import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:habitduel_server/cron/duel_expiry_cron.dart';
import 'package:habitduel_server/db/database.dart';
import 'package:habitduel_server/handlers/auth_handler.dart';
import 'package:habitduel_server/handlers/checkins_handler.dart';
import 'package:habitduel_server/handlers/duels_handler.dart';
import 'package:habitduel_server/handlers/leaderboard_handler.dart';
import 'package:habitduel_server/logging/app_logger.dart';
import 'package:habitduel_server/middleware/jwt_middleware.dart';
import 'package:habitduel_server/websocket/duel_ws_handler.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final port = int.parse(env['PORT'] ?? '8080');

  final conn = await Database.connection;
  AppLogger.info(
    'postgres_connected',
    fields: {
      'dbHost': env['DB_HOST'],
      'dbPort': env['DB_PORT'],
      'dbName': env['DB_NAME'],
    },
  );

  final authHandler = AuthHandler(env);
  final jwtSecret = env['JWT_SECRET'] ?? 'default_secret';
  final wsHub = DuelWsHub(jwtSecret);
  final duelsHandler = DuelsHandler();
  final checkinsHandler = CheckinsHandler(wsHub: wsHub);
  final leaderboardHandler = LeaderboardHandler();

  final protectedRouter = Router();
  protectedRouter.get('/users/me', (Request request) async {
    final userId = request.context['userId'] as String;
    final result = await conn.execute(
      Sql.named(
        'SELECT id, username, email, wins, losses FROM users WHERE id = @id::uuid',
      ),
      parameters: {'id': userId},
    );

    if (result.isEmpty) {
      return Response(
        404,
        body: '{"error":"user_not_found"}',
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = result.first.toColumnMap();
    final badgesResult = await conn.execute(
      Sql.named('SELECT badge_type, earned_at FROM badges WHERE user_id = @id::uuid'),
      parameters: {'id': userId},
    );
    final badges = badgesResult
        .map((r) => r.toColumnMap())
        .map((b) => {
              'badge_type': b['badge_type'],
              'earned_at': b['earned_at'].toString(),
            })
        .toList();

    return Response.ok(
      '{"id":"${row['id']}","username":"${row['username']}",'
      '"email":"${row['email']}","wins":${row['wins']},'
      '"losses":${row['losses']},"badges":${badges.toString().replaceAll("'", '"')}}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  protectedRouter.mount('/duels/', duelsHandler.router.call);
  protectedRouter.mount('/duels/', checkinsHandler.router.call);
  protectedRouter.mount('/leaderboard/', leaderboardHandler.router.call);

  final app = Router();
  app.get(
    '/healthz',
    (_) => Response.ok(
      '{"status":"ok"}',
      headers: {'Content-Type': 'application/json'},
    ),
  );
  app.mount('/auth/', authHandler.router.call);

  final protectedPipeline =
      const Pipeline().addMiddleware(jwtMiddleware(env)).addHandler(protectedRouter.call);
  app.mount('/', protectedPipeline);

  final handler = const Pipeline()
      .addMiddleware(AppLogger.requestLogging())
      .addMiddleware(_corsMiddleware())
      .addHandler(app.call);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  AppLogger.info(
    'server_started',
    fields: {'port': server.port, 'bind': '0.0.0.0'},
  );

  final expiryCron = DuelExpiryCron(wsHub: wsHub);
  expiryCron.start();
  AppLogger.info('duel_expiry_cron_started');

  server.listen((HttpRequest request) {
    final path = request.uri.path;
    if (path.startsWith('/ws/')) {
      AppLogger.info('websocket_upgrade', fields: {'path': path});
      wsHub.handleUpgrade(request);
    } else {
      shelf_io.handleRequest(request, handler);
    }
  });
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:habitduel_server/handlers/auth_handler.dart';
import 'package:habitduel_server/handlers/checkins_handler.dart';
import 'package:habitduel_server/handlers/duels_handler.dart';
import 'package:habitduel_server/handlers/leaderboard_handler.dart';
import 'package:habitduel_server/middleware/jwt_middleware.dart';
import 'package:habitduel_server/db/database.dart';
import 'package:habitduel_server/websocket/duel_ws_handler.dart';
import 'package:habitduel_server/cron/duel_expiry_cron.dart';

Future<void> main() async {
  // Load environment
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final port = int.parse(env['PORT'] ?? '8080');

  // Verify DB connectivity early
  final conn = await Database.connection;
  print('✅ Connected to PostgreSQL '
      '(${env["DB_HOST"]}:${env["DB_PORT"]}/${env["DB_NAME"]})');

  // --- Auth routes (public, no JWT required) ---
  final authHandler = AuthHandler(env);

  // --- WebSocket hub ---
  final jwtSecret = env['JWT_SECRET'] ?? 'default_secret';
  final wsHub = DuelWsHub(jwtSecret);

  // --- Duel + Checkin handlers ---
  final duelsHandler = DuelsHandler();
  final checkinsHandler = CheckinsHandler(wsHub: wsHub);
  final leaderboardHandler = LeaderboardHandler();

  // --- Protected routes (JWT required) ---
  final protectedRouter = Router();
  // GET /users/me — quick smoke-test for JWT middleware
  protectedRouter.get('/users/me', (Request request) async {
    final userId = request.context['userId'] as String;
    final result = await conn.execute(
      Sql.named(
        'SELECT id, username, email, wins, losses FROM users WHERE id = @id::uuid',
      ),
      parameters: {'id': userId},
    );

    if (result.isEmpty) {
      return Response(404,
          body: '{"error":"user_not_found"}',
          headers: {'Content-Type': 'application/json'});
    }

    final row = result.first.toColumnMap();
    // Fetch badges
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

  // Mount duels and checkins onto the protected router
  protectedRouter.mount('/duels/', duelsHandler.router.call);
  protectedRouter.mount('/duels/', checkinsHandler.router.call);
  protectedRouter.mount('/leaderboard/', leaderboardHandler.router.call);

  // --- Build the top-level router ---
  final app = Router();

  // Mount auth under /auth (public)
  app.mount('/auth/', authHandler.router.call);

  // Mount protected routes behind JWT middleware
  final protectedPipeline =
      const Pipeline().addMiddleware(jwtMiddleware(env)).addHandler(protectedRouter.call);
  app.mount('/', protectedPipeline);

  // --- Global middleware: logging + CORS ---
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(app.call);

  // --- Start server ---
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 HabitDuel server running on http://localhost:${server.port}');

  // --- Start duel expiry cron ---
  final expiryCron = DuelExpiryCron(wsHub: wsHub);
  expiryCron.start();

  // Route incoming requests: WebSocket upgrades go to wsHub,
  // everything else goes through Shelf pipeline.
  server.listen((HttpRequest request) {
    final path = request.uri.path;
    if (path.startsWith('/ws/')) {
      // WebSocket upgrade
      wsHub.handleUpgrade(request);
    } else {
      // Shelf handler
      shelf_io.handleRequest(request, handler);
    }
  });
}

/// Simple CORS middleware that allows all origins (fine for MVP / dev).
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Handle preflight
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


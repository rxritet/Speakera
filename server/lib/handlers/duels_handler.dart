import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';

/// Handles duel CRUD: create, accept, list, detail.
class DuelsHandler {
  Router get router {
    final r = Router();
    r.post('/', _createDuel);
    r.get('/', _listDuels);
    r.get('/<id>', _getDuel);
    r.post('/<id>/accept', _acceptDuel);
    return r;
  }

  // ---------------------------------------------------------------------------
  // POST /duels — create a new duel
  // ---------------------------------------------------------------------------
  Future<Response> _createDuel(Request request) async {
    final userId = request.context['userId'] as String;
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final habitName = (body['habit_name'] as String?)?.trim();
    final description = (body['description'] as String?)?.trim();
    final durationDays = body['duration_days'] as int?;
    final opponentUsername = (body['opponent_username'] as String?)?.trim();

    if (habitName == null || habitName.isEmpty) {
      return _json({'error': 'habit_name_required'}, 400);
    }
    if (durationDays == null || ![7, 14, 21, 30].contains(durationDays)) {
      return _json({'error': 'invalid_duration'}, 400);
    }

    final conn = await Database.connection;

    // Resolve opponent if provided
    String? opponentId;
    if (opponentUsername != null && opponentUsername.isNotEmpty) {
      final oppResult = await conn.execute(
        Sql.named('SELECT id FROM users WHERE username = @u'),
        parameters: {'u': opponentUsername},
      );
      if (oppResult.isEmpty) {
        return _json({'error': 'opponent_not_found'}, 404);
      }
      opponentId = oppResult.first.toColumnMap()['id'] as String;
    }

    // Insert duel
    final duelResult = await conn.execute(
      Sql.named('''
        INSERT INTO duels (habit_name, description, creator_id, opponent_id, duration_days)
        VALUES (@habit, @desc, @creator::uuid, ${opponentId != null ? '@opponent::uuid' : 'NULL'}, @days)
        RETURNING id, habit_name, description, creator_id, opponent_id, status, duration_days, created_at
      '''),
      parameters: {
        'habit': habitName,
        'desc': description,
        'creator': userId,
        if (opponentId != null) 'opponent': opponentId,
        'days': durationDays,
      },
    );

    final duel = duelResult.first.toColumnMap();
    final duelId = duel['id'] as String;

    // Add creator as participant
    await conn.execute(
      Sql.named(
        'INSERT INTO duel_participants (duel_id, user_id) VALUES (@d::uuid, @u::uuid)',
      ),
      parameters: {'d': duelId, 'u': userId},
    );

    // Fetch creator info
    final creatorRow = await _fetchUser(conn, userId);

    // Fetch opponent info if exists
    Map<String, dynamic>? opponentInfo;
    if (opponentId != null) {
      opponentInfo = await _fetchUser(conn, opponentId);
    }

    return _json({
      'id': duelId,
      'habit_name': duel['habit_name'],
      'description': duel['description'],
      'status': duel['status'],
      'creator': creatorRow,
      'opponent': opponentInfo,
      'duration_days': duel['duration_days'],
      'created_at': (duel['created_at'] as DateTime).toUtc().toIso8601String(),
    }, 201);
  }

  // ---------------------------------------------------------------------------
  // POST /duels/<id>/accept
  // ---------------------------------------------------------------------------
  Future<Response> _acceptDuel(Request request, String id) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    // Fetch duel
    final duelResult = await conn.execute(
      Sql.named('SELECT * FROM duels WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    final status = duel['status'] as String;
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;

    if (status != 'pending') {
      return _json({'error': 'duel_not_pending'}, 409);
    }

    // Cannot accept own duel
    if (creatorId == userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    // If targeted duel, only the specified opponent can accept
    if (opponentId != null && opponentId != userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    final now = DateTime.now().toUtc();
    final durationDays = duel['duration_days'] as int;
    final endsAt = now.add(Duration(days: durationDays));

    // Activate duel
    await conn.execute(
      Sql.named('''
        UPDATE duels
        SET status = 'active',
            opponent_id = @opp::uuid,
            starts_at = @start,
            ends_at = @end
        WHERE id = @id::uuid
      '''),
      parameters: {
        'id': id,
        'opp': userId,
        'start': now,
        'end': endsAt,
      },
    );

    // Add opponent as participant
    await conn.execute(
      Sql.named('''
        INSERT INTO duel_participants (duel_id, user_id)
        VALUES (@d::uuid, @u::uuid)
        ON CONFLICT (duel_id, user_id) DO NOTHING
      '''),
      parameters: {'d': id, 'u': userId},
    );

    return _json({
      'id': id,
      'status': 'active',
      'starts_at': now.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
    }, 200);
  }

  // ---------------------------------------------------------------------------
  // GET /duels — list duels for current user
  // ---------------------------------------------------------------------------
  Future<Response> _listDuels(Request request) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    final result = await conn.execute(
      Sql.named('''
        SELECT d.id, d.habit_name, d.status, d.ends_at, d.duration_days,
               dp_me.streak AS my_streak,
               dp_opp.streak AS opponent_streak,
               CASE WHEN d.creator_id = @uid::uuid THEN d.opponent_id ELSE d.creator_id END AS opponent_id
        FROM duels d
        LEFT JOIN duel_participants dp_me
          ON dp_me.duel_id = d.id AND dp_me.user_id = @uid::uuid
        LEFT JOIN duel_participants dp_opp
          ON dp_opp.duel_id = d.id AND dp_opp.user_id != @uid::uuid
        WHERE d.creator_id = @uid::uuid OR d.opponent_id = @uid::uuid
        ORDER BY d.created_at DESC
      '''),
      parameters: {'uid': userId},
    );

    final duels = result.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'habit_name': row['habit_name'],
        'status': row['status'],
        'my_streak': row['my_streak'] ?? 0,
        'opponent_streak': row['opponent_streak'] ?? 0,
        'duration_days': row['duration_days'],
        'ends_at': row['ends_at'] != null
            ? (row['ends_at'] as DateTime).toUtc().toIso8601String()
            : null,
      };
    }).toList();

    return _json({'duels': duels}, 200);
  }

  // ---------------------------------------------------------------------------
  // GET /duels/<id> — duel detail
  // ---------------------------------------------------------------------------
  Future<Response> _getDuel(Request request, String id) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    final duelResult = await conn.execute(
      Sql.named('SELECT * FROM duels WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;

    // Only participants can view
    if (creatorId != userId && opponentId != userId) {
      // Allow open duels to be visible
      if (opponentId != null) {
        return _json({'error': 'forbidden'}, 403);
      }
    }

    // Fetch participants with streaks
    final partResult = await conn.execute(
      Sql.named('''
        SELECT dp.user_id, dp.streak, dp.last_checkin, u.username
        FROM duel_participants dp
        JOIN users u ON u.id = dp.user_id
        WHERE dp.duel_id = @id::uuid
      '''),
      parameters: {'id': id},
    );

    final participants = partResult.map((r) {
      final row = r.toColumnMap();
      return {
        'user_id': row['user_id'],
        'username': row['username'],
        'streak': row['streak'],
        'last_checkin': row['last_checkin']?.toString(),
      };
    }).toList();

    // Fetch recent checkins (last 10)
    final checkinsResult = await conn.execute(
      Sql.named('''
        SELECT c.id, c.user_id, u.username, c.checked_at, c.note
        FROM checkins c
        JOIN users u ON u.id = c.user_id
        WHERE c.duel_id = @id::uuid
        ORDER BY c.checked_at DESC
        LIMIT 10
      '''),
      parameters: {'id': id},
    );

    final checkins = checkinsResult.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'user_id': row['user_id'],
        'username': row['username'],
        'checked_at': (row['checked_at'] as DateTime).toUtc().toIso8601String(),
        'note': row['note'],
      };
    }).toList();

    return _json({
      'id': duel['id'],
      'habit_name': duel['habit_name'],
      'description': duel['description'],
      'status': duel['status'],
      'creator_id': creatorId,
      'opponent_id': opponentId,
      'duration_days': duel['duration_days'],
      'starts_at': duel['starts_at'] != null
          ? (duel['starts_at'] as DateTime).toUtc().toIso8601String()
          : null,
      'ends_at': duel['ends_at'] != null
          ? (duel['ends_at'] as DateTime).toUtc().toIso8601String()
          : null,
      'created_at': (duel['created_at'] as DateTime).toUtc().toIso8601String(),
      'participants': participants,
      'checkins': checkins,
    }, 200);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchUser(Connection conn, String userId) async {
    final r = await conn.execute(
      Sql.named('SELECT id, username FROM users WHERE id = @id::uuid'),
      parameters: {'id': userId},
    );
    final row = r.first.toColumnMap();
    return {'id': row['id'], 'username': row['username']};
  }

  Response _json(Map<String, dynamic> data, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

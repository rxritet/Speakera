import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';
import '../services/duel_completion_service.dart';
import '../websocket/duel_ws_handler.dart';

/// Handles POST /duels/:id/checkin.
class CheckinsHandler {
  CheckinsHandler({this.wsHub});

  final DuelWsHub? wsHub;

  Router get router {
    final r = Router();
    r.post('/<duelId>/checkin', _checkIn);
    return r;
  }

  // ---------------------------------------------------------------------------
  // POST /duels/<duelId>/checkin
  // ---------------------------------------------------------------------------
  Future<Response> _checkIn(Request request, String duelId) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    // 1. Verify duel exists and is active
    final duelResult = await conn.execute(
      Sql.named('SELECT status, creator_id, opponent_id FROM duels WHERE id = @id::uuid'),
      parameters: {'id': duelId},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    if (duel['status'] != 'active') {
      return _json({'error': 'duel_not_active'}, 403);
    }

    // 2. Verify user is a participant
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;
    if (creatorId != userId && opponentId != userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    // 3. Server UTC date — the single source of truth
    final now = DateTime.now().toUtc();
    final todayDate = DateTime.utc(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // 4. Check if already checked in today
    final existingCheckin = await conn.execute(
      Sql.named('''
        SELECT id FROM checkins
        WHERE duel_id = @duel::uuid
          AND user_id = @user::uuid
          AND (checked_at::date) = @today
      '''),
      parameters: {
        'duel': duelId,
        'user': userId,
        'today': todayDate,
      },
    );

    if (existingCheckin.isNotEmpty) {
      return _json({'error': 'already_checked_in'}, 409);
    }

    // 5. Get current participant record
    final partResult = await conn.execute(
      Sql.named('''
        SELECT streak, last_checkin FROM duel_participants
        WHERE duel_id = @duel::uuid AND user_id = @user::uuid
      '''),
      parameters: {'duel': duelId, 'user': userId},
    );

    if (partResult.isEmpty) {
      return _json({'error': 'forbidden'}, 403);
    }

    final part = partResult.first.toColumnMap();
    var currentStreak = part['streak'] as int;
    final lastCheckin = part['last_checkin'] as DateTime?;

    // 6. Streak logic: reset if missed a day
    if (lastCheckin != null) {
      final lastDate = DateTime.utc(lastCheckin.year, lastCheckin.month, lastCheckin.day);
      if (lastDate.isBefore(yesterdayDate)) {
        // Missed at least one day → reset streak
        // Broadcast streak_broken before resetting
        if (currentStreak > 0) {
          final usernameResult = await conn.execute(
            Sql.named('SELECT username FROM users WHERE id = @id::uuid'),
            parameters: {'id': userId},
          );
          final uname = usernameResult.first.toColumnMap()['username'] as String;
          wsHub?.notifyStreakBroken(
            duelId: duelId,
            userId: userId,
            username: uname,
            oldStreak: currentStreak,
          );
        }
        currentStreak = 0;
      }
    }

    // 7. Increment streak
    final newStreak = currentStreak + 1;

    // 8. Parse optional note
    String? note;
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      note = body['note'] as String?;
    } catch (_) {
      // no body or invalid JSON — note stays null
    }

    // 9. Insert checkin record
    final checkinResult = await conn.execute(
      Sql.named('''
        INSERT INTO checkins (duel_id, user_id, checked_at, note)
        VALUES (@duel::uuid, @user::uuid, @now, @note)
        RETURNING id
      '''),
      parameters: {
        'duel': duelId,
        'user': userId,
        'now': now,
        'note': note,
      },
    );
    final checkinId = checkinResult.first.toColumnMap()['id'] as String;

    // 10. Update participant streak and last_checkin
    await conn.execute(
      Sql.named('''
        UPDATE duel_participants
        SET streak = @streak, last_checkin = @today
        WHERE duel_id = @duel::uuid AND user_id = @user::uuid
      '''),
      parameters: {
        'streak': newStreak,
        'today': todayDate,
        'duel': duelId,
        'user': userId,
      },
    );

    // 11. Broadcast checkin_created via WebSocket
    final usernameRes = await conn.execute(
      Sql.named('SELECT username FROM users WHERE id = @id::uuid'),
      parameters: {'id': userId},
    );
    final username = usernameRes.first.toColumnMap()['username'] as String;
    wsHub?.notifyCheckinCreated(
      duelId: duelId,
      userId: userId,
      username: username,
      newStreak: newStreak,
      checkinId: checkinId,
      checkedAt: now,
    );

    // 12. Check for duel completion (has end date passed?)
    final duelFull = await conn.execute(
      Sql.named('SELECT ends_at, creator_id, opponent_id FROM duels WHERE id = @id::uuid'),
      parameters: {'id': duelId},
    );
    if (duelFull.isNotEmpty) {
      final duelRow = duelFull.first.toColumnMap();
      final endsAt = duelRow['ends_at'] as DateTime?;
      if (endsAt != null && now.isAfter(endsAt)) {
        await completeDuel(conn, duelId, wsHub: wsHub);
      }
    }

    return _json({
      'checkin_id': checkinId,
      'duel_id': duelId,
      'new_streak': newStreak,
      'checked_at': now.toIso8601String(),
    }, 201);
  }

  // ---------------------------------------------------------------------------
  Response _json(Map<String, dynamic> data, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

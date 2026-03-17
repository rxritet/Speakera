import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';
import '../services/badge_service.dart';
import '../services/duel_completion_service.dart';
import '../websocket/duel_ws_handler.dart';

/// Обрабатывает POST /duels/:id/checkin.
class CheckinsHandler {
  CheckinsHandler({this.wsHub});

  final DuelWsHub? wsHub;

  Router get router {
    final r = Router();
    r.post('/<duelId>/checkin', _checkIn);
    return r;
  }

  // ---------------------------------------------------------------------------
  // POST /duels/<duelId>/checkin — отметить выполнение
  // ---------------------------------------------------------------------------
  Future<Response> _checkIn(Request request, String duelId) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    // 1. Проверяем, что дуэль есть и активна
    final duelResult = await conn.execute(
      Sql.named('SELECT status, creator_id, opponent_id FROM duels WHERE id = @id::uuid'),
      parameters: {'id': duelId},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    if (duel['status'] != 'active') {
      return _json({'error': 'duel_not_active'}, 403);
    }

    // 2. Проверяем, что пользователь — участник
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;
    if (creatorId != userId && opponentId != userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    // 3. Текущая UTC-дата — единый источник истины
    final now = DateTime.now().toUtc();
    final todayDate = DateTime.utc(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // 4. Проверяем, не отмечено ли сегодня
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

    // 5. Получаем текущую запись участника
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

    // 6. Логика серии: сброс при пропущенном дне
    if (lastCheckin != null) {
      final lastDate = DateTime.utc(lastCheckin.year, lastCheckin.month, lastCheckin.day);
      if (lastDate.isBefore(yesterdayDate)) {
        // Пропущен минимум один день — сбрасываем серию
          // Сначала отправляем streak_broken
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

    // 7. Увеличиваем серию
    final newStreak = currentStreak + 1;

    // 8. Извлекаем опциональную заметку
    String? note;
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      note = body['note'] as String?;
    } catch (_) {
      // нет тела запроса или невалидный JSON
    }

    // 9. Сохраняем запись об отметке
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

    // 10. Обновляем серию и дату последней отметки
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

    // --- Badge Awards ---
    // 1. Check for first check-in badge
    await BadgeService.checkAndAwardFirstCheckin(conn, userId);
    // 2. Check for streak-based badges
    await BadgeService.checkAndAwardStreakBadges(conn, userId, newStreak);

    // 11. Отправляем checkin_created через WebSocket
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

    // 12. Проверяем завершение дуэли (ends_at наступило?)
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

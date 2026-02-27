import 'package:postgres/postgres.dart';

import '../websocket/duel_ws_handler.dart';

/// Completes a duel by comparing participant streaks, updating stats.
/// Extracted so it can be called from both checkins_handler and the cron job.
Future<void> completeDuel(
  Connection conn,
  String duelId, {
  DuelWsHub? wsHub,
}) async {
  // Get both participants' streaks
  final parts = await conn.execute(
    Sql.named('''
      SELECT dp.user_id, dp.streak, u.username
      FROM duel_participants dp
      JOIN users u ON u.id = dp.user_id
      WHERE dp.duel_id = @id::uuid
      ORDER BY dp.streak DESC
    '''),
    parameters: {'id': duelId},
  );

  if (parts.length < 2) return;

  final p1 = parts[0].toColumnMap();
  final p2 = parts[1].toColumnMap();
  final s1 = p1['streak'] as int;
  final s2 = p2['streak'] as int;

  String? winnerId;
  String? winnerUsername;
  String? loserId;

  if (s1 > s2) {
    winnerId = p1['user_id'] as String;
    winnerUsername = p1['username'] as String;
    loserId = p2['user_id'] as String;
  } else if (s2 > s1) {
    winnerId = p2['user_id'] as String;
    winnerUsername = p2['username'] as String;
    loserId = p1['user_id'] as String;
  }
  // If equal, it's a draw — no winner/loser

  await conn.execute(
    Sql.named("UPDATE duels SET status = 'completed' WHERE id = @id::uuid"),
    parameters: {'id': duelId},
  );

  // Update stats
  if (winnerId != null && loserId != null) {
    await conn.execute(
      Sql.named('UPDATE users SET wins = wins + 1 WHERE id = @id::uuid'),
      parameters: {'id': winnerId},
    );
    await conn.execute(
      Sql.named('UPDATE users SET losses = losses + 1 WHERE id = @id::uuid'),
      parameters: {'id': loserId},
    );
  }

  wsHub?.notifyDuelCompleted(
    duelId: duelId,
    winnerId: winnerId,
    winnerUsername: winnerUsername,
  );
}

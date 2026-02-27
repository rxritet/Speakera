import 'dart:async';

import '../db/database.dart';
import '../services/duel_completion_service.dart';
import '../websocket/duel_ws_handler.dart';
import 'package:postgres/postgres.dart';

/// Periodically checks for expired duels and completes them.
/// Runs every 5 minutes.
class DuelExpiryCron {
  DuelExpiryCron({required this.wsHub});

  final DuelWsHub wsHub;
  Timer? _timer;

  void start() {
    // Run immediately on start, then every 5 minutes.
    _tick();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _tick());
    print('⏰ Duel expiry cron started (every 5 min)');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      final conn = await Database.connection;

      // Find active duels whose ends_at has passed.
      final expired = await conn.execute(
        Sql.named('''
          SELECT id FROM duels
          WHERE status = 'active'
            AND ends_at IS NOT NULL
            AND ends_at < NOW()
        '''),
      );

      if (expired.isEmpty) return;

      print('⏰ Found ${expired.length} expired duel(s), completing…');

      for (final row in expired) {
        final duelId = row.toColumnMap()['id'] as String;
        try {
          await completeDuel(conn, duelId, wsHub: wsHub);
          print('  ✅ Completed duel $duelId');
        } catch (e) {
          print('  ❌ Error completing duel $duelId: $e');
        }
      }
    } catch (e) {
      print('⏰ Cron tick error: $e');
    }
  }
}

import 'package:postgres/postgres.dart';

/// Сервис для автоматического начисления бейджей пользователям.
class BadgeService {
  /// Проверяет и начисляет бейдж, если у пользователя его еще нет.
  static Future<void> awardBadgeIfMissing(
    Connection conn,
    String userId,
    String badgeType,
  ) async {
    final existing = await conn.execute(
      Sql.named(
        'SELECT id FROM badges WHERE user_id = @userId::uuid AND badge_type = @type',
      ),
      parameters: {
        'userId': userId,
        'type': badgeType,
      },
    );

    if (existing.isEmpty) {
      await conn.execute(
        Sql.named(
          'INSERT INTO badges (user_id, badge_type) VALUES (@userId::uuid, @type)',
        ),
        parameters: {
          'userId': userId,
          'type': badgeType,
        },
      );
      print('🏅 Badge awarded: $badgeType to user $userId');
    }
  }

  /// Начисляет бейдж за первый чекин.
  static Future<void> checkAndAwardFirstCheckin(
    Connection conn,
    String userId,
  ) async {
    await awardBadgeIfMissing(conn, userId, 'first_checkin');
  }

  /// Проверяет количество побед и начисляет соответствующие бейджи.
  static Future<void> checkAndAwardWinBadges(
    Connection conn,
    String userId,
  ) async {
    final result = await conn.execute(
      Sql.named('SELECT wins FROM users WHERE id = @id::uuid'),
      parameters: {'id': userId},
    );

    if (result.isEmpty) return;

    final wins = result.first.toColumnMap()['wins'] as int;

    if (wins >= 1) await awardBadgeIfMissing(conn, userId, 'winner_1');
    if (wins >= 10) await awardBadgeIfMissing(conn, userId, 'winner_10');
    if (wins >= 50) await awardBadgeIfMissing(conn, userId, 'winner_50');
  }

  /// Начисляет бейджи за серии (стрики).
  static Future<void> checkAndAwardStreakBadges(
    Connection conn,
    String userId,
    int streak,
  ) async {
    if (streak >= 7) await awardBadgeIfMissing(conn, userId, 'streak_7');
    if (streak >= 14) await awardBadgeIfMissing(conn, userId, 'streak_14');
    if (streak >= 21) await awardBadgeIfMissing(conn, userId, 'streak_21');
    if (streak >= 30) await awardBadgeIfMissing(conn, userId, 'streak_30');
  }
}

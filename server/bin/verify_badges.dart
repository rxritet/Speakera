import 'package:postgres/postgres.dart';
import 'package:habitduel_server/db/database.dart';
import 'package:habitduel_server/services/badge_service.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  DotEnv(includePlatformEnvironment: true).load(['.env']);
  
  print('🧪 Starting Badge System Verification...');
  
  final conn = await Database.connection;
  
  // 1. Get a test user
  final users = await conn.execute('SELECT id, username FROM users LIMIT 1');
  if (users.isEmpty) {
    print('❌ No users found in DB. Please register at least one user.');
    return;
  }
  
  final userId = users.first[0] as String;
  final username = users.first[1] as String;
  print('👤 Testing with user: $username ($userId)');
  
  // 2. Clear existing badges for a clean test
  await conn.execute(Sql.named('DELETE FROM badges WHERE user_id = @id::uuid'), parameters: {'id': userId});
  print('🧹 Cleared existing badges.');
  
  // 3. Test First Check-in
  print('🏃 Testing: First Check-in Badge...');
  await BadgeService.checkAndAwardFirstCheckin(conn, userId);
  
  // Verify
  var badges = await conn.execute(Sql.named('SELECT badge_type FROM badges WHERE user_id = @id::uuid'), parameters: {'id': userId});
  if (badges.any((b) => b[0] == 'first_checkin')) {
    print('✅ Success: first_checkin badge awarded.');
  } else {
    print('❌ Failure: first_checkin badge NOT awarded.');
  }
  
  // 4. Test Streak Badge (7 days)
  print('🔥 Testing: Streak 7 Badge...');
  await BadgeService.checkAndAwardStreakBadges(conn, userId, 7);
  badges = await conn.execute(Sql.named('SELECT badge_type FROM badges WHERE user_id = @id::uuid'), parameters: {'id': userId});
  if (badges.any((b) => b[0] == 'streak_7')) {
    print('✅ Success: streak_7 badge awarded.');
  } else {
    print('❌ Failure: streak_7 badge NOT awarded.');
  }
  
  // 5. Test Win Badge (1 win)
  print('🏆 Testing: Win 1 Badge...');
  // Manually ensure wins >= 1
  await conn.execute(Sql.named('UPDATE users SET wins = GREATEST(wins, 1) WHERE id = @id::uuid'), parameters: {'id': userId});
  await BadgeService.checkAndAwardWinBadges(conn, userId);
  badges = await conn.execute(Sql.named('SELECT badge_type FROM badges WHERE user_id = @id::uuid'), parameters: {'id': userId});
  if (badges.any((b) => b[0] == 'winner_1')) {
    print('✅ Success: winner_1 badge awarded.');
  } else {
    print('❌ Failure: winner_1 badge NOT awarded.');
  }

  print('🏁 Verification complete.');
}

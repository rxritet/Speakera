import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Idempotent migration runner for HabitDuel.
///
/// Reads SQL files from `server/migrations/` in alphabetical order.
/// Checks `schema_migrations` table before each file — already applied
/// migrations are skipped.
Future<void> main() async {
  // Load .env from the server/ directory
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);

  final dbHost = env['DB_HOST'] ?? 'localhost';
  final dbPort = int.parse(env['DB_PORT'] ?? '5432');
  final dbName = env['DB_NAME'] ?? 'habitduel';
  final dbUser = env['DB_USER'] ?? 'postgres';
  final dbPassword = env['DB_PASSWORD'] ?? '';

  print('🔌 Connecting to PostgreSQL at $dbHost:$dbPort/$dbName ...');

  final connection = await Connection.open(
    Endpoint(
      host: dbHost,
      port: dbPort,
      database: dbName,
      username: dbUser,
      password: dbPassword,
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // Ensure schema_migrations table exists before anything else.
    // This solves the chicken-and-egg problem: migration 007 formally
    // records itself, but we need the table to track all migrations.
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
          version    VARCHAR(50) PRIMARY KEY,
          applied_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // Discover migration files sorted alphabetically
    final migrationsDir = Directory('../migrations');
    if (!migrationsDir.existsSync()) {
      print('❌ migrations/ directory not found at ${migrationsDir.absolute.path}');
      exit(1);
    }

    final sqlFiles = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (sqlFiles.isEmpty) {
      print('⚠️  No .sql files found in migrations/');
      exit(0);
    }

    print('📂 Found ${sqlFiles.length} migration file(s).\n');

    var applied = 0;
    var skipped = 0;

    for (final file in sqlFiles) {
      final version = file.uri.pathSegments.last; // e.g. "001_create_users.sql"

      // Check if already applied
      final result = await connection.execute(
        Sql.named('SELECT version FROM schema_migrations WHERE version = @version'),
        parameters: {'version': version},
      );

      if (result.isNotEmpty) {
        print('  ⏭  $version — already applied, skipping.');
        skipped++;
        continue;
      }

      // Read and execute the migration (split by ';' to support multi-statement files)
      final sql = await file.readAsString();
      print('  ▶  $version — applying...');

      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final statement in statements) {
        await connection.execute(statement);
      }

      // Record the migration
      await connection.execute(
        Sql.named(
          'INSERT INTO schema_migrations (version) VALUES (@version)',
        ),
        parameters: {'version': version},
      );

      print('  ✅ $version — done.');
      applied++;
    }

    print('\n🏁 Migrations complete: $applied applied, $skipped skipped.');
  } catch (e, st) {
    print('❌ Migration failed: $e');
    print(st);
    exit(1);
  } finally {
    await connection.close();
  }
}

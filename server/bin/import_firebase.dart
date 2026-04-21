import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:googleapis_auth/auth_io.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);

  final exportDir = Directory(env['EXPORT_DIR'] ?? '../exports/firebase');
  final projectId = env['FIREBASE_PROJECT_ID'] ?? _readProjectIdFromFirebaseJson('../firebase.json');
  final serviceAccountPath = env['FIREBASE_SERVICE_ACCOUNT_PATH'] ??
      env['GOOGLE_APPLICATION_CREDENTIALS'] ??
      '../service-account.json';
  final dryRun = (env['IMPORT_DRY_RUN'] ?? 'false').toLowerCase() == 'true';

  if (projectId == null || projectId.isEmpty) {
    stderr.writeln('FIREBASE_PROJECT_ID is required (or set in ../firebase.json).');
    exitCode = 1;
    return;
  }

  final serviceAccountFile = File(serviceAccountPath);
  if (!serviceAccountFile.existsSync()) {
    stderr.writeln('Service account file not found: ${serviceAccountFile.path}');
    stderr.writeln(
      'Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS in server/.env.',
    );
    exitCode = 1;
    return;
  }

  if (!exportDir.existsSync()) {
    stderr.writeln('Export directory not found: ${exportDir.path}');
    stderr.writeln('Run: dart run bin/export_postgres_for_firebase.dart');
    exitCode = 1;
    return;
  }

  final manifestFile = File('${exportDir.path}/manifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest.json not found in ${exportDir.path}.');
    stderr.writeln('Run: dart run bin/export_postgres_for_firebase.dart');
    exitCode = 1;
    return;
  }

  final users = await _readRows('${exportDir.path}/users.json');
  final duels = await _readRows('${exportDir.path}/duels.json');
  final participants = await _readRows('${exportDir.path}/duel_participants.json');
  final checkins = await _readRows('${exportDir.path}/checkins.json');
  final badges = await _readRows('${exportDir.path}/badges.json');

  print('Import target project: $projectId');
  print('Export dir: ${exportDir.absolute.path}');
  print('Dry run: $dryRun');
  print('Rows: users=${users.length}, duels=${duels.length}, participants=${participants.length}, checkins=${checkins.length}, badges=${badges.length}');

  if (dryRun) {
    print('Dry run enabled. No writes were sent to Firestore.');
    return;
  }

  final serviceAccountJson = jsonDecode(await serviceAccountFile.readAsString()) as Map<String, dynamic>;
  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

  final client = await clientViaServiceAccount(
    credentials,
    [fs.FirestoreApi.datastoreScope],
  );

  try {
    final firestore = fs.FirestoreApi(client);
    final databasePath = 'projects/$projectId/databases/(default)';

    var totalWrites = 0;

    totalWrites += await _commitBatched(
      firestore,
      databasePath,
      _buildUserWrites(projectId, users),
      label: 'users',
    );

    totalWrites += await _commitBatched(
      firestore,
      databasePath,
      _buildDuelWrites(projectId, duels),
      label: 'duels',
    );

    totalWrites += await _commitBatched(
      firestore,
      databasePath,
      _buildParticipantWrites(projectId, participants),
      label: 'participants',
    );

    totalWrites += await _commitBatched(
      firestore,
      databasePath,
      _buildCheckinWrites(projectId, checkins),
      label: 'checkins',
    );

    totalWrites += await _commitBatched(
      firestore,
      databasePath,
      _buildBadgeWrites(projectId, badges),
      label: 'badges',
    );

    print('Import completed. Total writes committed: $totalWrites');
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _readRows(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return const [];
  }

  final raw = jsonDecode(await file.readAsString());
  if (raw is! List) {
    throw StateError('Expected a JSON array in $path');
  }

  return raw
      .whereType<Map>()
      .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

List<fs.Write> _buildUserWrites(String projectId, List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = _asString(row['id']);
        if (id.isEmpty) return null;

        return _upsertWrite(
          projectId,
          'users/$id',
          {
            'id': id,
            'username': _asString(row['username']),
            'email': _nullableString(row['email']),
            'wins': _asInt(row['wins']),
            'losses': _asInt(row['losses']),
            'createdAt': _nullableTimestamp(row['created_at']),
            'legacyPostgresId': id,
          },
        );
      })
      .whereType<fs.Write>()
      .toList(growable: false);
}

List<fs.Write> _buildDuelWrites(String projectId, List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = _asString(row['id']);
        if (id.isEmpty) return null;

        return _upsertWrite(
          projectId,
          'duels/$id',
          {
            'id': id,
            'habitName': _asString(row['habit_name']),
            'description': _nullableString(row['description']),
            'creatorId': _nullableString(row['creator_id']),
            'opponentId': _nullableString(row['opponent_id']),
            'status': _asString(row['status']),
            'durationDays': _asInt(row['duration_days']),
            'startsAt': _nullableTimestamp(row['starts_at']),
            'endsAt': _nullableTimestamp(row['ends_at']),
            'createdAt': _nullableTimestamp(row['created_at']),
            'legacyPostgresId': id,
          },
        );
      })
      .whereType<fs.Write>()
      .toList(growable: false);
}

List<fs.Write> _buildParticipantWrites(String projectId, List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final duelId = _asString(row['duel_id']);
        final userId = _asString(row['user_id']);
        if (duelId.isEmpty || userId.isEmpty) return null;

        return _upsertWrite(
          projectId,
          'duels/$duelId/participants/$userId',
          {
            'userId': userId,
            'username': _asString(row['username']),
            'streak': _asInt(row['streak']),
            'lastCheckin': _nullableString(row['last_checkin']),
          },
        );
      })
      .whereType<fs.Write>()
      .toList(growable: false);
}

List<fs.Write> _buildCheckinWrites(String projectId, List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = _asString(row['id']);
        final duelId = _asString(row['duel_id']);
        if (id.isEmpty || duelId.isEmpty) return null;

        return _upsertWrite(
          projectId,
          'duels/$duelId/checkins/$id',
          {
            'id': id,
            'duelId': duelId,
            'userId': _asString(row['user_id']),
            'username': _asString(row['username']),
            'checkedAt': _nullableTimestamp(row['checked_at']),
            'note': _nullableString(row['note']),
            'legacyPostgresId': id,
          },
        );
      })
      .whereType<fs.Write>()
      .toList(growable: false);
}

List<fs.Write> _buildBadgeWrites(String projectId, List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = _asString(row['id']);
        final userId = _asString(row['user_id']);
        if (id.isEmpty || userId.isEmpty) return null;

        return _upsertWrite(
          projectId,
          'users/$userId/badges/$id',
          {
            'id': id,
            'badgeType': _asString(row['badge_type']),
            'earnedAt': _nullableTimestamp(row['earned_at']),
            'legacyPostgresId': id,
          },
        );
      })
      .whereType<fs.Write>()
      .toList(growable: false);
}

fs.Write _upsertWrite(
  String projectId,
  String docPath,
  Map<String, Object?> data,
) {
  final cleanData = Map<String, Object?>.fromEntries(
    data.entries.where((entry) => entry.value != null),
  );

  return fs.Write()
    ..update = (fs.Document()
      ..name = 'projects/$projectId/databases/(default)/documents/$docPath'
      ..fields = _toFirestoreFields(cleanData));
}

Future<int> _commitBatched(
  fs.FirestoreApi firestore,
  String databasePath,
  List<fs.Write> writes, {
  required String label,
}) async {
  const batchSize = 400;
  if (writes.isEmpty) {
    print('[$label] nothing to import');
    return 0;
  }

  var committed = 0;
  for (var i = 0; i < writes.length; i += batchSize) {
    final chunk = writes.sublist(i, (i + batchSize).clamp(0, writes.length));
    final request = fs.CommitRequest()..writes = chunk;
    await firestore.projects.databases.documents.commit(request, databasePath);
    committed += chunk.length;
    print('[$label] committed $committed/${writes.length}');
  }

  return committed;
}

Map<String, fs.Value> _toFirestoreFields(Map<String, Object?> data) {
  return data.map((key, value) => MapEntry(key, _toFirestoreValue(value)));
}

fs.Value _toFirestoreValue(Object? value) {
  final out = fs.Value();

  if (value == null) {
    out.nullValue = 'NULL_VALUE';
    return out;
  }

  if (value is bool) {
    out.booleanValue = value;
    return out;
  }

  if (value is int) {
    out.integerValue = value.toString();
    return out;
  }

  if (value is double) {
    out.doubleValue = value;
    return out;
  }

  if (value is DateTime) {
    out.timestampValue = value.toUtc().toIso8601String();
    return out;
  }

  if (value is List) {
    out.arrayValue = (fs.ArrayValue()
      ..values = value.map(_toFirestoreValue).toList(growable: false));
    return out;
  }

  if (value is Map) {
    final fields = value.map(
      (k, v) => MapEntry(k.toString(), _toFirestoreValue(v)),
    );
    out.mapValue = (fs.MapValue()..fields = fields);
    return out;
  }

  out.stringValue = value.toString();
  return out;
}

DateTime? _nullableTimestamp(Object? value) {
  final text = _nullableString(value);
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toUtc();
}

String _asString(Object? value) => value?.toString().trim() ?? '';

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readProjectIdFromFirebaseJson(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final flutter = json['flutter'] as Map<String, dynamic>?;
    final platforms = flutter?['platforms'] as Map<String, dynamic>?;
    final android = platforms?['android'] as Map<String, dynamic>?;
    final defaultNode = android?['default'] as Map<String, dynamic>?;
    return defaultNode?['projectId']?.toString();
  } catch (_) {
    return null;
  }
}

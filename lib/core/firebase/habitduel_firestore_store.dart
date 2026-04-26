import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/duel.dart';
import '../../domain/entities/gamification.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/social.dart';
import '../../domain/entities/shop.dart';
import '../../domain/entities/event.dart';

/// Основной слой доступа к Firestore для HabitDuel.
///
/// Работает на всех платформах включая Web.
class HabitDuelFirestoreStore {
  HabitDuelFirestoreStore([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore? _firestore;

  bool get _isEnabled => _firestore != null;
  FirebaseFirestore get _db => _firestore!;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _duels => _db.collection('duels');
  CollectionReference<Map<String, dynamic>> get _invites => _db.collection('invites');

  // ═══════════════════════════════════════════════════════════════════
  //  USERS / PROFILES
  // ═══════════════════════════════════════════════════════════════════

  Future<UserProfile?> readProfile(String userId) async {
    if (!_isEnabled) return null;
    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) return null;

    final badgesSnap = await _users.doc(userId).collection('badges').get();
    final badges = badgesSnap.docs.map((doc) {
      final data = doc.data();
      return ProfileBadge(
        badgeType: data['badgeType'] as String? ?? doc.id,
        earnedAt: _readDateTime(data['earnedAt']) ?? DateTime.now().toUtc(),
      );
    }).toList();

    final data = userDoc.data() ?? const <String, dynamic>{};
    return UserProfile(
      id: userId,
      username: data['username'] as String? ?? '',
      email: data['email'] as String?,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      badges: badges,
      bio: data['bio'] as String?,
      favoriteHabit: data['favoriteHabit'] as String?,
      avatarEmoji: data['avatarEmoji'] as String? ?? '🔥',
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    if (!_isEnabled) return;
    try {
      final batch = _db.batch();
      final userRef = _users.doc(profile.id);

      batch.set(
        userRef,
        {
          'id': profile.id,
          'username': profile.username,
          if (profile.email != null) 'email': profile.email,
          'wins': profile.wins,
          'losses': profile.losses,
          if (profile.bio != null) 'bio': profile.bio,
          if (profile.favoriteHabit != null)
            'favoriteHabit': profile.favoriteHabit,
          'avatarEmoji': profile.avatarEmoji,
          if (profile.avatarUrl != null) 'avatarUrl': profile.avatarUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final badge in profile.badges) {
        batch.set(
          userRef.collection('badges').doc(badge.badgeType),
          {
            'badgeType': badge.badgeType,
            'earnedAt': Timestamp.fromDate(badge.earnedAt.toUtc()),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Firestore profile mirror failed: $error');
    }
  }

  Future<void> mirrorUserFromAuth(User user) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(user.id).set(
        {
          'id': user.id,
          'username': user.username,
          if (user.email != null) 'email': user.email,
          'wins': user.wins,
          'losses': user.losses,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Firestore auth mirror failed: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LEADERBOARD
  // ═══════════════════════════════════════════════════════════════════

  Future<({List<LeaderboardEntry> entries, int total})> readLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_isEnabled) {
      return (entries: const <LeaderboardEntry>[], total: 0);
    }
    final snapshot = await _users.orderBy('wins', descending: true).get();
    final docs = snapshot.docs.toList();

    final total = docs.length;
    final sliced = docs.skip(offset).take(limit).toList(growable: false);
    final entries = <LeaderboardEntry>[];
    var rank = 0;
    int? previousWins;
    for (final doc in sliced) {
      final data = doc.data();
      final wins = (data['wins'] as num?)?.toInt() ?? 0;
      if (previousWins == null || wins != previousWins) {
        rank++;
        previousWins = wins;
      }
      entries.add(
        LeaderboardEntry(
          rank: rank,
          userId: doc.id,
          username: data['username'] as String? ?? '',
          wins: wins,
          losses: (data['losses'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return (entries: entries, total: total);
  }

  Stream<({List<LeaderboardEntry> entries, int total})> watchLeaderboard({
    int limit = 50,
    int offset = 0,
  }) {
    if (!_isEnabled) return Stream.value((entries: const <LeaderboardEntry>[], total: 0));
    
    return _users.orderBy('wins', descending: true).snapshots().map((snapshot) {
      final docs = snapshot.docs.toList();
      final total = docs.length;
      final sliced = docs.skip(offset).take(limit).toList(growable: false);
      final entries = <LeaderboardEntry>[];
      var rank = 0;
      int? previousWins;
      for (final doc in sliced) {
        final data = doc.data();
        final wins = (data['wins'] as num?)?.toInt() ?? 0;
        if (previousWins == null || wins != previousWins) {
          rank++;
          previousWins = wins;
        }
        entries.add(
          LeaderboardEntry(
            rank: rank,
            userId: doc.id,
            username: data['username'] as String? ?? '',
            wins: wins,
            losses: (data['losses'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      return (entries: entries, total: total);
    });
  }

  Future<void> mirrorLeaderboardUsers(Iterable<LeaderboardEntry> entries) async {
    if (!_isEnabled) return;
    try {
      final batch = _db.batch();
      for (final entry in entries) {
        batch.set(
          _users.doc(entry.userId),
          {
            'id': entry.userId,
            'username': entry.username,
            'wins': entry.wins,
            'losses': entry.losses,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (error) {
      debugPrint('Firestore leaderboard mirror failed: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DUELS  (1v1 + Group)
  // ═══════════════════════════════════════════════════════════════════

  Future<List<Duel>> readMyDuels(String userId) async {
    if (!_isEnabled) return const [];
    final snapshot = await _duels
        .where('participantIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .get();
    final duels = snapshot.docs.map(_duelFromSnapshot).toList();
    return duels;
  }

  Future<Duel?> readDuel(String duelId) async {
    if (!_isEnabled) return null;
    final duelDoc = await _duels.doc(duelId).get();
    if (!duelDoc.exists) return null;

    final participantSnap = await duelDoc.reference.collection('participants').get();
    final checkins = await _readCheckinsIfAllowed(duelDoc.reference);

    return _duelFromDocument(
      duelDoc,
      participants: participantSnap.docs,
      checkins: checkins,
    );
  }

  /// Stream для real-time обновлений дуэли (заменяет WebSocket).
  Stream<Duel?> watchDuel(String duelId) {
    if (!_isEnabled) return const Stream.empty();
    return _duels.doc(duelId).snapshots().asyncMap((snap) async {
      if (!snap.exists) return null;
      final participantSnap = await snap.reference.collection('participants').get();
      final checkins = await _readCheckinsIfAllowed(snap.reference);
      return _duelFromDocument(snap, participants: participantSnap.docs, checkins: checkins);
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _readCheckinsIfAllowed(
    DocumentReference<Map<String, dynamic>> duelRef,
  ) async {
    try {
      final snapshot = await duelRef
          .collection('checkins')
          .orderBy('checkedAt', descending: true)
          .get();
      return snapshot.docs;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return const [];
      }
      rethrow;
    }
  }

  /// Stream для real-time обновлений списка дуэлей пользователя.
  Stream<List<Duel>> watchMyDuels(String userId) {
    if (!_isEnabled) return const Stream.empty();
    return _duels
        .where('participantIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_duelFromSnapshot).toList());
  }

  /// Stream для открытых групповых дуэлей.
  Stream<List<Duel>> watchOpenGroupDuels() {
    if (!_isEnabled) return const Stream.empty();
    return _duels
        .where('type', isEqualTo: 'group')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snap) => snap.docs.map(_duelFromSnapshot).toList());
  }

  Future<void> upsertDuel(Duel duel) async {
    if (!_isEnabled) return;
    try {
      final duelRef = _duels.doc(duel.id);
      final batch = _db.batch();
      final participantIds = duel.participants
          .map((p) => p.userId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      batch.set(
        duelRef,
        {
          'id': duel.id,
          'habitName': duel.habitName,
          if (duel.description != null) 'description': duel.description,
          if (duel.creatorId != null) 'creatorId': duel.creatorId,
          if (duel.opponentId != null) 'opponentId': duel.opponentId,
          'status': duel.status,
          'type': duel.type.name,
          'durationDays': duel.durationDays,
          'maxParticipants': duel.maxParticipants,
          if (duel.inviteCode != null) 'inviteCode': duel.inviteCode,
          if (duel.habitCategory != null) 'habitCategory': duel.habitCategory,
          'isTrustedCheckin': duel.isTrustedCheckin,
          if (duel.healthMetric != null) 'healthMetric': duel.healthMetric,
          if (duel.healthTargetValue != null) 'healthTargetValue': duel.healthTargetValue,
          'entryFee': duel.entryFee,
          'currency': duel.currency.name,
          'myStreak': duel.myStreak,
          'opponentStreak': duel.opponentStreak,
          if (duel.startsAt != null) 'startsAt': Timestamp.fromDate(duel.startsAt!.toUtc()),
          if (duel.endsAt != null) 'endsAt': Timestamp.fromDate(duel.endsAt!.toUtc()),
          if (duel.createdAt != null) 'createdAt': Timestamp.fromDate(duel.createdAt!.toUtc()),
          'participantIds': participantIds,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final participant in duel.participants) {
        batch.set(
          duelRef.collection('participants').doc(participant.userId),
          {
            'userId': participant.userId,
            'username': participant.username,
            'streak': participant.streak,
            'lastCheckin': participant.lastCheckin,
            'xpGained': participant.xpGained,
            'isEliminated': participant.isEliminated,
            if (participant.rank != null) 'rank': participant.rank,
          },
          SetOptions(merge: true),
        );
      }

      for (final checkin in duel.checkins) {
        batch.set(
          duelRef.collection('checkins').doc(checkin.id),
          {
            'id': checkin.id,
            'userId': checkin.userId,
            'username': checkin.username,
            'checkedAt': Timestamp.fromDate(checkin.checkedAt.toUtc()),
            if (checkin.note != null) 'note': checkin.note,
            'isTrusted': checkin.isTrusted,
            if (checkin.healthValue != null) 'healthValue': checkin.healthValue,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Firestore duel upsert failed: $error');
    }
  }

  /// Создать дуэль напрямую в Firestore (без старого Dart сервера).
  Future<Duel> createDuelInFirestore({
    required String creatorId,
    required String creatorUsername,
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
    DuelType type = DuelType.duel,
    int maxParticipants = 2,
    String? habitCategory,
    bool isTrustedCheckin = false,
    String? healthMetric,
    double? healthTargetValue,
    int entryFee = 0,
    DuelCurrency currency = DuelCurrency.tenge,
  }) async {
    if (!_isEnabled) throw Exception('Firestore is not enabled');

    final duelRef = _duels.doc();
    final inviteCode = type == DuelType.group ? _generateInviteCode() : null;
    final now = DateTime.now().toUtc();

    String? actualOpponentId;
    if (type == DuelType.duel && opponentUsername != null && opponentUsername.isNotEmpty) {
      final querySnap = await _users.where('username', isEqualTo: opponentUsername).limit(1).get();
      if (querySnap.docs.isNotEmpty) {
        actualOpponentId = querySnap.docs.first.id;
      } else {
        throw Exception('User "$opponentUsername" not found. They must login first.');
      }
    }

    if (entryFee > 0) {
      await _ensureEnoughTenge(userId: creatorId, amount: entryFee);
      await _changeUserTenge(userId: creatorId, delta: -entryFee);
    }

    final duel = Duel(
      id: duelRef.id,
      habitName: habitName,
      description: description,
      status: type == DuelType.group ? 'open' : 'pending',
      durationDays: durationDays,
      type: type,
      creatorId: creatorId,
      opponentId: actualOpponentId,
      maxParticipants: maxParticipants,
      inviteCode: inviteCode,
      habitCategory: habitCategory,
      isTrustedCheckin: isTrustedCheckin,
      healthMetric: healthMetric,
      healthTargetValue: healthTargetValue,
      entryFee: entryFee,
      currency: currency,
      createdAt: now,
      participants: [
        DuelParticipant(userId: creatorId, username: creatorUsername),
        if (actualOpponentId != null)
          DuelParticipant(userId: actualOpponentId, username: opponentUsername!),
      ],
    );

    await upsertDuel(duel);

    // Создаём запись в /invites для группового лобби
    if (inviteCode != null) {
      await _invites.doc(inviteCode).set({
        'duelId': duelRef.id,
        'creatorId': creatorId,
        'habitName': habitName,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 7))),
      });
    }

    return duel;
  }

  /// Принять дуэль напрямую в Firestore.
  Future<void> acceptDuelInFirestore({
    required String duelId,
    required String userId,
    required String username,
  }) async {
    if (!_isEnabled) return;

    final duelRef = _duels.doc(duelId);
    final duelDoc = await duelRef.get();
    if (!duelDoc.exists) {
      throw Exception('Дуэль не найдена');
    }

    final duelData = duelDoc.data()!;
    final entryFee = (duelData['entryFee'] as num?)?.toInt() ?? 0;
    if (entryFee > 0) {
      await _ensureEnoughTenge(userId: userId, amount: entryFee);
    }

    final batch = _db.batch();
    final now = DateTime.now().toUtc();

    batch.update(duelRef, {
      'opponentId': userId,
      'status': 'active',
      'startsAt': Timestamp.fromDate(now),
      'participantIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      duelRef.collection('participants').doc(userId),
      {
        'userId': userId,
        'username': username,
        'streak': 0,
        'isEliminated': false,
      },
      SetOptions(merge: true),
    );

    if (entryFee > 0) {
      batch.set(
        _users.doc(userId).collection('currency').doc('current'),
        {'tenge': FieldValue.increment(-entryFee)},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Выполнить check-in напрямую в Firestore.
  Future<void> checkInInFirestore({
    required String duelId,
    required String userId,
    required String username,
    String? note,
    bool isTrusted = false,
    double? healthValue,
  }) async {
    if (!_isEnabled) return;

    final duelRef = _duels.doc(duelId);
    final checkinRef = duelRef.collection('checkins').doc();
    final now = DateTime.now().toUtc();
    final batch = _db.batch();

    batch.set(checkinRef, {
      'id': checkinRef.id,
      'userId': userId,
      'username': username,
      'checkedAt': Timestamp.fromDate(now),
      if (note != null) 'note': note,
      'isTrusted': isTrusted,
      if (healthValue != null) 'healthValue': healthValue,
    });

    // Обновляем streak участника
    final participantRef = duelRef.collection('participants').doc(userId);
    batch.update(participantRef, {
      'streak': FieldValue.increment(1),
      'lastCheckin': now.toIso8601String(),
    });

    batch.update(duelRef, {
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Присоединиться к групповому лобби по invite code.
  Future<Duel?> joinGroupDuelByInviteCode({
    required String inviteCode,
    required String userId,
    required String username,
  }) async {
    if (!_isEnabled) return null;

    final inviteDoc = await _invites.doc(inviteCode).get();
    if (!inviteDoc.exists) return null;

    final inviteData = inviteDoc.data()!;
    final duelId = inviteData['duelId'] as String;

    final duelDoc = await _duels.doc(duelId).get();
    if (!duelDoc.exists) return null;

    final duelData = duelDoc.data()!;
    final participantIds = (duelData['participantIds'] as List<dynamic>? ?? []).cast<String>();
    final maxParticipants = (duelData['maxParticipants'] as num?)?.toInt() ?? 10;

    if (participantIds.contains(userId)) {
      // Уже участник
      return readDuel(duelId);
    }

    if (participantIds.length >= maxParticipants) {
      throw Exception('Лобби заполнено');
    }

    final entryFee = (duelData['entryFee'] as num?)?.toInt() ?? 0;
    if (entryFee > 0) {
      await _ensureEnoughTenge(userId: userId, amount: entryFee);
    }

    final batch = _db.batch();
    batch.update(_duels.doc(duelId), {
      'participantIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _duels.doc(duelId).collection('participants').doc(userId),
      {
        'userId': userId,
        'username': username,
        'streak': 0,
        'isEliminated': false,
      },
      SetOptions(merge: true),
    );
    if (entryFee > 0) {
      batch.set(
        _users.doc(userId).collection('currency').doc('current'),
        {'tenge': FieldValue.increment(-entryFee)},
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    return readDuel(duelId);
  }

  /// Вступить в открытую дуэль (лобби) без инвайт-кода.
  Future<void> joinOpenDuel({
    required String duelId,
    required String userId,
    required String username,
  }) async {
    if (!_isEnabled) return;

    final duelRef = _duels.doc(duelId);
    final duelDoc = await duelRef.get();
    if (!duelDoc.exists) throw Exception('Дуэль не найдена');

    final duelData = duelDoc.data()!;
    final participantIds = (duelData['participantIds'] as List<dynamic>? ?? []).cast<String>();
    final maxParticipants = (duelData['maxParticipants'] as num?)?.toInt() ?? 10;
    final status = duelData['status'] as String? ?? '';

    if (status != 'open') {
      throw Exception('Эта дуэль уже в процессе или закрыта');
    }

    if (participantIds.contains(userId)) return;

    if (participantIds.length >= maxParticipants) {
      throw Exception('Лобби заполнено');
    }

    final entryFee = (duelData['entryFee'] as num?)?.toInt() ?? 0;
    if (entryFee > 0) {
      await _ensureEnoughTenge(userId: userId, amount: entryFee);
    }

    final batch = _db.batch();
    batch.update(duelRef, {
      'participantIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      duelRef.collection('participants').doc(userId),
      {
        'userId': userId,
        'username': username,
        'streak': 0,
        'isEliminated': false,
      },
      SetOptions(merge: true),
    );
    if (entryFee > 0) {
      batch.set(
        _users.doc(userId).collection('currency').doc('current'),
        {'tenge': FieldValue.increment(-entryFee)},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  GAMIFICATION — XP / LEVEL / STREAK FREEZE
  // ═══════════════════════════════════════════════════════════════════

  Future<UserXp?> readUserXp(String userId) async {
    if (!_isEnabled) return null;
    final doc = await _users.doc(userId).collection('xp').doc('current').get();
    if (!doc.exists) return UserXp(userId: userId);

    final data = doc.data()!;
    return UserXp(
      userId: userId,
      totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      freezesAvailable: (data['freezesAvailable'] as num?)?.toInt() ?? 0,
      weeklyXp: (data['weeklyXp'] as num?)?.toInt() ?? 0,
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Future<void> addXp({
    required String userId,
    required XpEventType eventType,
    String? duelId,
  }) async {
    if (!_isEnabled) return;
    try {
      final amount = _xpForEvent(eventType);
      final xpRef = _users.doc(userId).collection('xp').doc('current');

      await _db.runTransaction((tx) async {
        final snap = await tx.get(xpRef);
        final currentXp = (snap.data()?['totalXp'] as num?)?.toInt() ?? 0;
        final newXp = currentXp + amount;
        final newLevel = UserXp.levelFromXp(newXp);
        final freezesBonus = newLevel > UserXp.levelFromXp(currentXp) ? 1 : 0;

        tx.set(
          xpRef,
          {
            'totalXp': newXp,
            'level': newLevel,
            'freezesAvailable': FieldValue.increment(freezesBonus),
            'weeklyXp': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // Записываем событие XP для истории
      await _users.doc(userId).collection('xp').add({
        'eventType': eventType.name,
        'xpAmount': amount,
        if (duelId != null) 'duelId': duelId,
        'occurredAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Firestore addXp failed: $error');
    }
  }

  /// Использовать заморозку стрика.
  Future<bool> useStreakFreeze({
    required String userId,
    required String duelId,
  }) async {
    if (!_isEnabled) return false;

    final xpRef = _users.doc(userId).collection('xp').doc('current');
    bool success = false;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(xpRef);
      final freezes = (snap.data()?['freezesAvailable'] as num?)?.toInt() ?? 0;

      if (freezes <= 0) {
        success = false;
        return;
      }

      tx.update(xpRef, {'freezesAvailable': FieldValue.increment(-1)});

      // Сохраняем использование заморозки
      final freezeRef = _users.doc(userId).collection('xp').doc();
      tx.set(freezeRef, {
        'type': 'streak_freeze',
        'duelId': duelId,
        'usedAt': FieldValue.serverTimestamp(),
      });

      success = true;
    });

    return success;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SMART REMINDERS — паттерн чекинов
  // ═══════════════════════════════════════════════════════════════════

  Future<CheckinPattern?> readCheckinPattern(String userId) async {
    if (!_isEnabled) return null;
    final doc = await _users.doc(userId).collection('weekStats').doc('pattern').get();
    if (!doc.exists) return CheckinPattern(userId: userId);

    final data = doc.data()!;
    return CheckinPattern(
      userId: userId,
      preferredHour: (data['preferredHour'] as num?)?.toInt() ?? 9,
      preferredMinute: (data['preferredMinute'] as num?)?.toInt() ?? 0,
      averageCheckinHour: (data['averageCheckinHour'] as num?)?.toDouble() ?? 9.0,
      totalCheckins: (data['totalCheckins'] as num?)?.toInt() ?? 0,
      lastUpdated: _readDateTime(data['lastUpdated']),
    );
  }

  Future<void> updateCheckinPattern(String userId, DateTime checkinTime) async {
    if (!_isEnabled) return;
    try {
      final patternRef = _users.doc(userId).collection('weekStats').doc('pattern');

      await _db.runTransaction((tx) async {
        final snap = await tx.get(patternRef);
        final total = (snap.data()?['totalCheckins'] as num?)?.toInt() ?? 0;
        final avgHour = (snap.data()?['averageCheckinHour'] as num?)?.toDouble() ?? 9.0;
        
        final newTotal = total + 1;
        final checkinHour = checkinTime.hour + checkinTime.minute / 60.0;
        final newAvgHour = (avgHour * total + checkinHour) / newTotal;
        final preferredHour = newAvgHour.floor();
        final preferredMinute = ((newAvgHour - preferredHour) * 60).round();

        tx.set(
          patternRef,
          {
            'userId': userId,
            'preferredHour': preferredHour,
            'preferredMinute': preferredMinute,
            'averageCheckinHour': newAvgHour,
            'totalCheckins': newTotal,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (error) {
      debugPrint('Firestore updateCheckinPattern failed: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FCM TOKENS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('devices').doc(token).set(
        {
          'token': token,
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Firestore device token registration failed: $error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  AI COACH
  // ═══════════════════════════════════════════════════════════════════

  Future<AiCoachMessage?> readLatestCoachMessage(String userId) async {
    if (!_isEnabled) return null;
    final snap = await _users.doc(userId).collection('weekStats')
        .orderBy('weekStart', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    final message = data['coachMessage'] as String?;
    if (message == null) return null;

    return AiCoachMessage(
      userId: userId,
      weekStartDate: _readDateTime(data['weekStart']) ?? DateTime.now(),
      message: message,
      checkinsThisWeek: (data['checkinsThisWeek'] as num?)?.toInt() ?? 0,
      bestStreak: (data['bestStreak'] as num?)?.toInt() ?? 0,
      suggestion: data['suggestion'] as String?,
      generatedAt: _readDateTime(data['generatedAt']),
    );
  }

  Future<void> saveCoachMessage(AiCoachMessage msg) async {
    if (!_isEnabled) return;
    final weekKey = '${msg.weekStartDate.year}-W${_weekNumber(msg.weekStartDate)}';
    await _users.doc(msg.userId).collection('weekStats').doc(weekKey).set(
      {
        'weekStart': Timestamp.fromDate(msg.weekStartDate),
        'coachMessage': msg.message,
        'suggestion': msg.suggestion,
        'checkinsThisWeek': msg.checkinsThisWeek,
        'bestStreak': msg.bestStreak,
        'generatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Duel _duelFromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    return _duelFromData(snapshot.id, snapshot.data());
  }

  Duel _duelFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> participants = const [],
    List<QueryDocumentSnapshot<Map<String, dynamic>>> checkins = const [],
  }) {
    final duel = _duelFromData(doc.id, doc.data() ?? const <String, dynamic>{});

    final parsedParticipants = participants
        .map(
          (doc) => DuelParticipant(
            userId: doc.data()['userId'] as String? ?? doc.id,
            username: doc.data()['username'] as String? ?? doc.id,
            streak: (doc.data()['streak'] as num?)?.toInt() ?? 0,
            lastCheckin: doc.data()['lastCheckin'] as String?,
            xpGained: (doc.data()['xpGained'] as num?)?.toInt() ?? 0,
            isEliminated: doc.data()['isEliminated'] as bool? ?? false,
            rank: (doc.data()['rank'] as num?)?.toInt(),
          ),
        )
        .toList(growable: false);

    final parsedCheckins = checkins
        .map(
          (doc) => CheckInEntry(
            id: doc.data()['id'] as String? ?? doc.id,
            userId: doc.data()['userId'] as String? ?? '',
            username: doc.data()['username'] as String? ?? '',
            checkedAt: _readDateTime(doc.data()['checkedAt']) ?? DateTime.now().toUtc(),
            note: doc.data()['note'] as String?,
            isTrusted: doc.data()['isTrusted'] as bool? ?? false,
            healthValue: (doc.data()['healthValue'] as num?)?.toDouble(),
          ),
        )
        .toList(growable: false);

    return Duel(
      id: duel.id,
      habitName: duel.habitName,
      description: duel.description,
      status: duel.status,
      durationDays: duel.durationDays,
      type: duel.type,
      creatorId: duel.creatorId,
      opponentId: duel.opponentId,
      maxParticipants: duel.maxParticipants,
      inviteCode: duel.inviteCode,
      habitCategory: duel.habitCategory,
      isTrustedCheckin: duel.isTrustedCheckin,
      healthMetric: duel.healthMetric,
      healthTargetValue: duel.healthTargetValue,
      entryFee: duel.entryFee,
      currency: duel.currency,
      myStreak: duel.myStreak,
      opponentStreak: duel.opponentStreak,
      startsAt: duel.startsAt,
      endsAt: duel.endsAt,
      createdAt: duel.createdAt,
      participants: parsedParticipants.isNotEmpty ? parsedParticipants : duel.participants,
      checkins: parsedCheckins,
    );
  }

  Duel _duelFromData(String duelId, Map<String, dynamic> data) {
    final participantIds = (data['participantIds'] as List<dynamic>? ?? const []).cast<String>();
    final typeStr = data['type'] as String? ?? 'duel';

    return Duel(
      id: duelId,
      habitName: data['habitName'] as String? ?? '',
      description: data['description'] as String?,
      status: data['status'] as String? ?? 'pending',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      type: DuelType.values.firstWhere((e) => e.name == typeStr, orElse: () => DuelType.duel),
      creatorId: data['creatorId'] as String?,
      opponentId: data['opponentId'] as String?,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 2,
      inviteCode: data['inviteCode'] as String?,
      habitCategory: data['habitCategory'] as String?,
      isTrustedCheckin: data['isTrustedCheckin'] as bool? ?? false,
      healthMetric: data['healthMetric'] as String?,
      healthTargetValue: (data['healthTargetValue'] as num?)?.toDouble(),
      entryFee: (data['entryFee'] as num?)?.toInt() ?? 0,
      currency: DuelCurrency.values.firstWhere(
        (value) => value.name == data['currency'],
        orElse: () => DuelCurrency.tenge,
      ),
      myStreak: (data['myStreak'] as num?)?.toInt() ?? 0,
      opponentStreak: (data['opponentStreak'] as num?)?.toInt() ?? 0,
      startsAt: _readDateTime(data['startsAt']),
      endsAt: _readDateTime(data['endsAt']),
      createdAt: _readDateTime(data['createdAt']),
      participants: participantIds
          .map(
            (participantId) => DuelParticipant(
              userId: participantId,
              username: participantId,
            ),
          )
          .toList(growable: false),
      checkins: const [],
    );
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(rng >> (i * 5)) % chars.length]).join();
  }

  int _weekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (dayOfYear / 7).ceil();
  }

  int _xpForEvent(XpEventType type) {
    return switch (type) {
      XpEventType.checkin => 10,
      XpEventType.streakBonus => 5,
      XpEventType.duelWin => 50,
      XpEventType.groupTop3 => 30,
      XpEventType.firstDuel => 20,
      XpEventType.trustedCheckin => 5,
      XpEventType.achievement => 25,
      XpEventType.quest => 15,
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════════

  Future<List<Achievement>> readAchievements(String userId) async {
    if (!_isEnabled) return [];
    try {
      final snap = await _users.doc(userId).collection('achievements').get();
      if (snap.docs.isEmpty) {
        // Возвращаем дефолтный список достижений
        return _getDefaultAchievements();
      }
      return snap.docs.map((doc) {
        final data = doc.data();
        return Achievement(
          id: doc.id,
          type: data['type'] as String? ?? doc.id,
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          icon: data['icon'] as String? ?? '🏆',
          xpReward: (data['xpReward'] as num?)?.toInt() ?? 25,
          isUnlocked: data['isUnlocked'] as bool? ?? false,
          unlockedAt: _readDateTime(data['unlockedAt']),
          progress: (data['progress'] as num?)?.toInt() ?? 0,
          requiredValue: (data['requiredValue'] as num?)?.toInt() ?? 1,
          category: AchievementCategory.values.firstWhere(
            (c) => c.name == data['category'],
            orElse: () => AchievementCategory.general,
          ),
          isSecret: data['isSecret'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('readAchievements failed: $e');
      return _getDefaultAchievements();
    }
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(id: 'first_checkin', type: 'first_checkin', title: 'Первый шаг', description: 'Отметься впервые', icon: '🎯', xpReward: 10, isUnlocked: false, category: AchievementCategory.general),
      Achievement(id: 'streak_7', type: 'streak_7', title: 'Неделя силы', description: '7 дней серии', icon: '🔥', xpReward: 50, isUnlocked: false, category: AchievementCategory.streak, requiredValue: 7),
      Achievement(id: 'streak_21', type: 'streak_21', title: 'Марафонец', description: '21 день серии', icon: '💎', xpReward: 150, isUnlocked: false, category: AchievementCategory.streak, requiredValue: 21),
      Achievement(id: 'streak_30', type: 'streak_30', title: 'Легенда', description: '30 дней серии', icon: '👑', xpReward: 300, isUnlocked: false, category: AchievementCategory.streak, requiredValue: 30),
      Achievement(id: 'first_win', type: 'first_win', title: 'Победитель', description: 'Первая победа', icon: '🏆', xpReward: 50, isUnlocked: false, category: AchievementCategory.duel),
      Achievement(id: 'duel_master', type: 'duel_master', title: 'Мастер дуэлей', description: '10 побед', icon: '⚔️', xpReward: 200, isUnlocked: false, category: AchievementCategory.duel, requiredValue: 10),
      Achievement(id: 'social_butterfly', type: 'social_butterfly', title: 'Душа компании', description: '5 дуэлей с друзьями', icon: '🦋', xpReward: 100, isUnlocked: false, category: AchievementCategory.social, requiredValue: 5),
      Achievement(id: 'early_bird', type: 'early_bird', title: 'Жаворонок', description: '7 чекинов до 8 утра', icon: '🌅', xpReward: 75, isUnlocked: false, category: AchievementCategory.special, requiredValue: 7),
    ];
  }

  Future<void> claimAchievement({required String userId, required String achievementId}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('achievements').doc(achievementId).set({
        'isUnlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('claimAchievement failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  USER STATS
  // ═══════════════════════════════════════════════════════════════════

  Future<UserStats?> readUserStats(String userId) async {
    if (!_isEnabled) return null;
    try {
      final doc = await _users.doc(userId).collection('stats').doc('overview').get();
      if (!doc.exists) {
        return UserStats(userId: userId);
      }
      final data = doc.data()!;
      return UserStats(
        userId: userId,
        totalCheckins: (data['totalCheckins'] as num?)?.toInt() ?? 0,
        totalDuels: (data['totalDuels'] as num?)?.toInt() ?? 0,
        totalWins: (data['totalWins'] as num?)?.toInt() ?? 0,
        totalLosses: (data['totalLosses'] as num?)?.toInt() ?? 0,
        bestStreak: (data['bestStreak'] as num?)?.toInt() ?? 0,
        currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
        averageCheckinHour: (data['averageCheckinHour'] as num?)?.toDouble() ?? 9.0,
        favoriteHabitCategory: data['favoriteHabitCategory'] as String?,
      );
    } catch (e) {
      debugPrint('readUserStats failed: $e');
      return UserStats(userId: userId);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SOCIAL — FRIENDS & REQUESTS
  // ═══════════════════════════════════════════════════════════════════

  Future<List<Friend>?> readFriends(String userId) async {
    if (!_isEnabled) return null;
    try {
      final snap = await _users.doc(userId).collection('friends').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return Friend(
          id: doc.id,
          userId: data['userId'] as String? ?? doc.id,
          username: data['username'] as String? ?? '',
          avatarUrl: data['avatarUrl'] as String? ?? '',
          level: (data['level'] as num?)?.toInt() ?? 1,
          totalWins: (data['totalWins'] as num?)?.toInt() ?? 0,
          isOnline: data['isOnline'] as bool? ?? false,
          lastActiveAt: _readDateTime(data['lastActiveAt']),
          friendSince: _readDateTime(data['friendSince']),
          totalDuelsTogether: (data['totalDuelsTogether'] as num?)?.toInt() ?? 0,
          winsAgainstMe: (data['winsAgainstMe'] as num?)?.toInt() ?? 0,
          lossesAgainstMe: (data['lossesAgainstMe'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('readFriends failed: $e');
      return null;
    }
  }

  Future<List<FriendRequest>?> readFriendRequests(String userId) async {
    if (!_isEnabled) return null;
    try {
      final snap = await _users.doc(userId).collection('friendRequests').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return FriendRequest(
          id: doc.id,
          fromUserId: data['fromUserId'] as String? ?? '',
          fromUsername: data['fromUsername'] as String? ?? '',
          fromAvatar: data['fromAvatar'] as String? ?? '',
          createdAt: _readDateTime(data['createdAt']) ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('readFriendRequests failed: $e');
      return null;
    }
  }

  Future<List<OpponentRecommendation>?> readOpponentRecommendations(String userId) async {
    if (!_isEnabled) return null;
    // Заглушка — в реальной реализации будет умный подбор
    return [
      OpponentRecommendation(userId: 'rec1', username: 'Player1', level: 5, totalWins: 20, winRate: 55, commonHabits: ['Спорт']),
      OpponentRecommendation(userId: 'rec2', username: 'Player2', level: 3, totalWins: 12, winRate: 45, commonHabits: ['Чтение']),
    ];
  }

  Future<void> sendFriendRequest({required String fromUserId, required String toUserId}) async {
    if (!_isEnabled) return;
    try {
      final fromUser = await _users.doc(fromUserId).get();
      await _users.doc(toUserId).collection('friendRequests').add({
        'fromUserId': fromUserId,
        'fromUsername': fromUser.data()?['username'] ?? '',
        'fromAvatar': fromUser.data()?['avatarUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('sendFriendRequest failed: $e');
    }
  }

  Future<void> acceptFriendRequest({required String requestId}) async {
    if (!_isEnabled) return;
    try {
      // Нужно найти документ запроса и добавить в друзья обеим сторонам
      // Упрощённая реализация
    } catch (e) {
      debugPrint('acceptFriendRequest failed: $e');
    }
  }

  Future<void> declineFriendRequest({required String requestId}) async {
    if (!_isEnabled) return;
    try {
      // Удалить запрос
    } catch (e) {
      debugPrint('declineFriendRequest failed: $e');
    }
  }

  Future<void> removeFriend({required String friendId}) async {
    if (!_isEnabled) return;
    try {
      // Удалить из друзей
    } catch (e) {
      debugPrint('removeFriend failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CHAT MESSAGES
  // ═══════════════════════════════════════════════════════════════════

  Future<List<DuelMessage>?> readDuelMessages(String duelId) async {
    if (!_isEnabled) return null;
    try {
      final snap = await _duels.doc(duelId).collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return DuelMessage(
          id: doc.id,
          duelId: duelId,
          senderId: data['senderId'] as String? ?? '',
          senderName: data['senderName'] as String? ?? '',
          messageType: DuelMessageType.values.firstWhere(
            (t) => t.name == data['messageType'],
            orElse: () => DuelMessageType.text,
          ),
          text: data['text'] as String?,
          emoji: data['emoji'] as String?,
          createdAt: _readDateTime(data['createdAt']),
          isRead: data['isRead'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('readDuelMessages failed: $e');
      return null;
    }
  }

  Future<void> sendDuelMessage({
    required String duelId,
    required String senderId,
    required String senderName,
    String? text,
    String? emoji,
  }) async {
    if (!_isEnabled) return;
    try {
      await _duels.doc(duelId).collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'messageType': emoji != null ? 'emoji' : 'text',
        if (text != null) 'text': text,
        if (emoji != null) 'emoji': emoji,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('sendDuelMessage failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHOP & CURRENCY
  // ═══════════════════════════════════════════════════════════════════

  Future<List<ShopItem>?> readShopItems() async {
    if (!_isEnabled) return null;
    try {
      final snap = await _db.collection('shop').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return ShopItem(
          id: doc.id,
          type: ShopItemType.values.firstWhere((t) => t.name == data['type'], orElse: () => ShopItemType.avatar),
          name: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          icon: data['icon'] as String? ?? '',
          price: (data['price'] as num?)?.toInt() ?? 0,
          currency: ShopCurrency.values.firstWhere((c) => c.name == data['currency'], orElse: () => ShopCurrency.xp),
          requiredLevel: (data['requiredLevel'] as num?)?.toInt() ?? 1,
          category: ShopCategory.values.firstWhere((c) => c.name == data['category'], orElse: () => ShopCategory.all),
          isLimited: data['isLimited'] as bool? ?? false,
          limitedUntil: _readDateTime(data['limitedUntil']),
        );
      }).toList();
    } catch (e) {
      debugPrint('readShopItems failed: $e');
      return null;
    }
  }

  Future<List<Booster>?> readUserBoosters(String userId) async {
    if (!_isEnabled) return null;
    try {
      final snap = await _users.doc(userId).collection('boosters').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return Booster(
          id: doc.id,
          type: BoosterType.values.firstWhere((t) => t.name == data['type'], orElse: () => BoosterType.doubleXp),
          name: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          icon: data['icon'] as String? ?? '',
          durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
          isActive: data['isActive'] as bool? ?? false,
          expiresAt: _readDateTime(data['expiresAt']),
        );
      }).toList();
    } catch (e) {
      debugPrint('readUserBoosters failed: $e');
      return null;
    }
  }

  Future<UserCurrency?> readUserCurrency(String userId) async {
    if (!_isEnabled) return null;
    try {
      final doc = await _users.doc(userId).collection('currency').doc('current').get();
      if (!doc.exists) return const UserCurrency();
      final data = doc.data()!;
      return UserCurrency(
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        gems: (data['gems'] as num?)?.toInt() ?? 0,
        tenge: (data['tenge'] as num?)?.toInt() ?? (data['coins'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('readUserCurrency failed: $e');
      return const UserCurrency();
    }
  }

  Future<void> topUpTenge({
    required String userId,
    required int amount,
  }) async {
    if (!_isEnabled || amount <= 0) return;
    await _changeUserTenge(userId: userId, delta: amount);
  }

  Future<void> spendTenge({
    required String userId,
    required int amount,
  }) async {
    if (!_isEnabled || amount <= 0) return;
    await _ensureEnoughTenge(userId: userId, amount: amount);
    await _changeUserTenge(userId: userId, delta: -amount);
  }

  Future<void> _ensureEnoughTenge({
    required String userId,
    required int amount,
  }) async {
    if (amount <= 0) return;
    final balance = await _readUserTenge(userId);
    if (balance < amount) {
      throw Exception('Недостаточно средств на балансе');
    }
  }

  Future<int> _readUserTenge(String userId) async {
    final currency = await readUserCurrency(userId);
    return currency?.tenge ?? 0;
  }

  Future<void> _changeUserTenge({
    required String userId,
    required int delta,
  }) async {
    if (!_isEnabled || delta == 0) return;
    await _users.doc(userId).collection('currency').doc('current').set(
      {'tenge': FieldValue.increment(delta)},
      SetOptions(merge: true),
    );
  }

  Future<List<UserAvatar>?> readUserAvatars(String userId) async {
    if (!_isEnabled) return null;
    try {
      final snap = await _users.doc(userId).collection('avatars').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return UserAvatar(
          id: doc.id,
          name: data['name'] as String? ?? '',
          icon: data['icon'] as String? ?? '',
          backgroundColor: (data['backgroundColor'] as num?)?.toInt() ?? 0xFFEA580C,
          isUnlocked: data['isUnlocked'] as bool? ?? false,
          isEquipped: data['isEquipped'] as bool? ?? false,
          unlockedAt: _readDateTime(data['unlockedAt']),
          source: AvatarSource.values.firstWhere((s) => s.name == data['source'], orElse: () => AvatarSource.defaultAvatar),
        );
      }).toList();
    } catch (e) {
      debugPrint('readUserAvatars failed: $e');
      return null;
    }
  }

  Future<void> purchaseItem({required String userId, required String itemId}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('inventory').doc(itemId).set({
        'itemId': itemId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'isEquipped': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('purchaseItem failed: $e');
    }
  }

  Future<void> spendXp({required String userId, required int amount}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('currency').doc('current').set({
        'xp': FieldValue.increment(-amount),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('spendXp failed: $e');
    }
  }

  Future<void> equipItem({required String userId, required String itemId}) async {
    if (!_isEnabled) return;
    try {
      // Логика экипировки предмета
    } catch (e) {
      debugPrint('equipItem failed: $e');
    }
  }

  Future<void> activateBooster({required String userId, required String boosterId}) async {
    if (!_isEnabled) return;
    try {
      // Логика активации бустера
    } catch (e) {
      debugPrint('activateBooster failed: $e');
    }
  }

  Future<void> equipAvatar({required String userId, required String avatarId}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('avatars').doc(avatarId).update({
        'isEquipped': true,
      });
      // Снять экипировку с других аватаров
    } catch (e) {
      debugPrint('equipAvatar failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EVENTS & QUESTS
  // ═══════════════════════════════════════════════════════════════════

  Future<List<GameEvent>?> readActiveEvents() async {
    if (!_isEnabled) return null;
    try {
      final now = Timestamp.now();
      final snap = await _db.collection('events')
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return GameEvent(
          id: doc.id,
          type: GameEventType.values.firstWhere((t) => t.name == data['type'], orElse: () => GameEventType.weekly),
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          icon: data['icon'] as String? ?? '🎯',
          startDate: _readDateTime(data['startDate']) ?? DateTime.now(),
          endDate: _readDateTime(data['endDate']) ?? DateTime.now(),
          participantsCount: (data['participantsCount'] as num?)?.toInt() ?? 0,
          isActive: true,
          bannerColor: (data['bannerColor'] as num?)?.toInt() ?? 0xFFEA580C,
        );
      }).toList();
    } catch (e) {
      debugPrint('readActiveEvents failed: $e');
      return null;
    }
  }

  Future<List<DailyQuest>?> readDailyQuests(String userId) async {
    if (!_isEnabled) return null;
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final snap = await _users.doc(userId).collection('quests').doc(dateKey).collection('daily').get();
      if (snap.docs.isEmpty) {
        return _getDefaultDailyQuests(userId);
      }
      return snap.docs.map((doc) {
        final data = doc.data();
        return DailyQuest(
          id: doc.id,
          type: DailyQuestType.values.firstWhere((t) => t.name == data['type'], orElse: () => DailyQuestType.checkin),
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          xpReward: (data['xpReward'] as num?)?.toInt() ?? 15,
          currentProgress: (data['currentProgress'] as num?)?.toInt() ?? 0,
          targetProgress: (data['targetProgress'] as num?)?.toInt() ?? 1,
          isCompleted: data['isCompleted'] as bool? ?? false,
          isClaimed: data['isClaimed'] as bool? ?? false,
          resetAt: _readDateTime(data['resetAt']),
        );
      }).toList();
    } catch (e) {
      debugPrint('readDailyQuests failed: $e');
      return _getDefaultDailyQuests(userId);
    }
  }

  List<DailyQuest> _getDefaultDailyQuests(String userId) {
    final now = DateTime.now();
    final resetAt = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return [
      DailyQuest(id: 'q1', type: DailyQuestType.checkin, title: 'Первый чекин', description: 'Отметься сегодня', xpReward: 15, currentProgress: 0, targetProgress: 1, isCompleted: false, resetAt: resetAt),
      DailyQuest(id: 'q2', type: DailyQuestType.duelWin, title: 'Победа', description: 'Выиграй дуэль', xpReward: 30, currentProgress: 0, targetProgress: 1, isCompleted: false, resetAt: resetAt),
      DailyQuest(id: 'q3', type: DailyQuestType.checkin3, title: 'Тройной удар', description: '3 чекина за день', xpReward: 50, currentProgress: 0, targetProgress: 3, isCompleted: false, resetAt: resetAt),
    ];
  }

  Future<Season?> readCurrentSeason() async {
    if (!_isEnabled) return null;
    try {
      final now = Timestamp.now();
      final snap = await _db.collection('seasons')
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final data = doc.data();
      return Season(
        id: doc.id,
        number: (data['number'] as num?)?.toInt() ?? 1,
        name: data['name'] as String? ?? '',
        startDate: _readDateTime(data['startDate']) ?? DateTime.now(),
        endDate: _readDateTime(data['endDate']) ?? DateTime.now(),
        isActive: true,
      );
    } catch (e) {
      debugPrint('readCurrentSeason failed: $e');
      return null;
    }
  }

  Future<void> claimQuestReward({required String userId, required String questId}) async {
    if (!_isEnabled) return;
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _users.doc(userId).collection('quests').doc(dateKey).collection('daily').doc(questId).update({
        'isClaimed': true,
      });
    } catch (e) {
      debugPrint('claimQuestReward failed: $e');
    }
  }

  Future<void> claimEventReward({required String userId, required String eventId, required String rewardId}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('eventRewards').doc('${eventId}_$rewardId').set({
        'eventId': eventId,
        'rewardId': rewardId,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('claimEventReward failed: $e');
    }
  }

  Future<void> joinEvent({required String userId, required String eventId}) async {
    if (!_isEnabled) return;
    try {
      await _users.doc(userId).collection('events').doc(eventId).set({
        'eventId': eventId,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('joinEvent failed: $e');
    }
  }

  Future<void> updateQuestProgress({required String userId, required DailyQuestType type, required int amount}) async {
    if (!_isEnabled) return;
    try {
      // Найти квест по типу и обновить прогресс
    } catch (e) {
      debugPrint('updateQuestProgress failed: $e');
    }
  }
}

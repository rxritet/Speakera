import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/duel.dart';
import '../../domain/entities/profile.dart';
import '../models/duel_model.dart';
import 'leaderboard_remote_ds.dart' show LeaderboardResult;

/// Профиль пользователя — теперь только из Firestore.
class FirebaseAwareProfileDataSource {
  FirebaseAwareProfileDataSource(this._storage, this._store);

  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  Future<UserProfile> getMyProfile() async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId != null && userId.isNotEmpty) {
      try {
        final profile = await _store.readProfile(userId);
        if (profile != null) return profile;
      } catch (_) {}

      // Fallback из SecureStorage если нет в Firestore
      return UserProfile(
        id: userId,
        username: username ?? '',
        wins: 0,
        losses: 0,
        badges: const [],
        avatarEmoji: '🔥',
      );
    }

    throw const NetworkFailure('User not authenticated');
  }
}

/// Лидерборд — теперь только из Firestore.
class FirebaseAwareLeaderboardDataSource {
  FirebaseAwareLeaderboardDataSource(this._store);

  final HabitDuelFirestoreStore _store;

  Future<LeaderboardResult> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _store.readLeaderboard(limit: limit, offset: offset);
      return LeaderboardResult(entries: result.entries, total: result.total);
    } catch (_) {
      return LeaderboardResult(entries: const [], total: 0);
    }
  }

  Stream<LeaderboardResult> watchLeaderboard({
    int limit = 50,
    int offset = 0,
  }) {
    return _store.watchLeaderboard(limit: limit, offset: offset).map((result) {
      return LeaderboardResult(entries: result.entries, total: result.total);
    });
  }
}

/// Дуэли — Firestore primary (без REST fallback на старый сервер).
class FirebaseAwareDuelDataSource {
  FirebaseAwareDuelDataSource(this._storage, this._store);

  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  Future<DuelModel> createDuel({
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
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId == null || userId.isEmpty) {
      throw const AuthFailure('Not authenticated');
    }

    final duel = await _store.createDuelInFirestore(
      creatorId: userId,
      creatorUsername: username ?? userId,
      habitName: habitName,
      description: description,
      durationDays: durationDays,
      opponentUsername: opponentUsername,
      type: type,
      maxParticipants: maxParticipants,
      habitCategory: habitCategory,
      isTrustedCheckin: isTrustedCheckin,
      healthMetric: healthMetric,
      healthTargetValue: healthTargetValue,
      entryFee: entryFee,
      currency: currency,
    );

    return _toDuelModel(duel);
  }

  Future<DuelModel> acceptDuel(String duelId) async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId == null || userId.isEmpty) throw const AuthFailure('Not authenticated');

    await _store.acceptDuelInFirestore(
      duelId: duelId,
      userId: userId,
      username: username ?? userId,
    );

    final updated = await _store.readDuel(duelId);
    if (updated == null) throw const NetworkFailure('Duel not found');
    return _toDuelModel(updated);
  }

  Future<List<DuelModel>> getMyDuels() async {
    final userId = await _storage.read(key: kUserIdKey);
    if (userId == null || userId.isEmpty) return const [];

    try {
      final duels = await _store.readMyDuels(userId);
      return duels.map(_toDuelModel).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<DuelModel> getDuelDetail(String duelId) async {
    final duel = await _store.readDuel(duelId);
    if (duel == null) throw const NetworkFailure('Duel not found');
    return _toDuelModel(duel);
  }

  Future<Map<String, dynamic>> checkIn(String duelId, {String? note}) async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId == null || userId.isEmpty) throw const AuthFailure('Not authenticated');

    await _store.checkInInFirestore(
      duelId: duelId,
      userId: userId,
      username: username ?? userId,
      note: note,
    );

    return {'status': 'ok', 'duelId': duelId};
  }

  Future<DuelModel?> joinGroupByInviteCode(String inviteCode) async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId == null || userId.isEmpty) throw const AuthFailure('Not authenticated');

    final duel = await _store.joinGroupDuelByInviteCode(
      inviteCode: inviteCode,
      userId: userId,
      username: username ?? userId,
    );

    return duel != null ? _toDuelModel(duel) : null;
  }

  Future<void> joinOpenDuel(String duelId) async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    if (userId == null || userId.isEmpty) throw const AuthFailure('Not authenticated');

    await _store.joinOpenDuel(
      duelId: duelId,
      userId: userId,
      username: username ?? userId,
    );
  }

  /// Real-time stream дуэли.
  Stream<DuelModel?> watchDuel(String duelId) {
    return _store.watchDuel(duelId).map((d) => d != null ? _toDuelModel(d) : null);
  }

  /// Real-time stream списка дуэлей.
  Stream<List<DuelModel>> watchMyDuels(String userId) {
    return _store.watchMyDuels(userId).map((list) => list.map(_toDuelModel).toList());
  }

  /// Real-time stream открытых групповых дуэлей.
  Stream<List<DuelModel>> watchOpenGroupDuels() {
    return _store.watchOpenGroupDuels().map((list) => list.map(_toDuelModel).toList());
  }

  DuelModel _toDuelModel(Duel duel) {
    return DuelModel(
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
      participants: duel.participants,
      checkins: duel.checkins,
    );
  }
}

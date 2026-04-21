import 'dart:async';

import '../../domain/entities/duel.dart';
import '../../domain/repositories/duel_repository.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../datasources/firebase_aware_data_sources.dart';

class DuelRepositoryImpl implements DuelRepository {
  const DuelRepositoryImpl(this._remoteDS);
  final FirebaseAwareDuelDataSource _remoteDS;

  @override
  Future<Duel> createDuel({
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
  }) async {
    return _remoteDS.createDuel(
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
    );
  }

  @override
  Future<Duel> acceptDuel(String duelId) => _remoteDS.acceptDuel(duelId);

  @override
  Future<List<Duel>> getMyDuels() => _remoteDS.getMyDuels();

  @override
  Future<Duel> getDuelDetail(String duelId) => _remoteDS.getDuelDetail(duelId);

  @override
  Future<CheckInResult> checkIn(String duelId, {String? note}) async {
    final data = await _remoteDS.checkIn(duelId, note: note);
    return CheckInResult(
      checkinId: data['checkinId'] as String? ?? '',
      duelId: data['duelId'] as String? ?? duelId,
      newStreak: (data['streak'] as num?)?.toInt() ?? 0,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<Duel?> joinGroupByInviteCode(String inviteCode) {
    return _remoteDS.joinGroupByInviteCode(inviteCode);
  }

  @override
  Stream<Duel?> watchDuel(String duelId) => _remoteDS.watchDuel(duelId);

  @override
  Stream<List<Duel>> watchMyDuels(String userId) => _remoteDS.watchMyDuels(userId);
}

import '../../domain/entities/duel.dart';
import '../../domain/repositories/duel_repository.dart';
import '../datasources/duel_remote_ds.dart';

class DuelRepositoryImpl implements DuelRepository {
  const DuelRepositoryImpl(this._remoteDS);
  final DuelRemoteDataSource _remoteDS;

  @override
  Future<Duel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  }) {
    return _remoteDS.createDuel(
      habitName: habitName,
      description: description,
      durationDays: durationDays,
      opponentUsername: opponentUsername,
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
      checkinId: data['checkin_id'] as String,
      duelId: data['duel_id'] as String,
      newStreak: (data['new_streak'] as num).toInt(),
      checkedAt: DateTime.parse(data['checked_at'] as String),
    );
  }
}

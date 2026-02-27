import '../entities/duel.dart';

/// Abstract contract for duel operations.
abstract class DuelRepository {
  /// Create a new duel.
  Future<Duel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  });

  /// Accept a pending duel.
  Future<Duel> acceptDuel(String duelId);

  /// Get list of user's duels.
  Future<List<Duel>> getMyDuels();

  /// Get full duel detail by id.
  Future<Duel> getDuelDetail(String duelId);

  /// Perform a check-in on a duel.
  Future<CheckInResult> checkIn(String duelId, {String? note});
}

class CheckInResult {
  const CheckInResult({
    required this.checkinId,
    required this.duelId,
    required this.newStreak,
    required this.checkedAt,
  });

  final String checkinId;
  final String duelId;
  final int newStreak;
  final DateTime checkedAt;
}

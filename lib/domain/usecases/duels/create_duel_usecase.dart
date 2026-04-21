import '../../repositories/duel_repository.dart';
import '../../entities/duel.dart';

class CreateDuelUseCase {
  const CreateDuelUseCase(this._repo);
  final DuelRepository _repo;

  Future<Duel> call({
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
  }) {
    return _repo.createDuel(
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
}

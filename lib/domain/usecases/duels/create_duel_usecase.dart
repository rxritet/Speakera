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
  }) {
    return _repo.createDuel(
      habitName: habitName,
      description: description,
      durationDays: durationDays,
      opponentUsername: opponentUsername,
    );
  }
}

import '../../repositories/duel_repository.dart';
import '../../entities/duel.dart';

class AcceptDuelUseCase {
  const AcceptDuelUseCase(this._repo);
  final DuelRepository _repo;

  Future<Duel> call(String duelId) => _repo.acceptDuel(duelId);
}

import '../../repositories/duel_repository.dart';
import '../../entities/duel.dart';

class GetMyDuelsUseCase {
  const GetMyDuelsUseCase(this._repo);
  final DuelRepository _repo;

  Future<List<Duel>> call() => _repo.getMyDuels();
}

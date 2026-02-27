import '../../repositories/duel_repository.dart';
import '../../entities/duel.dart';

class GetDuelDetailUseCase {
  const GetDuelDetailUseCase(this._repo);
  final DuelRepository _repo;

  Future<Duel> call(String duelId) => _repo.getDuelDetail(duelId);
}

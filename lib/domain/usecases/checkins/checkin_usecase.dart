import '../../repositories/duel_repository.dart';

class CheckInUseCase {
  const CheckInUseCase(this._repo);
  final DuelRepository _repo;

  Future<CheckInResult> call(String duelId, {String? note}) {
    return _repo.checkIn(duelId, note: note);
  }
}

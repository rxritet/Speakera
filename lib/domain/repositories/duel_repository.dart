import '../entities/duel.dart';

/// Абстрактный контракт дуэлей.
abstract class DuelRepository {
  /// Создать дуэль.
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
    int entryFee = 0,
    DuelCurrency currency = DuelCurrency.tenge,
  });

  /// Принять ожидающую дуэль.
  Future<Duel> acceptDuel(String duelId);

  /// Список дуэлей пользователя.
  Future<List<Duel>> getMyDuels();

  /// Полная информация о дуэли по id.
  Future<Duel> getDuelDetail(String duelId);

  /// Выполнить check-in в дуэли.
  Future<CheckInResult> checkIn(String duelId, {String? note});

  /// Присоединиться к групповой дуэли по invite code.
  Future<Duel?> joinGroupByInviteCode(String inviteCode);

  /// Присоединиться к открытой дуэли (лобби).
  Future<void> joinOpenDuel(String duelId);

  /// Real-time stream конкретной дуэли.
  Stream<Duel?> watchDuel(String duelId);

  /// Real-time stream списка дуэлей пользователя.
  Stream<List<Duel>> watchMyDuels(String userId);

  /// Real-time stream списка открытых групповых дуэлей.
  Stream<List<Duel>> watchOpenGroupDuels();
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

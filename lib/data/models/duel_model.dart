import '../../domain/entities/duel.dart';

class DuelModel extends Duel {
  const DuelModel({
    required super.id,
    required super.habitName,
    super.description,
    required super.status,
    required super.durationDays,
    super.type,
    super.creatorId,
    super.opponentId,
    super.maxParticipants,
    super.inviteCode,
    super.habitCategory,
    super.isTrustedCheckin,
    super.healthMetric,
    super.healthTargetValue,
    super.myStreak,
    super.opponentStreak,
    super.startsAt,
    super.endsAt,
    super.createdAt,
    super.participants,
    super.checkins,
  });
}

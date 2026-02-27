/// Pure domain entity for a Duel.
class Duel {
  const Duel({
    required this.id,
    required this.habitName,
    this.description,
    required this.status,
    required this.durationDays,
    this.creatorId,
    this.opponentId,
    this.myStreak = 0,
    this.opponentStreak = 0,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.participants = const [],
    this.checkins = const [],
  });

  final String id;
  final String habitName;
  final String? description;
  final String status;
  final int durationDays;
  final String? creatorId;
  final String? opponentId;
  final int myStreak;
  final int opponentStreak;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final List<DuelParticipant> participants;
  final List<CheckInEntry> checkins;
}

class DuelParticipant {
  const DuelParticipant({
    required this.userId,
    required this.username,
    this.streak = 0,
    this.lastCheckin,
  });

  final String userId;
  final String username;
  final int streak;
  final String? lastCheckin;
}

class CheckInEntry {
  const CheckInEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.checkedAt,
    this.note,
  });

  final String id;
  final String userId;
  final String username;
  final DateTime checkedAt;
  final String? note;
}

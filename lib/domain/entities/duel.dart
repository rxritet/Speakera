class Duel {
  const Duel({
    required this.id,
    required this.habitName,
    this.description,
    required this.status,
    required this.durationDays,
    this.type = DuelType.duel,
    this.creatorId,
    this.opponentId,
    this.maxParticipants = 2,
    this.inviteCode,
    this.habitCategory,
    this.isTrustedCheckin = false,
    this.healthMetric,
    this.healthTargetValue,
    this.myStreak = 0,
    this.opponentStreak = 0,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.participants = const [],
    this.checkins = const [],
    this.entryFee = 0,
    this.currency = DuelCurrency.tenge,
  });

  final String id;
  final String habitName;
  final String? description;
  final String status;
  final int durationDays;
  final DuelType type;
  final String? creatorId;
  final String? opponentId;
  final int maxParticipants;
  final String? inviteCode;
  final String? habitCategory;
  final bool isTrustedCheckin;
  final String? healthMetric;
  final double? healthTargetValue;
  final int myStreak;
  final int opponentStreak;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final List<DuelParticipant> participants;
  final List<CheckInEntry> checkins;
  final int entryFee;
  final DuelCurrency currency;

  bool get isGroup => type == DuelType.group;
  bool get isOpen => status == 'open';
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get hasEntryFee => entryFee > 0;
  int get prizePool => entryFee * participants.length;

  List<DuelParticipant> get rankedParticipants {
    final sorted = [...participants];
    sorted.sort((a, b) => b.streak.compareTo(a.streak));
    return sorted;
  }

  Duel copyWith({
    String? id,
    String? habitName,
    String? description,
    String? status,
    int? durationDays,
    DuelType? type,
    String? creatorId,
    String? opponentId,
    int? maxParticipants,
    String? inviteCode,
    String? habitCategory,
    bool? isTrustedCheckin,
    String? healthMetric,
    double? healthTargetValue,
    int? myStreak,
    int? opponentStreak,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? createdAt,
    List<DuelParticipant>? participants,
    List<CheckInEntry>? checkins,
    int? entryFee,
    DuelCurrency? currency,
  }) {
    return Duel(
      id: id ?? this.id,
      habitName: habitName ?? this.habitName,
      description: description ?? this.description,
      status: status ?? this.status,
      durationDays: durationDays ?? this.durationDays,
      type: type ?? this.type,
      creatorId: creatorId ?? this.creatorId,
      opponentId: opponentId ?? this.opponentId,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      inviteCode: inviteCode ?? this.inviteCode,
      habitCategory: habitCategory ?? this.habitCategory,
      isTrustedCheckin: isTrustedCheckin ?? this.isTrustedCheckin,
      healthMetric: healthMetric ?? this.healthMetric,
      healthTargetValue: healthTargetValue ?? this.healthTargetValue,
      myStreak: myStreak ?? this.myStreak,
      opponentStreak: opponentStreak ?? this.opponentStreak,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      checkins: checkins ?? this.checkins,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
    );
  }
}

enum DuelType {
  duel,
  group,
}

enum DuelCurrency {
  tenge('Тенге', '₸');

  const DuelCurrency(this.label, this.symbol);
  final String label;
  final String symbol;
}

class DuelParticipant {
  const DuelParticipant({
    required this.userId,
    required this.username,
    this.streak = 0,
    this.lastCheckin,
    this.xpGained = 0,
    this.isEliminated = false,
    this.rank,
  });

  final String userId;
  final String username;
  final int streak;
  final String? lastCheckin;
  final int xpGained;
  final bool isEliminated;
  final int? rank;
}

class CheckInEntry {
  const CheckInEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.checkedAt,
    this.note,
    this.isTrusted = false,
    this.healthValue,
  });

  final String id;
  final String userId;
  final String username;
  final DateTime checkedAt;
  final String? note;
  final bool isTrusted;
  final double? healthValue;
}

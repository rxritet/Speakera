/// Доменная сущность дуэля.
///
/// Поддерживает оба режима: классический 1v1 ([type] == 'duel')
/// и групповой ([type] == 'group') для 3–10 участников.
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
  });

  final String id;
  final String habitName;
  final String? description;
  final String status;
  final int durationDays;
  final DuelType type;
  final String? creatorId;
  final String? opponentId;

  /// Максимальное число участников (2 для 1v1, 3–10 для группы).
  final int maxParticipants;

  /// Код приглашения для группового лобби.
  final String? inviteCode;

  /// Категория привычки: fitness, health, learning, mindfulness, etc.
  final String? habitCategory;

  /// Автоматический check-in via Health data.
  final bool isTrustedCheckin;

  /// Метрика здоровья: 'steps', 'sleep_hours', 'active_minutes', etc.
  final String? healthMetric;

  /// Целевое значение метрики здоровья в сутки.
  final double? healthTargetValue;

  final int myStreak;
  final int opponentStreak;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final List<DuelParticipant> participants;
  final List<CheckInEntry> checkins;

  bool get isGroup => type == DuelType.group;
  bool get isOpen => status == 'open';
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  /// Отсортированные участники по убыванию стрика (для группового лидерборда).
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
    );
  }
}

enum DuelType {
  duel,  // Классический 1v1
  group, // Групповой (3–10 игроков)
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

  /// XP, заработанный в этой дуэли.
  final int xpGained;

  /// Участник выбыл из групповой дуэли (пропустил чекин).
  final bool isEliminated;

  /// Текущее место в групповом лидерборде.
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

  /// Чекин подтверждён автоматически через Health данные.
  final bool isTrusted;

  /// Значение метрики здоровья на момент чекина.
  final double? healthValue;
}

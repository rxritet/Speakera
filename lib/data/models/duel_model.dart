import '../../domain/entities/duel.dart';

class DuelModel extends Duel {
  const DuelModel({
    required super.id,
    required super.habitName,
    super.description,
    required super.status,
    required super.durationDays,
    super.creatorId,
    super.opponentId,
    super.myStreak,
    super.opponentStreak,
    super.startsAt,
    super.endsAt,
    super.createdAt,
    super.participants,
    super.checkins,
  });

  /// Parse from GET /duels list item.
  factory DuelModel.fromListJson(Map<String, dynamic> json) {
    return DuelModel(
      id: json['id'] as String,
      habitName: json['habit_name'] as String,
      status: json['status'] as String,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      myStreak: (json['my_streak'] as num?)?.toInt() ?? 0,
      opponentStreak: (json['opponent_streak'] as num?)?.toInt() ?? 0,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
    );
  }

  /// Parse from GET /duels/:id detail.
  factory DuelModel.fromDetailJson(Map<String, dynamic> json) {
    final parts = (json['participants'] as List<dynamic>? ?? [])
        .map((p) => DuelParticipant(
              userId: p['user_id'] as String,
              username: p['username'] as String,
              streak: (p['streak'] as num?)?.toInt() ?? 0,
              lastCheckin: p['last_checkin'] as String?,
            ))
        .toList();

    final checks = (json['checkins'] as List<dynamic>? ?? [])
        .map((c) => CheckInEntry(
              id: c['id'] as String,
              userId: c['user_id'] as String,
              username: c['username'] as String,
              checkedAt: DateTime.parse(c['checked_at'] as String),
              note: c['note'] as String?,
            ))
        .toList();

    return DuelModel(
      id: json['id'] as String,
      habitName: json['habit_name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      creatorId: json['creator_id'] as String?,
      opponentId: json['opponent_id'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      participants: parts,
      checkins: checks,
    );
  }

  /// Parse from POST /duels create response.
  factory DuelModel.fromCreateJson(Map<String, dynamic> json) {
    return DuelModel(
      id: json['id'] as String,
      habitName: json['habit_name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

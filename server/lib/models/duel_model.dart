/// Dart model for the `duels` table.
class DuelModel {
  DuelModel({
    required this.id,
    required this.habitName,
    this.description,
    required this.creatorId,
    this.opponentId,
    required this.status,
    required this.durationDays,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
  });

  factory DuelModel.fromRow(Map<String, dynamic> row) {
    return DuelModel(
      id: row['id'] as String,
      habitName: row['habit_name'] as String,
      description: row['description'] as String?,
      creatorId: row['creator_id'] as String,
      opponentId: row['opponent_id'] as String?,
      status: row['status'] as String,
      durationDays: row['duration_days'] as int,
      startsAt: row['starts_at'] as DateTime?,
      endsAt: row['ends_at'] as DateTime?,
      createdAt: row['created_at'] is DateTime
          ? row['created_at'] as DateTime
          : DateTime.parse(row['created_at'].toString()),
    );
  }

  final String id;
  final String habitName;
  final String? description;
  final String creatorId;
  final String? opponentId;
  final String status;
  final int durationDays;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'habit_name': habitName,
        'description': description,
        'creator_id': creatorId,
        'opponent_id': opponentId,
        'status': status,
        'duration_days': durationDays,
        'starts_at': startsAt?.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

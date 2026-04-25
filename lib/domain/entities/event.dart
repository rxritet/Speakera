/// События и челленджи.
class GameEvent {
  const GameEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.startDate,
    required this.endDate,
    this.rewards = const [],
    this.participantsCount = 0,
    this.userProgress,
    this.isActive = false,
    this.bannerColor = const Color(0xFFEA580C),
  });

  final String id;
  final GameEventType type;
  final String title;
  final String description;
  final String icon;
  final DateTime startDate;
  final DateTime endDate;
  final List<EventReward> rewards;
  final int participantsCount;
  final EventProgress? userProgress;
  final bool isActive;
  final int bannerColor;

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isEnded => endDate.isBefore(DateTime.now());
  
  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 365);
  
  double get progressPercent => userProgress?.progressPercent ?? 0;
}

enum GameEventType {
  weekly('Еженедельный', 'Недельный челлендж с наградами'),
  seasonal('Сезонный', 'Большое событие на месяц'),
  tournament('Турнир', 'Соревнование на выбывание'),
  special('Специальный', 'Ограниченное событие'),
  daily('Ежедневный', 'Ежедневная задача');

  const GameEventType(this.label, this.description);
  final String label;
  final String description;
}

/// Прогресс пользователя в событии.
class EventProgress {
  const EventProgress({
    required this.eventId,
    required this.currentValue,
    required this.targetValue,
    this.completedTasks = const [],
    this.claimedRewards = const [],
  });

  final String eventId;
  final int currentValue;
  final int targetValue;
  final List<String> completedTasks;
  final List<String> claimedRewards;

  double get progressPercent => targetValue > 0 ? (currentValue / targetValue * 100) : 0;
  bool get isComplete => currentValue >= targetValue;
  
  int get remaining => targetValue - currentValue;
}

/// Награда за событие.
class EventReward {
  const EventReward({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.value,
    this.isClaimed = false,
    this.requiredProgress = 0,
  });

  final String id;
  final RewardType type;
  final String name;
  final String icon;
  final int value;
  final bool isClaimed;
  final int requiredProgress;
}

enum RewardType {
  xp('XP'),
  gems('Гемы'),
  coins('Монеты'),
  item('Предмет'),
  badge('Бейдж'),
  booster('Бустер');

  const RewardType(this.label);
  final String label;
}

/// Ежедневная задача.
class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    this.isClaimed = false,
    this.resetAt,
  });

  final String id;
  final DailyQuestType type;
  final String title;
  final String description;
  final int xpReward;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime? resetAt;

  double get progressPercent => targetProgress > 0 ? (currentProgress / targetProgress * 100) : 0;
  
  bool get canClaim => isCompleted && !isClaimed;
}

enum DailyQuestType {
  checkin('Отметиться 1 раз'),
  checkin3('Отметиться 3 раза'),
  duelWin('Выиграть дуэль'),
  streak7('Серия 7 дней'),
  social('Дуэль с другом');

  const DailyQuestType(this.label);
  final String label;
}

/// Сезонный рейтинг.
class Season {
  const Season({
    required this.id,
    required this.number,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.userRank,
    this.userReward,
    this.isActive = false,
  });

  final String id;
  final int number;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int? userRank;
  final SeasonReward? userReward;
  final bool isActive;

  bool get isEnded => endDate.isBefore(DateTime.now());
  
  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 365);
}

class SeasonReward {
  const SeasonReward({
    required this.rank,
    required this.xp,
    required this.gems,
    this.badge,
    this.avatar,
  });

  final int rank;
  final int xp;
  final int gems;
  final String? badge;
  final String? avatar;
}

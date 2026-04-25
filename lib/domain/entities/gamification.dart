/// XP и уровни пользователя (Gamification 2.0).
class UserXp {
  const UserXp({
    required this.userId,
    this.totalXp = 0,
    this.level = 1,
    this.freezesAvailable = 0,
    this.weeklyXp = 0,
    this.updatedAt,
  });

  final String userId;
  final int totalXp;
  final int level;

  /// Количество доступных «заморозок» стрика.
  final int freezesAvailable;

  /// XP, заработанных за текущую неделю.
  final int weeklyXp;
  final DateTime? updatedAt;

  /// Формула уровня: каждые 200 XP = +1 уровень.
  static int levelFromXp(int xp) => (xp ~/ 200) + 1;

  /// XP до следующего уровня.
  int get xpToNextLevel => 200 - (totalXp % 200);

  /// Прогресс к следующему уровню (0.0 – 1.0).
  double get levelProgress => (totalXp % 200) / 200;

  /// Название уровня.
  String get levelTitle {
    return switch (level) {
      1 => 'Новичок',
      2 => 'Упорный',
      3 => 'Ветеран',
      4 => 'Легенда',
      >= 5 => 'Чемпион',
      _ => 'Новичок',
    };
  }
}

/// За что начисляется XP.
class XpEvent {
  const XpEvent({
    required this.eventType,
    required this.xpAmount,
    this.duelId,
    this.occurredAt,
  });

  final XpEventType eventType;
  final int xpAmount;
  final String? duelId;
  final DateTime? occurredAt;
}

enum XpEventType {
  checkin,       // +10 XP за каждый чекин
  streakBonus,   // +5 XP бонус за каждые 7 дней стрика
  duelWin,       // +50 XP за победу в дуэли
  groupTop3,     // +30 XP за топ-3 в группе
  firstDuel,     // +20 XP за первую дуэль
  trustedCheckin,// +5 XP бонус за автоматический чекин (Health)
  achievement,   // +25 XP за достижение
  quest,         // +15 XP за ежедневный квест
}

/// Заморозка стрика.
class StreakFreeze {
  const StreakFreeze({
    required this.id,
    required this.userId,
    required this.duelId,
    required this.usedAt,
  });

  final String id;
  final String userId;
  final String duelId;
  final DateTime usedAt;
}

/// Еженедельная AI-аналитика от «Коуча привычек».
class AiCoachMessage {
  const AiCoachMessage({
    required this.userId,
    required this.weekStartDate,
    required this.message,
    required this.checkinsThisWeek,
    required this.bestStreak,
    this.suggestion,
    this.generatedAt,
  });

  final String userId;
  final DateTime weekStartDate;
  final String message;
  final int checkinsThisWeek;
  final int bestStreak;

  /// Персональная рекомендация.
  final String? suggestion;
  final DateTime? generatedAt;
}

/// Паттерн чекинов пользователя (для Smart Reminders).
class CheckinPattern {
  const CheckinPattern({
    required this.userId,
    this.preferredHour = 9,
    this.preferredMinute = 0,
    this.averageCheckinHour = 9.0,
    this.totalCheckins = 0,
    this.lastUpdated,
  });

  final String userId;

  /// Оптимальный час для напоминания (0–23).
  final int preferredHour;
  final int preferredMinute;

  /// Среднее время чекина (дробное значение часа дня).
  final double averageCheckinHour;
  final int totalCheckins;
  final DateTime? lastUpdated;
}

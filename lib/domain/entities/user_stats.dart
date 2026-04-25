/// Статистика пользователя (Analytics).
class UserStats {
  const UserStats({
    required this.userId,
    this.totalCheckins = 0,
    this.totalDuels = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.bestStreak = 0,
    this.currentStreak = 0,
    this.averageCheckinHour = 9.0,
    this.favoriteHabitCategory,
    this.weeklyStats = const [],
    this.monthlyStats = const [],
    this.heatMapData = const {},
    this.headToHeadStats = const {},
  });

  final String userId;
  final int totalCheckins;
  final int totalDuels;
  final int totalWins;
  final int totalLosses;
  final int bestStreak;
  final int currentStreak;
  
  /// Среднее время чекина (0-23).
  final double averageCheckinHour;
  
  /// Любимая категория привычек.
  final String? favoriteHabitCategory;
  
  /// Статистика по неделям (последние 12 недель).
  final List<WeeklyStats> weeklyStats;
  
  /// Статистика по месяцам (последние 12 месяцев).
  final List<MonthlyStats> monthlyStats;
  
  /// Тепловая карта активности {date: checkinCount}.
  final Map<String, int> heatMapData;
  
  /// Статистика противостояний с соперниками.
  final Map<String, HeadToHeadStats> headToHeadStats;

  double get winRate => totalDuels > 0 ? (totalWins / totalDuels * 100) : 0;
  
  String get timeOfDayLabel {
    if (averageCheckinHour < 12) return '🌅 Утро';
    if (averageCheckinHour < 18) return '☀️ День';
    return '🌙 Вечер';
  }
}

class WeeklyStats {
  const WeeklyStats({
    required this.weekStart,
    this.checkins = 0,
    this.duelsPlayed = 0,
    this.duelsWon = 0,
    this.xpEarned = 0,
  });

  final DateTime weekStart;
  final int checkins;
  final int duelsPlayed;
  final int duelsWon;
  final int xpEarned;
}

class MonthlyStats {
  const MonthlyStats({
    required this.month,
    required this.year,
    this.checkins = 0,
    this.duelsPlayed = 0,
    this.duelsWon = 0,
    this.xpEarned = 0,
    this.newStreakRecord = false,
  });

  final int month;
  final int year;
  final int checkins;
  final int duelsPlayed;
  final int duelsWon;
  final int xpEarned;
  final bool newStreakRecord;
}

class HeadToHeadStats {
  const HeadToHeadStats({
    required this.opponentId,
    required this.opponentName,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalCheckins = 0,
    this.opponentTotalCheckins = 0,
  });

  final String opponentId;
  final String opponentName;
  final int wins;
  final int losses;
  final int draws;
  final int totalCheckins;
  final int opponentTotalCheckins;

  int get totalGames => wins + losses + draws;
  double get winRate => totalGames > 0 ? (wins / totalGames * 100) : 0;
}

/// Данные для графика активности.
class ActivityGraphData {
  const ActivityGraphData({
    required this.labels,
    required this.values,
    this.maxValue,
  });

  final List<String> labels;
  final List<int> values;
  final int? maxValue;

  int get max => maxValue ?? (values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0);
}

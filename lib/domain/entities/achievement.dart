/// Достижения пользователя (Achievements 2.0).
class Achievement {
  const Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0,
    this.requiredValue = 1,
    this.category = AchievementCategory.general,
    this.isSecret = false,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int requiredValue;
  final AchievementCategory category;
  final bool isSecret;

  /// Прогресс в процентах (0-100).
  int get progressPercent => ((progress / requiredValue) * 100).clamp(0, 100).toInt();

  /// Отображаемое описание (скрытое для секретных).
  String get displayDescription => isSecret && !isUnlocked ? '???' : description;

  /// Отображаемый иконка (размытая для секретных).
  String get displayIcon => isSecret && !isUnlocked ? '🔒' : icon;
}

enum AchievementCategory {
  general('Общие', Icons.star),
  streak('Серии', Icons.local_fire_department),
  duel('Дуэли', Icons.swords),
  social('Социальные', Icons.people),
  special('События', Icons.celebration);

  const AchievementCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Прогресс достижения для UI.
class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    this.currentValue = 0,
  });

  final Achievement achievement;
  final int currentValue;

  int get remaining => achievement.requiredValue - currentValue;
  bool get isComplete => currentValue >= achievement.requiredValue;
}

/// Дерево достижений (группировка).
class AchievementTree {
  const AchievementTree({
    required this.category,
    required this.achievements,
    this.parentCategory,
  });

  final AchievementCategory category;
  final List<Achievement> achievements;
  final AchievementCategory? parentCategory;

  int get totalXp => achievements.where((a) => a.isUnlocked).fold(0, (sum, a) => sum + a.xpReward);
  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;
  int get totalCount => achievements.length;
  double get completionPercent => totalCount > 0 ? (unlockedCount / totalCount * 100) : 0;
}

/// Магазин и кастомизация.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    this.currency = ShopCurrency.xp,
    this.isPurchased = false,
    this.isEquipped = false,
    this.isLimited = false,
    this.limitedUntil,
    this.requiredLevel = 1,
    this.category = ShopCategory.all,
  });

  final String id;
  final ShopItemType type;
  final String name;
  final String description;
  final String icon;
  final int price;
  final ShopCurrency currency;
  final bool isPurchased;
  final bool isEquipped;
  final bool isLimited;
  final DateTime? limitedUntil;
  final int requiredLevel;
  final ShopCategory category;

  bool get isAvailable => !isLimited || (limitedUntil != null && limitedUntil!.isAfter(DateTime.now()));
  bool get canAfford => currency == ShopCurrency.xp; // Упрощённая проверка
}

enum ShopItemType {
  avatar('Аватар'),
  theme('Тема'),
  booster('Бустер'),
  effect('Эффект');

  const ShopItemType(this.label);
  final String label;
}

enum ShopCurrency {
  xp('XP'),
  gems('Гемы'),
  coins('Монеты');

  const ShopCurrency(this.label);
  final String label;
}

enum ShopCategory {
  all('Все'),
  avatars('Аватары'),
  themes('Темы'),
  boosters('Бустеры'),
  effects('Эффекты');

  const ShopCategory(this.label);
  final String label;
}

/// Бустеры и временные улучшения.
class Booster {
  const Booster({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.durationMinutes,
    this.isActive = false,
    this.expiresAt,
  });

  final String id;
  final BoosterType type;
  final String name;
  final String description;
  final String icon;
  final int durationMinutes;
  final bool isActive;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  
  int get remainingMinutes {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inMinutes.clamp(0, durationMinutes);
  }
}

enum BoosterType {
  doubleXp('Двойной XP', '2x XP на 30 минут', '⚡'),
  freezeStreak('Заморозка серии', 'Сохраняет серию при пропуске', '🧊'),
  extraHeart('Дополнительная жизнь', '+1 попытка в дуэли', '❤️'),
  headStart('Фора', 'Начать дуэль с +3 серии', '🚀');

  const BoosterType(this.name, this.description, this.icon);
  final String name;
  final String description;
  final String icon;
}

/// Пользовательская валюта.
class UserCurrency {
  const UserCurrency({
    this.xp = 0,
    this.gems = 0,
    this.coins = 0,
  });

  final int xp;
  final int gems;
  final int coins;

  UserCurrency copyWith({int? xp, int? gems, int? coins}) {
    return UserCurrency(
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      coins: coins ?? this.coins,
    );
  }
}

/// Аватар пользователя.
class UserAvatar {
  const UserAvatar({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    this.isUnlocked = false,
    this.unlockedAt,
    this.source = AvatarSource.defaultAvatar,
  });

  final String id;
  final String name;
  final String icon;
  final int backgroundColor;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AvatarSource source;
}

enum AvatarSource {
  defaultAvatar,
  purchased,
  achievement,
  event,
}

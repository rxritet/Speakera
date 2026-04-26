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

  bool get isAvailable =>
      !isLimited || (limitedUntil != null && limitedUntil!.isAfter(DateTime.now()));

  ShopItem copyWith({
    String? id,
    ShopItemType? type,
    String? name,
    String? description,
    String? icon,
    int? price,
    ShopCurrency? currency,
    bool? isPurchased,
    bool? isEquipped,
    bool? isLimited,
    DateTime? limitedUntil,
    int? requiredLevel,
    ShopCategory? category,
  }) {
    return ShopItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isPurchased: isPurchased ?? this.isPurchased,
      isEquipped: isEquipped ?? this.isEquipped,
      isLimited: isLimited ?? this.isLimited,
      limitedUntil: limitedUntil ?? this.limitedUntil,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      category: category ?? this.category,
    );
  }
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
  xp('XP', '⚡'),
  gems('Гемы', '💎'),
  tenge('Тенге', '₸');

  const ShopCurrency(this.label, this.symbol);
  final String label;
  final String symbol;
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

  Booster copyWith({
    String? id,
    BoosterType? type,
    String? name,
    String? description,
    String? icon,
    int? durationMinutes,
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return Booster(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
    );
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

class UserCurrency {
  const UserCurrency({
    this.xp = 0,
    this.gems = 0,
    this.tenge = 0,
  });

  final int xp;
  final int gems;
  final int tenge;

  UserCurrency copyWith({int? xp, int? gems, int? tenge}) {
    return UserCurrency(
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      tenge: tenge ?? this.tenge,
    );
  }
}

class UserAvatar {
  const UserAvatar({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    this.isUnlocked = false,
    this.isEquipped = false,
    this.unlockedAt,
    this.source = AvatarSource.defaultAvatar,
  });

  final String id;
  final String name;
  final String icon;
  final int backgroundColor;
  final bool isUnlocked;
  final bool isEquipped;
  final DateTime? unlockedAt;
  final AvatarSource source;

  UserAvatar copyWith({
    String? id,
    String? name,
    String? icon,
    int? backgroundColor,
    bool? isUnlocked,
    bool? isEquipped,
    DateTime? unlockedAt,
    AvatarSource? source,
  }) {
    return UserAvatar(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      source: source ?? this.source,
    );
  }
}

enum AvatarSource {
  defaultAvatar,
  purchased,
  achievement,
  event,
}

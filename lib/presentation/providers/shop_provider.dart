import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/shop.dart';
import 'core_providers.dart';

sealed class ShopState {
  const ShopState();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopLoaded extends ShopState {
  const ShopLoaded({
    required this.items,
    required this.boosters,
    required this.currency,
    required this.avatars,
  });

  final List<ShopItem> items;
  final List<Booster> boosters;
  final UserCurrency currency;
  final List<UserAvatar> avatars;
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;
}

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier(this._store, this._storage) : super(const ShopLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;

  static const _purchasedItemsKey = 'demo_shop_purchased_items';
  static const _equippedItemKey = 'demo_shop_equipped_item';
  static const _activeBoosterIdsKey = 'demo_shop_active_boosters';
  static const _equippedAvatarIdKey = 'demo_shop_equipped_avatar';
  static const _currencyKey = 'demo_shop_currency';
  static const _userIdKey = 'user_id';

  Future<void> load() async {
    state = const ShopLoading();
    try {
      final userId = await _storage.read(key: _userIdKey);

      final remoteItems = userId == null ? null : await _store.readShopItems();
      final remoteBoosters = userId == null ? null : await _store.readUserBoosters(userId);
      final remoteCurrency = userId == null ? null : await _store.readUserCurrency(userId);
      final remoteAvatars = userId == null ? null : await _store.readUserAvatars(userId);

      state = ShopLoaded(
        items: await _applyItemState(
          remoteItems?.isNotEmpty == true ? remoteItems! : _demoItems,
        ),
        boosters: await _applyBoosterState(
          remoteBoosters?.isNotEmpty == true ? remoteBoosters! : _demoBoosters,
        ),
        currency: await _readCurrency(remoteCurrency),
        avatars: await _applyAvatarState(
          remoteAvatars?.isNotEmpty == true ? remoteAvatars! : _demoAvatars,
        ),
      );
    } catch (_) {
      state = ShopLoaded(
        items: await _applyItemState(_demoItems),
        boosters: await _applyBoosterState(_demoBoosters),
        currency: await _readCurrency(null),
        avatars: await _applyAvatarState(_demoAvatars),
      );
    }
  }

  Future<void> topUpBalance({required int amount}) async {
    final currentState = state;
    if (currentState is! ShopLoaded || amount <= 0) return;

    final userId = await _storage.read(key: _userIdKey);
    final newCurrency = currentState.currency.copyWith(
      tenge: currentState.currency.tenge + amount,
    );

    await _writeCurrency(newCurrency);
    if (userId != null && userId.isNotEmpty) {
      await _store.topUpTenge(userId: userId, amount: amount);
    }

    state = ShopLoaded(
      items: currentState.items,
      boosters: currentState.boosters,
      currency: newCurrency,
      avatars: currentState.avatars,
    );
  }

  Future<void> purchaseItem(String itemId) async {
    final currentState = state;
    if (currentState is! ShopLoaded) return;

    final item = currentState.items.firstWhere((candidate) => candidate.id == itemId);
    if (item.isPurchased) return;

    final balanceError = _validateBalance(currentState.currency, item);
    if (balanceError != null) {
      state = ShopError(balanceError);
      state = currentState;
      return;
    }

    final userId = await _storage.read(key: _userIdKey);
    final purchasedIds = await _readIdSet(_purchasedItemsKey)..add(itemId);
    final newCurrency = _spendCurrency(currentState.currency, item);

    await _writeIdSet(_purchasedItemsKey, purchasedIds);
    await _writeCurrency(newCurrency);

    if (userId != null && userId.isNotEmpty) {
      await _syncRemotePurchase(userId: userId, item: item);
    }

    state = ShopLoaded(
      items: currentState.items
          .map((candidate) {
            if (candidate.id != itemId) return candidate;
            return candidate.copyWith(isPurchased: true);
          })
          .toList(growable: false),
      boosters: currentState.boosters,
      currency: newCurrency,
      avatars: currentState.avatars,
    );
  }

  Future<void> equipItem(String itemId) async {
    final currentState = state;
    if (currentState is! ShopLoaded) return;

    await _storage.write(key: _equippedItemKey, value: itemId);
    state = ShopLoaded(
      items: currentState.items
          .map((item) => item.copyWith(isEquipped: item.id == itemId))
          .toList(growable: false),
      boosters: currentState.boosters,
      currency: currentState.currency,
      avatars: currentState.avatars,
    );
  }

  Future<void> activateBooster(String boosterId) async {
    final currentState = state;
    if (currentState is! ShopLoaded) return;

    final activeIds = await _readIdSet(_activeBoosterIdsKey)..add(boosterId);
    await _writeIdSet(_activeBoosterIdsKey, activeIds);

    state = ShopLoaded(
      items: currentState.items
          .map((item) => item.id == boosterId ? item.copyWith(isEquipped: true) : item)
          .toList(growable: false),
      boosters: currentState.boosters.map((booster) {
        if (booster.id != boosterId) return booster;
        return booster.copyWith(
          isActive: true,
          expiresAt: DateTime.now().add(Duration(minutes: booster.durationMinutes)),
        );
      }).toList(growable: false),
      currency: currentState.currency,
      avatars: currentState.avatars,
    );
  }

  Future<void> equipAvatar(String avatarId) async {
    final currentState = state;
    if (currentState is! ShopLoaded) return;

    await _storage.write(key: _equippedAvatarIdKey, value: avatarId);
    state = ShopLoaded(
      items: currentState.items,
      boosters: currentState.boosters,
      currency: currentState.currency,
      avatars: currentState.avatars
          .map((avatar) => avatar.copyWith(isEquipped: avatar.id == avatarId))
          .toList(growable: false),
    );
  }

  String? _validateBalance(UserCurrency currency, ShopItem item) {
    return switch (item.currency) {
      ShopCurrency.xp when currency.xp < item.price => 'Недостаточно XP для покупки',
      ShopCurrency.gems when currency.gems < item.price => 'Недостаточно гемов для покупки',
      ShopCurrency.tenge when currency.tenge < item.price => 'Недостаточно тенге на балансе',
      _ => null,
    };
  }

  UserCurrency _spendCurrency(UserCurrency currency, ShopItem item) {
    return switch (item.currency) {
      ShopCurrency.xp => currency.copyWith(xp: currency.xp - item.price),
      ShopCurrency.gems => currency.copyWith(gems: currency.gems - item.price),
      ShopCurrency.tenge => currency.copyWith(tenge: currency.tenge - item.price),
    };
  }

  Future<void> _syncRemotePurchase({
    required String userId,
    required ShopItem item,
  }) async {
    await _store.purchaseItem(userId: userId, itemId: item.id);
    switch (item.currency) {
      case ShopCurrency.xp:
        await _store.spendXp(userId: userId, amount: item.price);
        break;
      case ShopCurrency.gems:
        break;
      case ShopCurrency.tenge:
        await _store.spendTenge(userId: userId, amount: item.price);
        break;
    }
  }

  Future<List<ShopItem>> _applyItemState(List<ShopItem> items) async {
    final purchasedIds = await _readIdSet(_purchasedItemsKey);
    final equippedItemId = await _storage.read(key: _equippedItemKey);
    final activeBoosterIds = await _readIdSet(_activeBoosterIdsKey);
    return items.map((item) {
      final isPurchased = item.isPurchased || purchasedIds.contains(item.id);
      return item.copyWith(
        isPurchased: isPurchased,
        isEquipped: equippedItemId == item.id || activeBoosterIds.contains(item.id),
      );
    }).toList(growable: false);
  }

  Future<List<Booster>> _applyBoosterState(List<Booster> boosters) async {
    final activeIds = await _readIdSet(_activeBoosterIdsKey);
    return boosters.map((booster) {
      if (!activeIds.contains(booster.id)) return booster;
      final expiresAt =
          booster.expiresAt ?? DateTime.now().add(Duration(minutes: booster.durationMinutes));
      return booster.copyWith(
        isActive: expiresAt.isAfter(DateTime.now()),
        expiresAt: expiresAt,
      );
    }).toList(growable: false);
  }

  Future<List<UserAvatar>> _applyAvatarState(List<UserAvatar> avatars) async {
    final equippedAvatarId = await _storage.read(key: _equippedAvatarIdKey);
    return avatars
        .map((avatar) => avatar.copyWith(isEquipped: avatar.id == equippedAvatarId))
        .toList(growable: false);
  }

  Future<UserCurrency> _readCurrency(UserCurrency? remote) async {
    final raw = await _storage.read(key: _currencyKey);
    if (raw == null || raw.isEmpty) {
      final base = remote ?? const UserCurrency(xp: 1350, gems: 45, tenge: 15000);
      await _writeCurrency(base);
      return base;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return UserCurrency(
      xp: data['xp'] as int? ?? remote?.xp ?? 0,
      gems: data['gems'] as int? ?? remote?.gems ?? 0,
      tenge: data['tenge'] as int? ?? data['coins'] as int? ?? remote?.tenge ?? 0,
    );
  }

  Future<void> _writeCurrency(UserCurrency currency) async {
    await _storage.write(
      key: _currencyKey,
      value: jsonEncode({
        'xp': currency.xp,
        'gems': currency.gems,
        'tenge': currency.tenge,
      }),
    );
  }

  Future<Set<String>> _readIdSet(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw
        .split(',')
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim())
        .toSet();
  }

  Future<void> _writeIdSet(String key, Set<String> values) async {
    await _storage.write(key: key, value: values.join(','));
  }

  List<ShopItem> get _demoItems => [
        const ShopItem(
          id: 'avatar_neon_fox',
          type: ShopItemType.avatar,
          name: 'Neon Fox',
          description: 'Яркий аватар для тех, кто любит побеждать красиво.',
          icon: '🦊',
          price: 180,
          currency: ShopCurrency.tenge,
          category: ShopCategory.avatars,
        ),
        const ShopItem(
          id: 'theme_sunrise',
          type: ShopItemType.theme,
          name: 'Sunrise Arena',
          description: 'Тёплая тема с атмосферой арены на рассвете.',
          icon: '🌅',
          price: 320,
          currency: ShopCurrency.tenge,
          category: ShopCategory.themes,
        ),
        const ShopItem(
          id: 'theme_cybermint',
          type: ShopItemType.theme,
          name: 'Cyber Mint',
          description: 'Свежая неоновая тема для вечерних дуэлей.',
          icon: '💠',
          price: 420,
          currency: ShopCurrency.tenge,
          category: ShopCategory.themes,
        ),
        const ShopItem(
          id: 'booster_double_xp',
          type: ShopItemType.booster,
          name: 'Double XP',
          description: 'Удваивает награду за активность на 30 минут.',
          icon: '⚡',
          price: 150,
          currency: ShopCurrency.xp,
          category: ShopCategory.boosters,
        ),
        const ShopItem(
          id: 'booster_freeze',
          type: ShopItemType.booster,
          name: 'Streak Shield',
          description: 'Сохраняет серию при одном пропуске.',
          icon: '🧊',
          price: 240,
          currency: ShopCurrency.xp,
          category: ShopCategory.boosters,
        ),
        ShopItem(
          id: 'effect_confetti',
          type: ShopItemType.effect,
          name: 'Victory Confetti',
          description: 'Конфетти после победы в денежной дуэли.',
          icon: '🎉',
          price: 260,
          currency: ShopCurrency.tenge,
          category: ShopCategory.effects,
          isLimited: true,
          limitedUntil: DateTime.now().add(const Duration(days: 14)),
        ),
        const ShopItem(
          id: 'effect_fire_trail',
          type: ShopItemType.effect,
          name: 'Fire Trail',
          description: 'Огненный след для чемпионских серий.',
          icon: '🔥',
          price: 300,
          currency: ShopCurrency.tenge,
          category: ShopCategory.effects,
        ),
      ];

  List<Booster> get _demoBoosters => const [
        Booster(
          id: 'booster_double_xp',
          type: BoosterType.doubleXp,
          name: 'Double XP',
          description: 'Ускоряет прокачку на 30 минут.',
          icon: '⚡',
          durationMinutes: 30,
        ),
        Booster(
          id: 'booster_freeze',
          type: BoosterType.freezeStreak,
          name: 'Streak Shield',
          description: 'Сохраняет серию при одном пропуске.',
          icon: '🧊',
          durationMinutes: 1440,
        ),
      ];

  List<UserAvatar> get _demoAvatars => const [
        UserAvatar(
          id: 'avatar_default_blaze',
          name: 'Blaze',
          icon: '🔥',
          backgroundColor: 0xFFEA580C,
          isUnlocked: true,
        ),
        UserAvatar(
          id: 'avatar_default_wave',
          name: 'Wave',
          icon: '🌊',
          backgroundColor: 0xFF0F766E,
          isUnlocked: true,
        ),
        UserAvatar(
          id: 'avatar_owl',
          name: 'Night Owl',
          icon: '🦉',
          backgroundColor: 0xFF4338CA,
          isUnlocked: true,
          source: AvatarSource.purchased,
        ),
      ];
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

final shopCategoryFilterProvider = StateProvider<ShopCategory>((_) => ShopCategory.all);

final filteredShopItemsProvider = Provider<List<ShopItem>>((ref) {
  final state = ref.watch(shopProvider);
  final category = ref.watch(shopCategoryFilterProvider);

  if (state is! ShopLoaded) return [];
  if (category == ShopCategory.all) return state.items;

  return state.items.where((item) {
    return switch (category) {
      ShopCategory.avatars => item.type == ShopItemType.avatar,
      ShopCategory.themes => item.type == ShopItemType.theme,
      ShopCategory.boosters => item.type == ShopItemType.booster,
      ShopCategory.effects => item.type == ShopItemType.effect,
      ShopCategory.all => true,
    };
  }).toList(growable: false);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/shop.dart';
import 'core_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────

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

  List<ShopItem> get purchasedItems => items.where((i) => i.isPurchased).toList();
  List<ShopItem> get availableItems => items.where((i) => !i.isPurchased && i.isAvailable).toList();
}

class ShopError extends ShopState {
  const ShopError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier(this._store, this._storage) : super(const ShopLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    state = const ShopLoading();
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null || userId.isEmpty) {
        state = const ShopLoaded(
          items: [],
          boosters: [],
          currency: UserCurrency(),
          avatars: [],
        );
        return;
      }

      final items = await _store.readShopItems();
      final boosters = await _store.readUserBoosters(userId);
      final currency = await _store.readUserCurrency(userId);
      final avatars = await _store.readUserAvatars(userId);

      state = ShopLoaded(
        items: items ?? [],
        boosters: boosters ?? [],
        currency: currency ?? const UserCurrency(),
        avatars: avatars ?? [],
      );
    } catch (e) {
      state = ShopError(e.toString());
    }
  }

  Future<void> purchaseItem(String itemId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    final currentState = state;
    if (currentState is! ShopLoaded) return;

    final item = currentState.items.firstWhere((i) => i.id == itemId);
    
    // Проверка достаточности средств
    if (item.currency == ShopCurrency.xp && currentState.currency.xp < item.price) {
      state = const ShopError('Недостаточно XP');
      return;
    }

    try {
      await _store.purchaseItem(userId: userId, itemId: itemId);
      
      // Списание средств
      if (item.currency == ShopCurrency.xp) {
        await _store.spendXp(userId: userId, amount: item.price);
      }

      await load();
    } catch (e) {
      state = ShopError(e.toString());
    }
  }

  Future<void> equipItem(String itemId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.equipItem(userId: userId, itemId: itemId);
      await load();
    } catch (e) {
      state = ShopError(e.toString());
    }
  }

  Future<void> activateBooster(String boosterId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.activateBooster(userId: userId, boosterId: boosterId);
      await load();
    } catch (e) {
      state = ShopError(e.toString());
    }
  }

  Future<void> equipAvatar(String avatarId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.equipAvatar(userId: userId, avatarId: avatarId);
      await load();
    } catch (e) {
      state = ShopError(e.toString());
    }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

// ─── Filter Provider ───────────────────────────────────────────────────────

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
  }).toList();
});

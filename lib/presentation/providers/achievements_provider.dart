import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/gamification.dart';
import 'core_providers.dart';
import 'gamification_provider.dart';

// ─── State ─────────────────────────────────────────────────────────────────

sealed class AchievementsState {
  const AchievementsState();
}

class AchievementsLoading extends AchievementsState {
  const AchievementsLoading();
}

class AchievementsLoaded extends AchievementsState {
  const AchievementsLoaded({
    required this.achievements,
    required this.trees,
  });
  final List<Achievement> achievements;
  final List<AchievementTree> trees;

  int get totalUnlocked => achievements.where((a) => a.isUnlocked).length;
  int get totalCount => achievements.length;
  double get completionPercent => totalCount > 0 ? (totalUnlocked / totalCount * 100) : 0;
}

class AchievementsError extends AchievementsState {
  const AchievementsError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier(this._store, this._storage, this._xpNotifier)
      : super(const AchievementsLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;
  final UserXpNotifier _xpNotifier;

  Future<void> load() async {
    state = const AchievementsLoading();
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null || userId.isEmpty) {
        state = const AchievementsLoaded(achievements: [], trees: []);
        return;
      }

      final achievements = await _store.readAchievements(userId);
      final trees = _buildAchievementTrees(achievements);
      state = AchievementsLoaded(achievements: achievements, trees: trees);
    } catch (e) {
      state = AchievementsError(e.toString());
    }
  }

  List<AchievementTree> _buildAchievementTrees(List<Achievement> achievements) {
    final categories = AchievementCategory.values;
    return categories.map((category) {
      final categoryAchievements = achievements.where((a) => a.category == category).toList();
      return AchievementTree(
        category: category,
        achievements: categoryAchievements,
      );
    }).toList();
  }

  Future<void> claimAchievement(String achievementId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.claimAchievement(userId: userId, achievementId: achievementId);
      await load();
      // Начислить XP
      final achievement = (state as AchievementsLoaded?)
          ?.achievements
          .firstWhere((a) => a.id == achievementId);
      if (achievement != null && achievement.isUnlocked) {
        await _xpNotifier.addXp(XpEventType.achievement, duelId: achievementId);
      }
    } catch (e) {
      state = AchievementsError(e.toString());
    }
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
    ref.read(userXpProvider.notifier),
  );
});

// ─── Filter Provider ───────────────────────────────────────────────────────

enum AchievementFilter { all, unlocked, locked, byCategory }

final achievementFilterProvider = StateProvider<AchievementFilter>((_) => AchievementFilter.all);

final achievementCategoryFilterProvider = StateProvider<AchievementCategory?>((_) => null);

final filteredAchievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementsProvider);
  final filter = ref.watch(achievementFilterProvider);
  final categoryFilter = ref.watch(achievementCategoryFilterProvider);

  if (state is! AchievementsLoaded) return [];

  var achievements = state.achievements;

  if (categoryFilter != null) {
    achievements = achievements.where((a) => a.category == categoryFilter).toList();
  }

  return switch (filter) {
    AchievementFilter.all => achievements,
    AchievementFilter.unlocked => achievements.where((a) => a.isUnlocked).toList(),
    AchievementFilter.locked => achievements.where((a) => !a.isUnlocked).toList(),
    AchievementFilter.byCategory => achievements,
  };
});

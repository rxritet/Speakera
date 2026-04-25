import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/user_stats.dart';
import 'core_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────

sealed class StatsState {
  const StatsState();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  const StatsLoaded({required this.stats});
  final UserStats stats;
}

class StatsError extends StatsState {
  const StatsError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._store, this._storage) : super(const StatsLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    state = const StatsLoading();
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null || userId.isEmpty) {
        state = StatsLoaded(stats: UserStats(userId: ''));
        return;
      }

      final stats = await _store.readUserStats(userId);
      state = StatsLoaded(stats: stats ?? UserStats(userId: userId));
    } catch (e) {
      state = StatsError(e.toString());
    }
  }

  Future<void> refresh() async {
    await load();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

// ─── Derived Providers ─────────────────────────────────────────────────────

final activityGraphProvider = Provider<ActivityGraphData?>((ref) {
  final state = ref.watch(statsProvider);
  if (state is! StatsLoaded) return null;

  final weeklyStats = state.stats.weeklyStats;
  if (weeklyStats.isEmpty) return null;

  return ActivityGraphData(
    labels: weeklyStats.map((w) => 'Нед ${weeklyStats.indexOf(w) + 1}').toList(),
    values: weeklyStats.map((w) => w.checkins).toList(),
  );
});

final heatMapProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(statsProvider);
  if (state is! StatsLoaded) return {};
  return state.stats.heatMapData;
});

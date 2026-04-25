import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/event.dart';
import 'core_providers.dart';
import 'gamification_provider.dart';

// ─── State ─────────────────────────────────────────────────────────────────

sealed class EventsState {
  const EventsState();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  const EventsLoaded({
    required this.events,
    required this.dailyQuests,
    required this.currentSeason,
  });
  final List<GameEvent> events;
  final List<DailyQuest> dailyQuests;
  final Season? currentSeason;

  List<GameEvent> get activeEvents => events.where((e) => e.isActive).toList();
  List<GameEvent> get upcomingEvents => events.where((e) => e.isUpcoming).toList();
}

class EventsError extends EventsState {
  const EventsError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier(this._store, this._storage, this._xpNotifier)
      : super(const EventsLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;
  final UserXpNotifier _xpNotifier;

  Future<void> load() async {
    state = const EventsLoading();
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null || userId.isEmpty) {
        state = const EventsLoaded(
          events: [],
          dailyQuests: [],
          currentSeason: null,
        );
        return;
      }

      final events = await _store.readActiveEvents();
      final dailyQuests = await _store.readDailyQuests(userId);
      final season = await _store.readCurrentSeason();

      state = EventsLoaded(
        events: events ?? [],
        dailyQuests: dailyQuests ?? [],
        currentSeason: season,
      );
    } catch (e) {
      state = EventsError(e.toString());
    }
  }

  Future<void> claimQuestReward(String questId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      final quest = (state as EventsLoaded?)?.dailyQuests.firstWhere((q) => q.id == questId);
      if (quest == null || !quest.canClaim) return;

      await _store.claimQuestReward(userId: userId, questId: questId);
      await _xpNotifier.addXp(XpEventType.quest, duelId: questId);
      await load();
    } catch (e) {
      state = EventsError(e.toString());
    }
  }

  Future<void> claimEventReward(String eventId, String rewardId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.claimEventReward(userId: userId, eventId: eventId, rewardId: rewardId);
      await load();
    } catch (e) {
      state = EventsError(e.toString());
    }
  }

  Future<void> joinEvent(String eventId) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.joinEvent(userId: userId, eventId: eventId);
      await load();
    } catch (e) {
      state = EventsError(e.toString());
    }
  }

  Future<void> updateQuestProgress(DailyQuestType type, int amount) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await _store.updateQuestProgress(userId: userId, type: type, amount: amount);
      await load();
    } catch (e) {
      state = EventsError(e.toString());
    }
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
    ref.read(userXpProvider.notifier),
  );
});

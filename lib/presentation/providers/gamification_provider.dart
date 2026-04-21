import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/ai/ai_coach_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/gamification.dart';
import 'core_providers.dart';

// ─── State ─────────────────────────────────────────────────────────────────

sealed class XpState {
  const XpState();
}

class XpLoading extends XpState {
  const XpLoading();
}

class XpLoaded extends XpState {
  const XpLoaded({required this.xp, this.coachMessage});
  final UserXp xp;
  final AiCoachMessage? coachMessage;
}

class XpError extends XpState {
  const XpError(this.message);
  final String message;
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class UserXpNotifier extends StateNotifier<XpState> {
  UserXpNotifier(this._store, this._storage) : super(const XpLoading());

  final HabitDuelFirestoreStore _store;
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    state = const XpLoading();
    try {
      final userId = await _storage.read(key: kUserIdKey);
      if (userId == null || userId.isEmpty) {
        state = XpLoaded(xp: UserXp(userId: ''));
        return;
      }
      final xp = await _store.readUserXp(userId);
      final coach = await _store.readLatestCoachMessage(userId);

      // Генерируем новое сообщение коуча если нет за эту неделю
      AiCoachMessage? coachMessage = coach;
      if (coach == null) {
        coachMessage = AiCoachService.instance.generateWeeklyMessage(
          userId: userId,
          checkinsThisWeek: 0,
          bestStreak: xp?.totalXp ?? 0 > 0 ? (xp!.totalXp ~/ 10) : 0,
          totalDuels: 0,
          wins: 0,
          losses: 0,
          xpThisWeek: xp?.weeklyXp ?? 0,
        );
        await _store.saveCoachMessage(coachMessage);
      }

      state = XpLoaded(
        xp: xp ?? UserXp(userId: userId),
        coachMessage: coachMessage,
      );
    } catch (e) {
      state = XpError(e.toString());
    }
  }

  Future<void> addXp(XpEventType eventType, {String? duelId}) async {
    final userId = await _storage.read(key: kUserIdKey);
    if (userId == null || userId.isEmpty) return;
    await _store.addXp(userId: userId, eventType: eventType, duelId: duelId);
    await load(); // обновляем UI
  }

  Future<bool> useFreeze(String duelId) async {
    final userId = await _storage.read(key: kUserIdKey);
    if (userId == null || userId.isEmpty) return false;
    final result = await _store.useStreakFreeze(userId: userId, duelId: duelId);
    if (result) await load();
    return result;
  }
}

final userXpProvider = StateNotifierProvider<UserXpNotifier, XpState>((ref) {
  return UserXpNotifier(
    ref.watch(firestoreStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

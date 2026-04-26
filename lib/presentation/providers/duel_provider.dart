import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/duel.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

// ─── Состояние списка дуэлей ───────────────────────────────────────────

sealed class DuelsListState {
  const DuelsListState();
}

class DuelsListInitial extends DuelsListState {
  const DuelsListInitial();
}

class DuelsListLoading extends DuelsListState {
  const DuelsListLoading();
}

class DuelsListLoaded extends DuelsListState {
  const DuelsListLoaded(this.duels);
  final List<Duel> duels;
}

class DuelsListError extends DuelsListState {
  const DuelsListError(this.message);
  final String message;
}

// ─── Обработчик списка дуэлей ──────────────────────────────────────────

class DuelsListNotifier extends StateNotifier<DuelsListState> {
  DuelsListNotifier(this._ref) : super(const DuelsListInitial());
  final Ref _ref;
  StreamSubscription<List<Duel>>? _myDuelsSub;
  StreamSubscription<List<Duel>>? _openGroupSub;

  List<Duel> _myDuels = [];
  List<Duel> _openGroups = [];
  bool _myDuelsLoaded = false;
  bool _openGroupsLoaded = false;

  void load() {
    state = const DuelsListLoading();
    _myDuelsSub?.cancel();
    _openGroupSub?.cancel();
    _myDuelsLoaded = false;
    _openGroupsLoaded = false;
    _myDuels = [];
    _openGroups = [];

    final authState = _ref.read(authProvider);
    if (authState is Authenticated) {
      final repo = _ref.read(duelRepositoryProvider);
      
      _myDuelsSub = repo.watchMyDuels(authState.user.id).listen((duels) {
        _myDuels = duels;
        _myDuelsLoaded = true;
        _emitCombined();
      }, onError: (e) {
        state = DuelsListError(e.toString());
      });

      _openGroupSub = repo.watchOpenGroupDuels().listen((duels) {
        _openGroups = duels;
        _openGroupsLoaded = true;
        _emitCombined();
      }, onError: (e) {
        state = DuelsListError(e.toString());
      });
    } else {
      state = const DuelsListError('User is not authenticated');
    }
  }

  void _emitCombined() {
    // Only emit when both streams have emitted at least once to avoid brief jumps.
    if (!_myDuelsLoaded || !_openGroupsLoaded) return;
    
    final Map<String, Duel> mergedMap = {};
    for (final d in _openGroups) {
      mergedMap[d.id] = d;
    }
    // _myDuels overrides _openGroups so that if you join an open group, 
    // it will be correctly rendered based on user's participant state.
    for (final d in _myDuels) {
      mergedMap[d.id] = d;
    }
    
    final mergedList = mergedMap.values.toList();
    mergedList.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    state = DuelsListLoaded(mergedList);
  }

  @override
  void dispose() {
    _myDuelsSub?.cancel();
    _openGroupSub?.cancel();
    super.dispose();
  }
}

final duelsListProvider =
    StateNotifierProvider<DuelsListNotifier, DuelsListState>((ref) {
  return DuelsListNotifier(ref);
});

// ─── Состояние деталей дуэли ───────────────────────────────────────────

sealed class DuelDetailState {
  const DuelDetailState();
}

class DuelDetailLoading extends DuelDetailState {
  const DuelDetailLoading();
}

class DuelDetailLoaded extends DuelDetailState {
  const DuelDetailLoaded(this.duel);
  final Duel duel;
}

class DuelDetailError extends DuelDetailState {
  const DuelDetailError(this.message);
  final String message;
}

// ─── Обработчик деталей дуэли ──────────────────────────────────────────

class DuelDetailNotifier extends StateNotifier<DuelDetailState> {
  DuelDetailNotifier(this._ref) : super(const DuelDetailLoading());
  final Ref _ref;
  StreamSubscription? _sub;

  void load(String duelId) {
    state = const DuelDetailLoading();
    _sub?.cancel();

    try {
      final repo = _ref.read(duelRepositoryProvider);
      _sub = repo.watchDuel(duelId).listen(
        (duel) {
          if (duel != null) {
            state = DuelDetailLoaded(duel);
          } else {
            state = const DuelDetailError('Duel not found');
          }
        },
        onError: (e) {
          state = DuelDetailError(e.toString());
        },
      );
    } catch (e) {
      state = DuelDetailError(e.toString());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> checkIn(String duelId, {String? note}) async {
    try {
      await _ref.read(checkInUseCaseProvider).call(duelId, note: note);
      // Stream automatically updates the UI
      return true;
    } on Failure {
      return false;
    }
  }

  Future<bool> accept(String duelId) async {
    try {
      await _ref.read(acceptDuelUseCaseProvider).call(duelId);
      // Stream automatically updates the UI
      return true;
    } on Failure {
      return false;
    }
  }

  Future<bool> join(String duelId) async {
    try {
      await _ref.read(duelRepositoryProvider).joinOpenDuel(duelId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final duelDetailProvider =
    StateNotifierProvider<DuelDetailNotifier, DuelDetailState>((ref) {
  return DuelDetailNotifier(ref);
});

// ─── Состояние создания дуэли ──────────────────────────────────────────

sealed class CreateDuelState {
  const CreateDuelState();
}

class CreateDuelInitial extends CreateDuelState {
  const CreateDuelInitial();
}

class CreateDuelLoading extends CreateDuelState {
  const CreateDuelLoading();
}

class CreateDuelSuccess extends CreateDuelState {
  const CreateDuelSuccess(this.duel);
  final Duel duel;
}

class CreateDuelError extends CreateDuelState {
  const CreateDuelError(this.message);
  final String message;
}

class CreateDuelNotifier extends StateNotifier<CreateDuelState> {
  CreateDuelNotifier(this._ref) : super(const CreateDuelInitial());
  final Ref _ref;

  Future<void> create({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
    DuelType type = DuelType.duel,
    int maxParticipants = 2,
    String? habitCategory,
    bool isTrustedCheckin = false,
    String? healthMetric,
    double? healthTargetValue,
    int entryFee = 0,
    DuelCurrency currency = DuelCurrency.tenge,
  }) async {
    state = const CreateDuelLoading();
    try {
      final duel = await _ref.read(createDuelUseCaseProvider).call(
            habitName: habitName,
            description: description,
            durationDays: durationDays,
            opponentUsername: opponentUsername,
            type: type,
            maxParticipants: maxParticipants,
            habitCategory: habitCategory,
            isTrustedCheckin: isTrustedCheckin,
            healthMetric: healthMetric,
            healthTargetValue: healthTargetValue,
            entryFee: entryFee,
            currency: currency,
          );
      state = CreateDuelSuccess(duel);
    } on Failure catch (e) {
      state = CreateDuelError(e.message);
    } catch (e) {
      state = CreateDuelError(e.toString());
    }
  }

  void reset() => state = const CreateDuelInitial();
}

final createDuelProvider =
    StateNotifierProvider<CreateDuelNotifier, CreateDuelState>((ref) {
  return CreateDuelNotifier(ref);
});

// ─── Join by Invite Code ───────────────────────────────────────────────

sealed class JoinDuelState {
  const JoinDuelState();
}

class JoinDuelInitial extends JoinDuelState {
  const JoinDuelInitial();
}

class JoinDuelLoading extends JoinDuelState {
  const JoinDuelLoading();
}

class JoinDuelSuccess extends JoinDuelState {
  const JoinDuelSuccess(this.duel);
  final Duel duel;
}

class JoinDuelError extends JoinDuelState {
  const JoinDuelError(this.message);
  final String message;
}

class JoinDuelNotifier extends StateNotifier<JoinDuelState> {
  JoinDuelNotifier(this._ref) : super(const JoinDuelInitial());
  final Ref _ref;

  Future<void> joinByInviteCode(String inviteCode) async {
    state = const JoinDuelLoading();
    try {
      final repo = _ref.read(duelRepositoryProvider);
      final duel = await repo.joinGroupByInviteCode(inviteCode.trim().toUpperCase());
      if (duel == null) {
        state = const JoinDuelError('Код не найден или лобби уже заполнено');
      } else {
        state = JoinDuelSuccess(duel);
      }
    } catch (e) {
      state = JoinDuelError(e.toString());
    }
  }

  void reset() => state = const JoinDuelInitial();
}

final joinDuelProvider =
    StateNotifierProvider<JoinDuelNotifier, JoinDuelState>((ref) {
  return JoinDuelNotifier(ref);
});

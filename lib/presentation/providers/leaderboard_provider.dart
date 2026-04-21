import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import 'core_providers.dart';

// ─── Состояние ─────────────────────────────────────────────────────────

sealed class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded(this.entries, {this.total = 0});
  final List<LeaderboardEntry> entries;
  final int total;
}

class LeaderboardError extends LeaderboardState {
  const LeaderboardError(this.message);
  final String message;
}

// ─── Обработчик ────────────────────────────────────────────────────────

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier(this._ref) : super(const LeaderboardInitial());
  final Ref _ref;
  StreamSubscription? _sub;

  void load({int limit = 50, int offset = 0}) {
    state = const LeaderboardLoading();
    _sub?.cancel();

    _sub = _ref
        .read(leaderboardRemoteDSProvider)
        .watchLeaderboard(limit: limit, offset: offset)
        .listen(
      (result) {
        state = LeaderboardLoaded(result.entries, total: result.total);
      },
      onError: (e) {
        state = LeaderboardError(e.toString());
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

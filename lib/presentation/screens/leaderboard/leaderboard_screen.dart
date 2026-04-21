import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/leaderboard_entry.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(leaderboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final body = switch (state) {
      LeaderboardInitial() || LeaderboardLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      LeaderboardError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(leaderboardProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      LeaderboardLoaded(:final entries) => RefreshIndicator(
          onRefresh: () async => ref.read(leaderboardProvider.notifier).load(),
          child: entries.isEmpty
              ? const Center(child: Text('No users yet'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _AnimatedLeaderboardTile(entry: entries[index], index: index),
                ),
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(state.runtimeType),
          child: body,
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.index});
  final LeaderboardEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = entry.rank <= 3;

    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isTop3 ? theme.colorScheme.primaryContainer : null,
        child: Text(
          medal,
          style: TextStyle(fontSize: isTop3 ? 20 : 14),
        ),
      ),
      title: Text(
        entry.username,
        style: isTop3
            ? theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: Text('${entry.wins}W / ${entry.losses}L'),
      trailing: Text(
        '${entry.wins} wins',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AnimatedLeaderboardTile extends StatelessWidget {
  const _AnimatedLeaderboardTile({required this.entry, required this.index});

  final LeaderboardEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: _LeaderboardTile(entry: entry, index: index),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/duel_provider.dart';
import '../../../domain/entities/duel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(duelsListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelsListProvider);
    final body = switch (state) {
      DuelsListInitial() || DuelsListLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      DuelsListError(:final message) => _ErrorBody(
          message: message,
          onRetry: () => ref.read(duelsListProvider.notifier).load(),
        ),
      DuelsListLoaded(:final duels) => duels.isEmpty
          ? const _EmptyBody()
          : RefreshIndicator(
              onRefresh: () async => ref.read(duelsListProvider.notifier).load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: duels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _AnimatedDuelCard(
                  duel: duels[index],
                  index: index,
                ),
              ),
            ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitDuel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(state.runtimeType),
          child: body,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-duel'),
        icon: const Icon(Icons.add),
        label: const Text('New Duel'),
      ),
    );
  }
}

// ─── Duel card ──────────────────────────────────────────────────────────

class _DuelCard extends StatelessWidget {
  const _DuelCard({required this.duel});
  final Duel duel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = duel.status == 'pending';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/duel', arguments: duel.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      duel.habitName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: duel.status),
                ],
              ),
              const SizedBox(height: 12),
              if (!isPending)
                Row(
                  children: [
                    _StreakIndicator(
                      label: 'You',
                      streak: duel.myStreak,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 24),
                    _StreakIndicator(
                      label: 'Opponent',
                      streak: duel.opponentStreak,
                      color: theme.colorScheme.secondary,
                    ),
                    const Spacer(),
                    Text(
                      '${duel.durationDays} days',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                )
              else
                Text(
                  'Waiting for opponent…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDuelCard extends StatelessWidget {
  const _AnimatedDuelCard({required this.duel, required this.index});

  final Duel duel;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 35)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: _DuelCard(duel: duel),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', Colors.green),
      'pending' => ('Pending', Colors.orange),
      'completed' => ('Done', Colors.blue),
      'cancelled' => ('Cancelled', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StreakIndicator extends StatelessWidget {
  const _StreakIndicator({
    required this.label,
    required this.streak,
    required this.color,
  });
  final String label;
  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$streak 🔥',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── Empty / Error helpers ──────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'No duels yet.\nTap "New Duel" to challenge a friend!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

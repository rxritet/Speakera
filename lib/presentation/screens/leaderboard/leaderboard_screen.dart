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
                onPressed: () => ref.read(leaderboardProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      LeaderboardLoaded(:final entries) => RefreshIndicator(
          onRefresh: () async => ref.read(leaderboardProvider.notifier).load(),
          child: entries.isEmpty
              ? const Center(child: Text('Игроки пока не появились'))
              : _LeaderboardBody(entries: entries),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг'),
        actions: [
          IconButton(
            tooltip: 'Обновить рейтинг',
            onPressed: () => ref.read(leaderboardProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final topThree = entries.take(3).toList(growable: false);
    final rest = entries.skip(3).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _LeaderboardHero(entries: entries),
        if (topThree.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Podium(topThree: topThree),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Остальные участники',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ...rest.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnimatedLeaderboardTile(
                    entry: entry.value,
                    index: entry.key + 3,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWins = entries.fold<int>(0, (sum, entry) => sum + entry.wins);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Таблица сезона',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Кто держит лучшую форму прямо сейчас',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Обновляется автоматически. Недельный цикл: ${_weeklyWindowLabel()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Игроков',
                    value: '${entries.length}',
                    icon: Icons.groups_2_outlined,
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    label: 'Побед всего',
                    value: '$totalWins',
                    icon: Icons.bolt_outlined,
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    label: 'Лидер',
                    value: entries.first.username,
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.topThree});

  final List<LeaderboardEntry> topThree;

  @override
  Widget build(BuildContext context) {
    final arranged = [
      if (topThree.length > 1) topThree[1],
      topThree.first,
      if (topThree.length > 2) topThree[2],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: arranged.map((entry) {
        final isChampion = entry.rank == 1;
        final height = switch (entry.rank) {
          1 => 236.0,
          2 => 212.0,
          _ => 204.0,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _PodiumCard(
              entry: entry,
              height: height,
              isChampion: isChampion,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.isChampion,
  });

  final LeaderboardEntry entry;
  final double height;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };
    final winRate = _winRate(entry);

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isChampion
              ? [const Color(0xFFFFEDD5), const Color(0xFFFDE68A)]
              : [theme.colorScheme.surface, theme.colorScheme.primaryContainer],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: isChampion ? 30 : 26,
            backgroundColor: theme.colorScheme.surface,
            child: Text(
              entry.username.isEmpty ? '?' : entry.username[0].toUpperCase(),
              style: TextStyle(
                fontSize: isChampion ? 26 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.wins} побед',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$winRate% винрейт',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    final winRate = _winRate(entry);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${entry.rank}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                entry.username.isEmpty ? '?' : entry.username[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.wins}W / ${entry.losses}L',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$winRate%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
      duration: Duration(milliseconds: 240 + (index * 28)),
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

String _winRate(LeaderboardEntry entry) {
  final total = entry.wins + entry.losses;
  if (total == 0) return '0';
  return ((entry.wins / total) * 100).toStringAsFixed(0);
}

String _weeklyWindowLabel() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return '${monday.day}.${monday.month} - ${sunday.day}.${sunday.month}';
}

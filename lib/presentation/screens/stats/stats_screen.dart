import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_stats.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/heat_map_widget.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(statsProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Обзор', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Активность', icon: Icon(Icons.calendar_month_outlined)),
            Tab(text: 'Соперники', icon: Icon(Icons.people_outline)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: switch (state) {
        StatsLoading() => const Center(child: CircularProgressIndicator()),
        StatsError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        StatsLoaded(:final stats) => TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(stats: stats),
              _ActivityTab(stats: stats),
              _OpponentsTab(stats: stats),
            ],
          ),
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              title: 'Всего дуэлей',
              value: stats.totalDuels.toString(),
              icon: Icons.sports_martial_arts,
              color: const Color(0xFFEA580C),
            ),
            _StatCard(
              title: 'Победы',
              value: stats.totalWins.toString(),
              icon: Icons.emoji_events,
              color: const Color(0xFF16A34A),
            ),
            _StatCard(
              title: 'Поражения',
              value: stats.totalLosses.toString(),
              icon: Icons.cancel_outlined,
              color: const Color(0xFFDC2626),
            ),
            _StatCard(
              title: 'Win Rate',
              value: '${stats.winRate.toStringAsFixed(1)}%',
              icon: Icons.show_chart,
              color: const Color(0xFF2563EB),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StreakCard(
                label: 'Текущая серия',
                streak: stats.currentStreak,
                icon: Icons.local_fire_department,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StreakCard(
                label: 'Лучшая серия',
                streak: stats.bestStreak,
                icon: Icons.bolt,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getTimeEmoji(stats.averageCheckinHour),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Любимое время',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.timeOfDayLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '~${stats.averageCheckinHour.toInt()}:00',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Всего чекинов',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  stats.totalCheckins.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeEmoji(double hour) {
    if (hour < 6) return '🌙';
    if (hour < 12) return '🌅';
    if (hour < 18) return '☀️';
    return '🌆';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.label,
    required this.streak,
    required this.icon,
    required this.color,
  });

  final String label;
  final int streak;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 8),
            Text(
              '$streak',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тепловая карта активности',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                HeatMapWidget(
                  heatMapData: stats.heatMapData,
                  cellSize: 14,
                  cellSpacing: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Последние 4 недели',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                MiniHeatMap(heatMapData: stats.heatMapData, days: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OpponentsTab extends StatelessWidget {
  const _OpponentsTab({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.headToHeadStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Пока нет статистики противостояний',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stats.headToHeadStats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final h2h = stats.headToHeadStats.values.elementAt(index);
        return _HeadToHeadCard(stats: h2h);
      },
    );
  }
}

class _HeadToHeadCard extends StatelessWidget {
  const _HeadToHeadCard({required this.stats});

  final HeadToHeadStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winRate = stats.winRate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    stats.opponentName.isNotEmpty
                        ? stats.opponentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.opponentName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stats.totalGames} игр',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: winRate > 50
                        ? Colors.green.withValues(alpha: 0.18)
                        : winRate < 50
                            ? Colors.red.withValues(alpha: 0.18)
                            : Colors.grey.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${winRate.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: winRate > 50
                          ? Colors.green
                          : winRate < 50
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _H2HStat(
                    label: 'Победы',
                    value: stats.wins.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _H2HStat(
                    label: 'Поражения',
                    value: stats.losses.toString(),
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _H2HStat(
                    label: 'Ничьи',
                    value: stats.draws.toString(),
                    color: Colors.grey,
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

class _H2HStat extends StatelessWidget {
  const _H2HStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

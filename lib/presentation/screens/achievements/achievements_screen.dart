import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/achievement.dart';
import '../../providers/achievements_provider.dart';
import '../../widgets/achievement_card.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AchievementCategory.values.length, vsync: this);
    Future.microtask(() => ref.read(achievementsProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);
    final filter = ref.watch(achievementFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AchievementCategory.values.map((cat) => Tab(text: cat.label)).toList(),
        ),
        actions: [
          PopupMenuButton<AchievementFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              ref.read(achievementFilterProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: AchievementFilter.all, child: Text('Все')),
              const PopupMenuItem(value: AchievementFilter.unlocked, child: Text('Разблокированы')),
              const PopupMenuItem(value: AchievementFilter.locked, child: Text('Заблокированы')),
            ],
          ),
        ],
      ),
      body: switch (state) {
        AchievementsLoading() => const Center(child: CircularProgressIndicator()),
        AchievementsError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        AchievementsLoaded(:final trees, :final achievements) => _AchievementsBody(
            trees: trees,
            achievements: achievements,
            filter: filter,
            tabController: _tabController,
          ),
      },
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  const _AchievementsBody({
    required this.trees,
    required this.achievements,
    required this.filter,
    required this.tabController,
  });

  final List<AchievementTree> trees;
  final List<Achievement> achievements;
  final AchievementFilter filter;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Всего',
                  value: achievements.length.toString(),
                  icon: Icons.emoji_events,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Разблокировано',
                  value: achievements.where((a) => a.isUnlocked).length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'XP',
                  value: achievements
                      .where((a) => a.isUnlocked)
                      .fold(0, (sum, a) => sum + a.xpReward)
                      .toString(),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        // Trees overview
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            itemCount: trees.length,
            itemBuilder: (context, index) {
              final tree = trees[index];
              return SizedBox(
                width: 200,
                child: AchievementTreeCard(
                  tree: tree,
                  onTap: () => tabController.animateTo(
                    AchievementCategory.values.indexOf(tree.category),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Achievements list
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: AchievementCategory.values.map((category) {
              var filtered = achievements.where((a) => a.category == category).toList();
              
              filtered = switch (filter) {
                AchievementFilter.all => filtered,
                AchievementFilter.unlocked => filtered.where((a) => a.isUnlocked).toList(),
                AchievementFilter.locked => filtered.where((a) => !a.isUnlocked).toList(),
                AchievementFilter.byCategory => filtered,
              };

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return AchievementCard(
                    achievement: filtered[index],
                    onClaim: filtered[index].isUnlocked
                        ? null
                        : () => _showAchievementDetail(context, filtered[index]),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${achievement.xpReward} XP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!achievement.isUnlocked) ...[
                Text(
                  'Прогресс',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: achievement.progressPercent / 100,
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  '${achievement.progress} / ${achievement.requiredValue}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Разблокировано',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (achievement.unlockedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${achievement.unlockedAt!.day}.${achievement.unlockedAt!.month}.${achievement.unlockedAt!.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

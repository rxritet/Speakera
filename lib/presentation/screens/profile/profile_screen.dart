import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/profile.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final body = switch (state) {
      ProfileInitial() || ProfileLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      ProfileError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ProfileLoaded(:final profile) => _ProfileBody(profile: profile),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winRate = (profile.wins + profile.losses) > 0
        ? (profile.wins / (profile.wins + profile.losses) * 100)
            .toStringAsFixed(1)
        : '–';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Avatar + username ──
        Center(
          child: CircleAvatar(
            radius: 48,
            child: Text(
              profile.username.isNotEmpty
                  ? profile.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 36),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            profile.username,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (profile.email != null)
          Center(
            child: Text(
              profile.email!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),

        const SizedBox(height: 32),

        // ── Stats cards ──
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Wins', value: profile.wins, color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Losses', value: profile.losses, color: Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Win Rate', value: double.tryParse(winRate) ?? 0, suffix: '%', color: Colors.blue)),
          ],
        ),

        const SizedBox(height: 32),

        // ── Badges ──
        Text('Badges', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (profile.badges.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No badges yet. Keep competing!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.badges.map((b) => _BadgeChip(badge: b)).toList(),
          ),

        const SizedBox(height: 32),

        // Quick actions
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.shopping_bag,
                label: 'Магазин',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/shop'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.emoji_events,
                label: 'Достижения',
                color: Colors.amber,
                onTap: () => Navigator.pushNamed(context, '/achievements'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.analytics,
                label: 'Статистика',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/stats'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.star_rounded,
                label: 'XP Прогресс',
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/xp-progress'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });
  final String label;
  final num value;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                final displayValue = value is int
                    ? animatedValue.round().toString()
                    : animatedValue.toStringAsFixed(1);
                return Text(
                  '$displayValue$suffix',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final icon = switch (badge.badgeType) {
      'first_win' => '🏆',
      'streak_7' => '🔥',
      'streak_21' => '💎',
      'streak_30' => '👑',
      _ => '🎖️',
    };
    final label = switch (badge.badgeType) {
      'first_win' => 'First Win',
      'streak_7' => '7-Day Streak',
      'streak_21' => '21-Day Streak',
      'streak_30' => '30-Day Streak',
      _ => badge.badgeType.replaceAll('_', ' '),
    };
    return Chip(
      avatar: Text(icon, style: const TextStyle(fontSize: 18)),
      label: Text(label),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

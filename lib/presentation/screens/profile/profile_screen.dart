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
      body: switch (state) {
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
      },
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
            Expanded(child: _StatCard(label: 'Wins', value: '${profile.wins}', color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Losses', value: '${profile.losses}', color: Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Win Rate', value: '$winRate%', color: Colors.blue)),
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
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

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
    final loadedProfile = state is ProfileLoaded ? state.profile : null;
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
                onPressed: () => ref.read(profileProvider.notifier).load(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ProfileLoaded(:final profile) => _ProfileBody(
          profile: profile,
          onEdit: () => _openEditSheet(context, profile),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed:
                loadedProfile == null ? null : () => _openEditSheet(context, loadedProfile),
          ),
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

  Future<void> _openEditSheet(BuildContext context, UserProfile profile) async {
    final usernameController = TextEditingController(text: profile.username);
    final bioController = TextEditingController(text: profile.bio ?? '');
    final habitController =
        TextEditingController(text: profile.favoriteHabit ?? '');
    final emojiController = TextEditingController(text: profile.avatarEmoji);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Редактирование профиля',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя игрока',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Эмодзи аватара',
                  prefixIcon: Icon(Icons.emoji_emotions_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: habitController,
                decoration: const InputDecoration(
                  labelText: 'Любимая привычка',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(profileProvider.notifier).saveEdits(
                          username: usernameController.text,
                          bio: bioController.text,
                          favoriteHabit: habitController.text,
                          avatarEmoji: emojiController.text,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        );
      },
    );

    usernameController.dispose();
    bioController.dispose();
    habitController.dispose();
    emojiController.dispose();
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winRate = (profile.wins + profile.losses) > 0
        ? (profile.wins / (profile.wins + profile.losses) * 100)
            .toStringAsFixed(1)
        : '0.0';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: theme.colorScheme.surface,
                  child: Text(
                    profile.avatarEmoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.username,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (profile.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if ((profile.bio ?? '').isNotEmpty)
                  Text(
                    profile.bio!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.flag_outlined,
                        label: 'Фокус',
                        value: profile.favoriteHabit ?? 'Новая серия',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Win rate',
                        value: '$winRate%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Изменить профиль'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Победы',
                value: profile.wins,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Поражения',
                value: profile.losses,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Win Rate',
                value: double.tryParse(winRate) ?? 0,
                suffix: '%',
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Бейджи', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (profile.badges.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Пока нет бейджей. Самое время заработать первый.',
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Магазин',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.pushNamed(context, '/shop'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.emoji_events_outlined,
                label: 'Достижения',
                color: const Color(0xFFF59E0B),
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
                icon: Icons.analytics_outlined,
                label: 'Статистика',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.pushNamed(context, '/stats'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.star_rounded,
                label: 'XP Прогресс',
                color: const Color(0xFF16A34A),
                onTap: () => Navigator.pushNamed(context, '/xp-progress'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
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
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.08),
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

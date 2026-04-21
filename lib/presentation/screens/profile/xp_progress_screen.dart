import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/gamification.dart';
import '../../providers/gamification_provider.dart';

/// Экран прогресса XP и уровня пользователя (Gamification 2.0).
class XpProgressScreen extends ConsumerStatefulWidget {
  const XpProgressScreen({super.key});

  @override
  ConsumerState<XpProgressScreen> createState() => _XpProgressScreenState();
}

class _XpProgressScreenState extends ConsumerState<XpProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    Future.microtask(() {
      ref.read(userXpProvider.notifier).load();
      WidgetsBinding.instance.addPostFrameCallback((_) => _progressController.forward());
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userXpProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Прогресс и уровни')),
      body: switch (state) {
        XpLoading() => const Center(child: CircularProgressIndicator()),
        XpError(:final message) => Center(child: Text(message)),
        XpLoaded(:final xp, :final coachMessage) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _LevelCard(xp: xp, progressAnimation: _progressAnimation),
            const SizedBox(height: 20),
            if (xp.freezesAvailable > 0) ...[
              _FreezeCard(freezes: xp.freezesAvailable),
              const SizedBox(height: 20),
            ],
            _XpBreakdown(),
            const SizedBox(height: 20),
            if (coachMessage != null) _CoachMessageCard(message: coachMessage),
          ],
        ),
      },
    );
  }
}

// ─── Level Card ────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.xp, required this.progressAnimation});
  final UserXp xp;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${xp.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      xp.levelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${xp.totalXp} XP • ${xp.xpToNextLevel} XP до уровня ${xp.level + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Weekly XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '+${xp.weeklyXp}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'XP/нед.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: AnimatedBuilder(
              animation: progressAnimation,
              builder: (_, _) => LinearProgressIndicator(
                value: xp.levelProgress * progressAnimation.value,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Freeze Card ───────────────────────────────────────────────────────────

class _FreezeCard extends StatelessWidget {
  const _FreezeCard({required this.freezes});
  final int freezes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🧊', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заморозки стрика: $freezes',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Используй в экран дуэли, чтобы защитить стрик в трудный день.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP Breakdown ─────────────────────────────────────────────────────────

class _XpBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = [
      _XpEventInfo('Ежедневный check-in', '+10 XP', Icons.check_circle_outline, Colors.green),
      _XpEventInfo('Бонус за 7-дневный стрик', '+5 XP', Icons.local_fire_department, Colors.orange),
      _XpEventInfo('Победа в дуэли', '+50 XP', Icons.emoji_events, Colors.amber),
      _XpEventInfo('Топ-3 в группе', '+30 XP', Icons.leaderboard, Colors.purple),
      _XpEventInfo('Trusted Check-in', '+5 XP', Icons.health_and_safety, Colors.teal),
      _XpEventInfo('Первая дуэль', '+20 XP', Icons.celebration, Colors.pink),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как зарабатывать XP',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...events.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(e.icon, color: e.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.label, style: theme.textTheme.bodyMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e.xp,
                    style: TextStyle(
                      color: e.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _XpEventInfo {
  const _XpEventInfo(this.label, this.xp, this.icon, this.color);
  final String label;
  final String xp;
  final IconData icon;
  final Color color;
}

// ─── AI Coach Message Card ─────────────────────────────────────────────────

class _CoachMessageCard extends StatelessWidget {
  const _CoachMessageCard({required this.message});

  final AiCoachMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Коуч говорит:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Еженедельный анализ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message.message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (message.suggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.suggestion!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                '${message.checkinsThisWeek} чекинов • стрик ${message.bestStreak} дней',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

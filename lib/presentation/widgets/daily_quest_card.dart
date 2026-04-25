import 'package:flutter/material.dart';
import '../../domain/entities/event.dart';

/// Карточка ежедневного квеста.
class DailyQuestCard extends StatelessWidget {
  const DailyQuestCard({
    super.key,
    required this.quest,
    this.onClaim,
  });

  final DailyQuest quest;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = quest.isCompleted;
    final isClaimed = quest.isClaimed;
    final canClaim = quest.canClaim;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canClaim
                ? [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ]
                : isCompleted
                    ? [
                        theme.colorScheme.surfaceContainerHighest,
                        theme.colorScheme.surfaceContainer,
                      ]
                    : [
                        theme.colorScheme.surfaceContainer,
                        theme.colorScheme.surfaceContainerHighest,
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getQuestIcon(quest.type),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isClaimed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${quest.xpReward} XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress
                  if (!isCompleted && !isClaimed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: quest.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (!isCompleted && !isClaimed) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${quest.currentProgress} / ${quest.targetProgress}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status
            if (isClaimed)
              const Icon(Icons.check_circle, color: Colors.green, size: 32)
            else if (canClaim && onClaim != null)
              FilledButton(
                onPressed: onClaim,
                child: const Text('Забрать'),
              )
            else if (isCompleted)
              const Icon(Icons.task_alt, color: Colors.grey, size: 28),
          ],
        ),
      ),
    );
  }

  String _getQuestIcon(DailyQuestType type) {
    return switch (type) {
      DailyQuestType.checkin => '✓',
      DailyQuestType.checkin3 => '✓✓✓',
      DailyQuestType.duelWin => '⚔️',
      DailyQuestType.streak7 => '🔥',
      DailyQuestType.social => '👥',
    };
  }
}

/// Виджет списка ежедневных квестов.
class DailyQuestsList extends StatelessWidget {
  const DailyQuestsList({
    super.key,
    required this.quests,
    this.onClaim,
  });

  final List<DailyQuest> quests;
  final Function(DailyQuest)? onClaim;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Нет активных квестов'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return DailyQuestCard(
          quest: quest,
          onClaim: quest.canClaim
              ? () => onClaim?.call(quest)
              : null,
        );
      },
    );
  }
}

/// Карточка события.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onJoin,
    this.onClaimReward,
  });

  final GameEvent event;
  final VoidCallback? onJoin;
  final Function(String)? onClaimReward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = event.isActive;
    final progress = event.progressPercent;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(event.bannerColor),
              Color(event.bannerColor).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    event.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress
            if (event.userProgress != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Прогресс',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${event.userProgress!.currentValue} / ${event.userProgress!.targetValue}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Осталось: ${event.daysRemaining} дн.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  if (!isActive && onJoin != null)
                    FilledButton(
                      onPressed: onJoin,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(event.bannerColor),
                      ),
                      child: const Text('Участвовать'),
                    )
                  else if (isActive)
                    Text(
                      '${event.participantsCount} участников',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

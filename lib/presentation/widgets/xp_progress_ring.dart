import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Анимированное кольцо прогресса XP.
class XpProgressRing extends StatelessWidget {
  const XpProgressRing({
    super.key,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.level,
    this.size = 200,
    this.strokeWidth = 20,
    this.showLevel = true,
  });

  final int currentXp;
  final int xpToNextLevel;
  final int level;
  final double size;
  final double strokeWidth;
  final bool showLevel;

  double get progress => xpToNextLevel > 0 
      ? ((xpToNextLevel - (xpToNextLevel - (currentXp % 200))) / xpToNextLevel)
      : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualProgress = (currentXp % 200) / 200;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Фоновое кольцо
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: RingPainter(
                progress: 1,
                strokeWidth: strokeWidth,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          // Прогресс кольцо
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: RingPainter(
                progress: actualProgress,
                strokeWidth: strokeWidth,
                color: theme.colorScheme.primary,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
            ),
          ),
          // Центр
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLevel)
                Text(
                  'LVL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '$level',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentXp % 200} / 200 XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.progress,
    required this.strokeWidth,
    this.color,
    this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final Color? color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = color?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (gradient != null) {
        progressPaint.shader = gradient!.createShader(rect);
      } else {
        progressPaint.color = color ?? Colors.blue;
      }

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient;
  }
}

/// Горизонтальный прогресс XP с уровнем.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.totalXp,
    required this.level,
    this.height = 12,
  });

  final int currentXp;
  final int totalXp;
  final int level;
  final double height;

  double get progress => totalXp > 0 ? (currentXp % 200) / 200 : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Уровень $level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${currentXp % 200} / 200 XP',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: height,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

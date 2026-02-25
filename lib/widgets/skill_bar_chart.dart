import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_theme.dart';

/// Vertical bar chart showing scores for 5 language skills.
///
/// Each bar is color-coded by score range:
///   ≥ 80 → green (riskLow)
///   ≥ 60 → blue  (accent)
///   < 60 → red   (riskHigh)
///
/// Bars have rounded tops and sit on a clean grid with bottom labels.
class SkillBarChart extends StatelessWidget {
  /// Map of skill name → score (0-100).
  /// Expected keys: listening, reading, writing, speaking, grammar.
  final Map<String, int> scores;
  final String title;

  const SkillBarChart({
    super.key,
    required this.scores,
    this.title = 'Skills Overview',
  });

  // Canonical skill order
  static const _skillOrder = [
    'listening',
    'reading',
    'writing',
    'speaking',
    'grammar',
  ];

  static const _skillLabels = [
    'Listen.',
    'Read.',
    'Writ.',
    'Speak.',
    'Gram.',
  ];

  static const _skillIcons = [
    Icons.headphones_rounded,
    Icons.menu_book_rounded,
    Icons.edit_rounded,
    Icons.mic_rounded,
    Icons.spellcheck_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build ordered data, defaulting missing skills to 0
    final data = _skillOrder
        .map((s) => (scores[s] ?? 0).toDouble())
        .toList();

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Bar chart ──
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: AppRadius.sm,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final skill = _skillOrder[group.x];
                        final score = rod.toY.toInt();
                        return BarTooltipItem(
                          '${_capitalise(skill)}\n',
                          TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? AppColors.dividerDark.withValues(alpha: 0.4)
                          : AppColors.divider.withValues(alpha: 0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _skillLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _skillIcons[idx],
                                  size: 16,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _skillLabels[idx],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(data.length, (i) {
                    final val = data[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          width: 28,
                          color: _barColor(val.toInt()),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: isDark
                                ? AppColors.dividerDark.withValues(alpha: 0.3)
                                : AppColors.divider.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Legend ──
            _buildLegend(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    final items = [
      (color: AppColors.riskLow, label: 'Excellent (≥80)'),
      (color: AppColors.accent, label: 'Good (60–79)'),
      (color: AppColors.riskHigh, label: 'Needs work (<60)'),
    ];

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static Color _barColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

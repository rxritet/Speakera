import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Тепловая карта активности (GitHub-style contribution graph).
class HeatMapWidget extends StatelessWidget {
  const HeatMapWidget({
    super.key,
    required this.heatMapData,
    this.cellSize = 12,
    this.cellSpacing = 3,
    this.cornerRadius = 2,
  });

  /// Данные: {date: checkinCount}.
  final Map<String, int> heatMapData;
  final double cellSize;
  final double cellSpacing;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Генерируем последние 365 дней
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 364));
    
    // Группируем по неделям
    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];
    
    for (var i = 0; i < 365; i++) {
      final date = startDate.add(Duration(days: i));
      if (date.weekday == 1 && currentWeek.isNotEmpty) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      currentWeek.add(date);
    }
    if (currentWeek.isNotEmpty) weeks.add(currentWeek);

    // Уровни интенсивности
    final maxCount = heatMapData.values.isNotEmpty 
        ? heatMapData.values.reduce((a, b) => a > b ? a : b) 
        : 1;
    
    Color getColorForCount(int count) {
      if (count == 0) return theme.colorScheme.surfaceContainerHighest;
      final intensity = count / maxCount;
      if (intensity < 0.25) return theme.colorScheme.primary.withValues(alpha: 0.3);
      if (intensity < 0.5) return theme.colorScheme.primary.withValues(alpha: 0.5);
      if (intensity < 0.75) return theme.colorScheme.primary.withValues(alpha: 0.7);
      return theme.colorScheme.primary;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дни недели
            Column(
              children: [
                const SizedBox(height: 20),
                _buildDayLabel('Пн'),
                SizedBox(height: cellSpacing),
                _buildDayLabel('Ср'),
                SizedBox(height: cellSpacing),
                _buildDayLabel('Пт'),
              ],
            ),
            const SizedBox(width: 8),
            // Недели
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weeks.map((week) {
                return Row(
                  children: week.map((date) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final count = heatMapData[dateKey] ?? 0;
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.all(cellSpacing / 2),
                      decoration: BoxDecoration(
                        color: getColorForCount(count),
                        borderRadius: BorderRadius.circular(cornerRadius),
                      ),
                      child: Tooltip(
                        message: '${DateFormat('d MMM', 'ru').format(date)}: $count чекинов',
                        child: InkWell(
                          onTap: count > 0 
                              ? () => _showDayDetail(context, date, count) 
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayLabel(String label) {
    return SizedBox(
      width: cellSize,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime date, int count) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM y', 'ru').format(date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$count чекинов',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Мини-версия тепловой карты для профиля.
class MiniHeatMap extends StatelessWidget {
  const MiniHeatMap({
    super.key,
    required this.heatMapData,
    this.days = 28,
  });

  final Map<String, int> heatMapData;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days - 1));
    
    final maxCount = heatMapData.values.isNotEmpty 
        ? heatMapData.values.reduce((a, b) => a > b ? a : b) 
        : 1;

    Color getColorForCount(int count) {
      if (count == 0) return theme.colorScheme.surfaceContainerHighest;
      final intensity = count / maxCount;
      if (intensity < 0.5) return theme.colorScheme.primary.withValues(alpha: 0.4);
      return theme.colorScheme.primary;
    }

    return SizedBox(
      height: 56,
      child: Row(
        children: List.generate(days, (index) {
          final date = startDate.add(Duration(days: index));
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final count = heatMapData[dateKey] ?? 0;
          
          return Container(
            width: 8,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: getColorForCount(count),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

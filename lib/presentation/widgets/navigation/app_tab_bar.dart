import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  Перечисления и данные
// ──────────────────────────────────────────────────────────────────────────────

/// Стиль индикатора вкладки.
enum AppTabStyle {
  /// Закрашенная капсула скользит за выбранной вкладкой.
  pill,

  /// Тонкая линия под выбранной вкладкой.
  underline,
}

/// Данные одной вкладки.
class AppTabItem {
  const AppTabItem({
    required this.label,
    this.icon,
    this.badgeCount,
  });

  /// Текст вкладки.
  final String label;

  /// Иконка вкладки.
  final IconData? icon;

  /// Числовой бейдж (null или 0 — скрыт).
  final int? badgeCount;
}

// ──────────────────────────────────────────────────────────────────────────────
//  AppTabBar
// ──────────────────────────────────────────────────────────────────────────────

/// Таббар с поддержкой стилей [AppTabStyle.pill] и [AppTabStyle.underline].
///
/// Индикатор анимируется за 300 мс через [AnimationController] — плавно
/// скользит между любыми двумя вкладками в любом направлении.
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.style = AppTabStyle.pill,
    this.height = 44.0,
  });

  final List<AppTabItem> tabs;

  /// Индекс активной вкладки.
  final int selectedIndex;

  /// Вызывается при смене вкладки.
  final ValueChanged<int> onTabChanged;

  /// Стиль индикатора.
  final AppTabStyle style;

  /// Высота виджета. По умолчанию 44 px.
  final double height;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  // ── Анимация позиции индикатора ──────────────────────────────────────────

  late final AnimationController _ctrl;

  /// Дробная позиция индикатора (1.5 — между 1 и 2 вкладками).
  late double _fromIndex;
  late double _toIndex;
  late Animation<double> _indicatorPos;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex.toDouble();
    _toIndex   = widget.selectedIndex.toDouble();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _indicatorPos = AlwaysStoppedAnimation(_toIndex);
  }

  @override
  void didUpdateWidget(AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Фиксируем текущую визуальную позицию как начало новой анимации.
      final currentPos = _fromIndex +
          (_toIndex - _fromIndex) * _ctrl.value;
      _fromIndex = currentPos;
      _toIndex   = widget.selectedIndex.toDouble();

      _indicatorPos = Tween<double>(
        begin: _fromIndex,
        end: _toIndex,
      ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );

      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Сборка ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (widget.style) {
      AppTabStyle.pill      => _buildPill(context, isDark),
      AppTabStyle.underline => _buildUnderline(context, isDark),
    };
  }

  // ── Стиль капсулы ────────────────────────────────────────────────────────────

  Widget _buildPill(BuildContext context, bool isDark) {
    final containerBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceElevated;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount  = widget.tabs.length;
          final totalW    = constraints.maxWidth;
          final tabW      = totalW / tabCount;

          return AnimatedBuilder(
            animation: _indicatorPos,
            builder: (context, _) {
              final pos = _indicatorPos.value;

              return Stack(
                children: [
                  // ── Анимированная капсула ──────────────────────────────────────
                  Positioned(
                    left: pos * tabW,
                    top: 0,
                    bottom: 0,
                    width: tabW,
                    child: _PillIndicator(isDark: isDark),
                  ),

                  // ── Подписи вкладок (поверх индикатора) ────────────────────
                  Row(
                    children: List.generate(tabCount, (i) {
                      final isSelected = i == widget.selectedIndex;
                      return _TabCell(
                        width: tabW,
                        height: widget.height - 6, // без отступа контейнера
                        item: widget.tabs[i],
                        isSelected: isSelected,
                        isDark: isDark,
                        style: AppTabStyle.pill,
                        onTap: () => widget.onTabChanged(i),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Стиль подчёркивания ─────────────────────────────────────────────────────

  Widget _buildUnderline(BuildContext context, bool isDark) {
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabCount = widget.tabs.length;
          final totalW   = constraints.maxWidth;
          final tabW     = totalW / tabCount;

          return AnimatedBuilder(
            animation: _indicatorPos,
            builder: (context, _) {
              final pos = _indicatorPos.value;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Разделитель.
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Divider(height: 1, color: dividerColor),
                  ),

                  // ── Анимированное подчёркивание ─────────────────────────────────
                  Positioned(
                    bottom: 0,
                    left: pos * tabW + tabW * 0.15,
                    width: tabW * 0.70,
                    height: 2,
                    child: _UnderlineIndicator(isDark: isDark),
                  ),

                  // ── Подписи вкладок ───────────────────────────────────────────────
                  Row(
                    children: List.generate(tabCount, (i) {
                      final isSelected = i == widget.selectedIndex;
                      return _TabCell(
                        width: tabW,
                        height: widget.height,
                        item: widget.tabs[i],
                        isSelected: isSelected,
                        isDark: isDark,
                        style: AppTabStyle.underline,
                        onTap: () => widget.onTabChanged(i),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  Индикаторы
// ──────────────────────────────────────────────────────────────────────────────

class _PillIndicator extends StatelessWidget {
  const _PillIndicator({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary(
          isDark ? Brightness.dark : Brightness.light,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primaryNight : AppColors.primary)
                .withAlpha(isDark ? 0x40 : 0x26),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _UnderlineIndicator extends StatelessWidget {
  const _UnderlineIndicator({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary(
          isDark ? Brightness.dark : Brightness.light,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  Ячейка вкладки
// ──────────────────────────────────────────────────────────────────────────────

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.width,
    required this.height,
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.style,
    required this.onTap,
  });

  final double width;
  final double height;
  final AppTabItem item;
  final bool isSelected;
  final bool isDark;
  final AppTabStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor  = isDark ? AppColors.primaryNight : Colors.white;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final labelColor = style == AppTabStyle.pill
        ? (isSelected ? activeColor : inactiveColor)
        : (isSelected
            ? (isDark ? AppColors.primaryNight : AppColors.primary)
            : inactiveColor);

    final labelStyle = AppTypography.button.copyWith(
      fontSize: 13,
      color: labelColor,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: AppSpacing.iconSm, color: labelColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(item.label, style: labelStyle),
            if ((item.badgeCount ?? 0) > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              _BadgeDot(count: item.badgeCount!, isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Numeric badge ─────────────────────────────────────────────────────────────

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({required this.count, required this.isDark});
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.overline.copyWith(
          color: Colors.white,
          fontSize: 9,
          height: 1.2,
        ),
      ),
    );
  }
}

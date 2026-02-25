import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Generic filter chip row used for risk, test-type, status filters.
class FilterChips<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: isDark ? AppColors.accent : AppColors.primary,
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.textOnPrimary
                : (isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            side: isSelected
                ? BorderSide.none
                : BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                  ),
          ),
          side: BorderSide.none,
          showCheckmark: false,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        );
      }).toList(),
    );
  }
}

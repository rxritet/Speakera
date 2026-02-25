import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A single multiple-choice option card.
///
/// Highlights with the primary/accent colour when [isSelected] is true.
/// Taps trigger [onTap].
class AnswerOptionTile extends StatelessWidget {
  final String label;
  final String optionLetter; // A, B, C, D…
  final bool isSelected;
  final VoidCallback onTap;

  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.optionLetter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.accent : AppColors.primary).withValues(alpha: 0.10)
        : isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight;

    final borderColor = isSelected
        ? (isDark ? AppColors.accent : AppColors.primary)
        : isDark
            ? AppColors.dividerDark
            : AppColors.divider;

    final letterBg = isSelected
        ? (isDark ? AppColors.accent : AppColors.primary)
        : isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF1F5F9);

    final letterFg = isSelected
        ? Colors.white
        : isDark
            ? AppColors.textDarkSecondary
            : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              // Letter badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  optionLetter,
                  style: TextStyle(
                    color: letterFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              // Check mark
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

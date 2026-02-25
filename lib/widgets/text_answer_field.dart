import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A text-input answer widget with a styled multi-line TextField.
class TextAnswerField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const TextAnswerField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Type your answer here…',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
        color: isDark ? AppColors.inputDarkFill : AppColors.inputFill,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 6,
        minLines: 4,
        style: TextStyle(
          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textHint,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
        ),
      ),
    );
  }
}

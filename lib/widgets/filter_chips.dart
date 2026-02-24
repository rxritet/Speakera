import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF1E3A5F);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: isDark ? const Color(0xFF3B82F6) : primaryColor,
          backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        );
      }).toList(),
    );
  }
}

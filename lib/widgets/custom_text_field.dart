import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A styled text field matching the Speakera design system.
///
/// Features:
/// - Rounded corners (12px)
/// - Filled background (light grey)
/// - Subtle border with accent color on focus
/// - Prefix icon support
/// - Suffix icon support (e.g., visibility toggle)
/// - Error state
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      focusNode: focusNode,
      enabled: enabled,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 20,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              )
            : null,
        suffixIcon: suffixIcon,
        // All other styling comes from theme's InputDecorationTheme
      ),
    );
  }
}

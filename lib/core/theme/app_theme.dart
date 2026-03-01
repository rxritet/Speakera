import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Premium Glass Design System — Root ThemeData
///
/// Implements the "Premium Glass" concept from DESIGN.md.
/// Colours, typography, radii, and component defaults all derive from
/// [AppColors], [AppTypography], and [AppSpacing] tokens.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
abstract final class AppTheme {
  // ── Public entries ─────────────────────────────────────────────────────────

  static ThemeData get light => _build(isDark: false);
  static ThemeData get dark  => _build(isDark: true);

  // ── Internal builder ───────────────────────────────────────────────────────

  static ThemeData _build({required bool isDark}) {
    // ── Resolved palette ─────────────────────────────────────────────────────
    final bg             = isDark ? AppColors.darkBackground      : AppColors.lightBackground;
    final surface        = isDark ? AppColors.darkSurface         : AppColors.lightSurface;
    final surfaceElev    = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final glassBg        = isDark ? AppColors.darkGlassBackground : AppColors.lightGlassBackground;
    final glassBorder    = isDark ? AppColors.darkGlassBorder     : AppColors.lightGlassBorder;
    final textPrimary    = isDark ? AppColors.darkTextPrimary     : AppColors.lightTextPrimary;
    final textSecondary  = isDark ? AppColors.darkTextSecondary   : AppColors.lightTextSecondary;
    final textMuted      = isDark ? AppColors.darkTextMuted       : AppColors.lightTextMuted;
    final borderColor    = isDark ? AppColors.darkBorder          : AppColors.lightBorder;
    final primaryColor   = isDark ? AppColors.primaryNight        : AppColors.primary;
    final secondaryColor = isDark ? AppColors.secondaryNight      : AppColors.secondary;
    final tertiaryColor  = isDark ? AppColors.tertiaryNight       : AppColors.tertiary;
    final brightness     = isDark ? Brightness.dark               : Brightness.light;

    // Status-bar icons contrast
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    // ── ColorScheme ──────────────────────────────────────────────────────────
    final colorScheme = ColorScheme(
      brightness: brightness,

      // Primary
      primary: primaryColor,
      onPrimary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      primaryContainer: isDark
          ? AppColors.primaryContainerNight
          : AppColors.primaryContainer,
      onPrimaryContainer: isDark ? AppColors.darkTextPrimary : AppColors.lightSurface,

      // Secondary
      secondary: secondaryColor,
      onSecondary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      secondaryContainer: isDark
          ? AppColors.secondaryContainerNight
          : AppColors.secondaryContainer,
      onSecondaryContainer: isDark ? AppColors.darkTextPrimary : AppColors.lightSurface,

      // Tertiary
      tertiary: tertiaryColor,
      onTertiary: isDark ? AppColors.darkBackground : AppColors.lightSurface,
      tertiaryContainer: isDark
          ? const Color(0xFF065F46) // emerald-900
          : const Color(0xFFD1FAE5), // emerald-100
      onTertiaryContainer: isDark ? AppColors.tertiaryNight : AppColors.tertiary,

      // Error
      error: AppColors.error,
      onError: AppColors.lightSurface,
      errorContainer: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
      onErrorContainer: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),

      // Surfaces
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceElev,
      onSurfaceVariant: textSecondary,

      // Scaffold background / legacy
      // ignore: deprecated_member_use
      background: bg,
      // ignore: deprecated_member_use
      onBackground: textPrimary,

      // Outline / border
      outline: borderColor,
      outlineVariant: glassBorder,

      // Misc
      shadow: Colors.black,
      scrim: AppColors.scrim,
      inverseSurface: isDark ? AppColors.lightSurface  : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      inversePrimary: isDark ? AppColors.primary : AppColors.primaryNight,
    );

    // ── ThemeData ────────────────────────────────────────────────────────────
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: AppTypography.toTextTheme(
        primaryColor: textPrimary,
        secondaryColor: textSecondary,
        mutedColor: textMuted,
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: textPrimary, size: AppSpacing.iconMd),
        titleTextStyle: AppTypography.h3.copyWith(color: textPrimary),
        centerTitle: false,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      // Glass card: semi-transparent fill + subtle border.
      // BackdropFilter blur must be applied in the widget, but base colours
      // are defined here so GlassCard can read them from the theme.
      cardTheme: CardThemeData(
        color: glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: glassBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.itemGap / 2,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
          disabledBackgroundColor: glassBg,
          disabledForegroundColor: textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      // ── Input / TextField ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.body.copyWith(color: textSecondary),
        hintStyle: AppTypography.body.copyWith(color: textMuted),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── NavigationBar (Material 3) ───────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: primaryColor.withAlpha(40),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: AppSpacing.iconMd);
          }
          return IconThemeData(color: textSecondary, size: AppSpacing.iconMd);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.overline.copyWith(color: primaryColor);
          }
          return AppTypography.overline.copyWith(color: textSecondary);
        }),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
      ),

      // ── Bottom Navigation Bar (legacy) ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.overline,
        unselectedLabelStyle: AppTypography.overline,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: textSecondary, size: AppSpacing.iconMd),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: glassBg,
        selectedColor: primaryColor.withAlpha(50),
        labelStyle: AppTypography.caption.copyWith(color: textPrimary),
        side: BorderSide(color: glassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElev,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        ),
        titleTextStyle: AppTypography.h3.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: textSecondary),
      ),

      // ── Snackbar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElev,
        contentTextStyle: AppTypography.body.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Progress Indicator ───────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: glassBg,
        circularTrackColor: glassBg,
      ),

      // ── Switch / Toggle ──────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.darkBackground : AppColors.lightSurface;
          }
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return glassBg;
        }),
      ),

      // ── Floating Action Button ───────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),

      // ── Badge ────────────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: secondaryColor,
        textColor: AppColors.lightSurface,
        textStyle: AppTypography.overline,
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: textSecondary,
        titleTextStyle: AppTypography.body.copyWith(color: textPrimary),
        subtitleTextStyle: AppTypography.caption.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
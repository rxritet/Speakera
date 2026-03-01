import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Glass Design System — Typography
///
/// Implements the exact type scale from DESIGN.md §2.3.
///
/// **Font family:** Inter (400 · 500 · 600 · 700) via `google_fonts`.
///
/// Named getters (`h1` … `overline`) match the DESIGN.md names directly.
/// [toTextTheme] maps these onto Flutter's [TextTheme] for [ThemeData].
///
/// Letter-spacing values are converted from em to logical pixels:
///   -0.02em at 32 px → -0.64 lp,  0.02em at 16 px → 0.32 lp, etc.
///
/// Usage:
/// ```dart
/// Text('Level up', style: AppTypography.h1)
/// Text('Today's habit', style: AppTypography.subtitle)
/// ```
abstract final class AppTypography {
  // ══════════════════════════════════════════════════════════════════
  //  DESIGN SYSTEM NAMED STYLES  (DESIGN.md §2.3)
  // ══════════════════════════════════════════════════════════════════

  /// H1 — screen titles, hero labels.
  /// 32 px · w700 · height 1.2 · ls -0.64 (-0.02 em)
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.64,
  );

  /// H2 — section headings.
  /// 24 px · w600 · height 1.3 · ls -0.24 (-0.01 em)
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.24,
  );

  /// H3 — sub-section labels, card headings.
  /// 20 px · w600 · height 1.4 · ls 0
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Subtitle — supporting screen title line, list group headers.
  /// 18 px · w500 · height 1.5 · ls 0
  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Body Large — primary readable content.
  /// 16 px · w400 · height 1.6 · ls 0
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  /// Body — standard content text.
  /// 14 px · w400 · height 1.6 · ls 0
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  /// Caption — timestamps, metadata, helper text.
  /// 12 px · w500 · height 1.5 · ls 0.12 (0.01 em)
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.12,
  );

  /// Button — all button labels.
  /// 16 px · w600 · height 1.0 · ls 0.32 (0.02 em)
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.32,
  );

  /// Overline — category labels, pill tags, badge text.
  /// 11 px · w600 · height 1.0 · ls 0.55 (0.05 em)
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.55,
  );

  // ══════════════════════════════════════════════════════════════════
  //  SPECIAL-PURPOSE STYLES  (not in DESIGN.md type scale)
  // ══════════════════════════════════════════════════════════════════

  /// Large hero numeral — streak count, days, big scores.
  /// 64 px · w800 · height 1.0 · ls -1.28
  static TextStyle get numeralHero => GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.28,
  );

  /// Medium stat numeral — badge values, secondary counters.
  /// 36 px · w700 · height 1.0 · ls -0.72
  static TextStyle get numeralMedium => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.72,
  );

  /// Small button label — secondary / icon-text combos.
  /// 14 px · w600 · height 1.0 · ls 0.28
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.28,
  );

  /// Form input text.
  /// 16 px · w400 · height 1.5 · ls 0
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // ══════════════════════════════════════════════════════════════════
  //  MATERIAL TEXT THEME BUILDER
  // ══════════════════════════════════════════════════════════════════

  /// Builds a [TextTheme] for [ThemeData] using the DESIGN.md type scale.
  ///
  /// Pass [primaryColor], [secondaryColor], and [mutedColor] to tint text
  /// appropriately for light or dark mode.
  static TextTheme toTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      // Display — hero numerals / large stats
      displayLarge: numeralHero.copyWith(color: primaryColor),
      displayMedium: h1.copyWith(color: primaryColor),
      displaySmall: h2.copyWith(color: primaryColor),

      // Headline — screen & section titles
      headlineLarge: h1.copyWith(color: primaryColor),
      headlineMedium: h2.copyWith(color: primaryColor),
      headlineSmall: h3.copyWith(color: primaryColor),

      // Title — card heads, list group labels
      titleLarge: subtitle.copyWith(color: primaryColor),
      titleMedium: bodyLarge.copyWith(
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      titleSmall: body.copyWith(fontWeight: FontWeight.w500, color: primaryColor),

      // Body — readable content
      bodyLarge: bodyLarge.copyWith(color: secondaryColor),
      bodyMedium: body.copyWith(color: secondaryColor),
      bodySmall: caption.copyWith(color: mutedColor),

      // Label — buttons, chips, tags, overlines
      labelLarge: button.copyWith(color: primaryColor),
      labelMedium: caption.copyWith(color: primaryColor),
      labelSmall: overline.copyWith(color: mutedColor),
    );
  }
}

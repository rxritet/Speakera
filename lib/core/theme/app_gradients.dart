import 'package:flutter/material.dart';

/// Premium Glass Design System — Gradient Definitions
///
/// Implements the exact gradient tokens from DESIGN.md §2.2.
///
/// **Primary** — ocean-sky (Day) / sky-cyan (Night)  → identity, CTA, progress
/// **Secondary** — coral-rose (Day) / rose-blush (Night) → opponent, VS, duels
/// **Success** — mint-emerald → completion, victory, growth
/// **Warning** — amber-gold → reminders, streak alerts
/// **Background Night** — deep charcoal sweep → page background in dark mode
///
/// Use the `*Day` / `*Night` suffix for mode-specific gradients.
/// Utility gradients (gold, streak fire, glass shimmer) are mode-agnostic.
abstract final class AppGradients {
  // ══════════════════════════════════════════════════════════════════
  //  PRIMARY GRADIENT  (Ocean-blue / Sky-blue)
  // ══════════════════════════════════════════════════════════════════

  /// Day: #0EA5E9 → #22D3EE at 135°  (CTA, active elements, your progress).
  static const LinearGradient primaryDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
  );

  /// Night: #38BDF8 → #22D3EE at 135°  (CTA, active elements, your progress).
  static const LinearGradient primaryNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF22D3EE)],
  );

  // ══════════════════════════════════════════════════════════════════
  //  SECONDARY GRADIENT  (Coral / Rose)
  // ══════════════════════════════════════════════════════════════════

  /// Day: #F43F5E → #FB7185 at 135°  (opponent, VS elements, duels).
  static const LinearGradient secondaryDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );

  /// Night: #FB7185 → #FDA4AF at 135°  (opponent, VS elements).
  static const LinearGradient secondaryNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFFDA4AF)],
  );

  // ══════════════════════════════════════════════════════════════════
  //  UTILITY GRADIENTS  (mode-agnostic)
  // ══════════════════════════════════════════════════════════════════

  /// Success / victory / growth: #10B981 → #34D399 at 135°.
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  /// Warning / reminder: #F59E0B → #FBBF24 at 135°.
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  /// Night page background sweep: deep charcoal top & bottom, charcoal mid.
  static const LinearGradient backgroundNight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C0A09), Color(0xFF1C1917), Color(0xFF0C0A09)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Streak / fire effect: yellow → orange → red-orange (top-to-bottom).
  static const LinearGradient streak = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE259), Color(0xFFFF8C00), Color(0xFFFF4500)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gold / achievement shimmer: bright gold → deep gold at 135°.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE066), Color(0xFFFFD700), Color(0xFFD4A017)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Glass shimmer overlay (foreground shimmer inside glass cards).
  static const LinearGradient glassShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // white 20 %
      Color(0x0DFFFFFF), // white  5 %
      Color(0x1AFFFFFF), // white 10 %
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ══════════════════════════════════════════════════════════════════
  //  CONVENIENCE HELPERS
  // ══════════════════════════════════════════════════════════════════

  /// Returns the correct primary gradient for the given brightness.
  static LinearGradient primary(Brightness brightness) =>
      brightness == Brightness.dark ? primaryNight : primaryDay;

  /// Returns the correct secondary gradient for the given brightness.
  static LinearGradient secondary(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryNight : secondaryDay;
}

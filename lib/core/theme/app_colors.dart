import 'package:flutter/material.dart';

/// Premium Glass Design System — Color Palette
///
/// Implements the exact "Premium Glass" tokens from the DESIGN.md specification.
///
/// **Day (Light) mode** uses warm neutral backgrounds with ocean-blue primary.
/// **Night (Dark) mode** uses deep charcoal backgrounds with sky-blue primary.
///
/// Naming convention:
///  - `light*`  — Day / Light theme tokens
///  - `dark*`   — Night / Dark theme tokens
///  - Unprefixed brand colours are the Day variants; use `*Night` for Night.
abstract final class AppColors {
  // ══════════════════════════════════════════════════════════════════
  //  DAY MODE  (Light theme)
  // ══════════════════════════════════════════════════════════════════

  /// White pearl — general screen background.
  static const Color lightBackground = Color(0xFFFAFAF9);

  /// Pure white — cards, modals, inputs.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light stone — hover states, highlighted blocks.
  static const Color lightSurfaceElevated = Color(0xFFF5F5F4);

  /// Glass card background: white at 70 % opacity.
  static const Color lightGlassBackground = Color(0xB3FFFFFF);

  /// Glass card border: white at 20 % opacity.
  static const Color lightGlassBorder = Color(0x33FFFFFF);

  /// Charcoal — headings, primary body text.
  static const Color lightTextPrimary = Color(0xFF1C1917);

  /// Stone grey — captions, metadata.
  static const Color lightTextSecondary = Color(0xFF78716C);

  /// Light stone grey — placeholders, disabled text.
  static const Color lightTextMuted = Color(0xFFA8A29E);

  /// Warm grey — dividers, card borders.
  static const Color lightBorder = Color(0xFFE7E5E4);

  // ══════════════════════════════════════════════════════════════════
  //  NIGHT MODE  (Dark theme)
  // ══════════════════════════════════════════════════════════════════

  /// Deep charcoal — general screen background.
  static const Color darkBackground = Color(0xFF0C0A09);

  /// Charcoal — cards, modals, inputs.
  static const Color darkSurface = Color(0xFF1C1917);

  /// Warm graphite — hover states, elevated blocks.
  static const Color darkSurfaceElevated = Color(0xFF292524);

  /// Glass card background: charcoal at 60 % opacity.
  static const Color darkGlassBackground = Color(0x991C1917);

  /// Glass card border: white at 5 % opacity.
  static const Color darkGlassBorder = Color(0x0DFFFFFF);

  /// Off-white — headings, primary body text.
  static const Color darkTextPrimary = Color(0xFFFAFAF9);

  /// Warm grey — captions, metadata.
  static const Color darkTextSecondary = Color(0xFFA8A29E);

  /// Dark grey — placeholders, disabled text.
  static const Color darkTextMuted = Color(0xFF78716C);

  /// Dark divider line.
  static const Color darkBorder = Color(0xFF44403C);

  // ══════════════════════════════════════════════════════════════════
  //  BRAND COLOURS  (Day variants as canonical; Night variants below)
  // ══════════════════════════════════════════════════════════════════

  // ── Primary ────────────────────────────────────────────────────────────────

  /// Ocean blue — CTA, your progress, active elements (Day).
  static const Color primary = Color(0xFF0EA5E9);

  /// Sky blue — CTA, your progress, active elements (Night).
  static const Color primaryNight = Color(0xFF38BDF8);

  /// Darker ocean for containers / pressed states (Day).
  static const Color primaryContainer = Color(0xFF0369A1);

  /// Darker sky for containers / pressed states (Night).
  static const Color primaryContainerNight = Color(0xFF0EA5E9);

  // ── Secondary ──────────────────────────────────────────────────────────────

  /// Coral — opponent, VS elements, duels (Day).
  static const Color secondary = Color(0xFFF43F5E);

  /// Rose — opponent, VS elements (Night).
  static const Color secondaryNight = Color(0xFFFB7185);

  /// Deep rose container (Day).
  static const Color secondaryContainer = Color(0xFF9F1239);

  /// Soft rose container (Night).
  static const Color secondaryContainerNight = Color(0xFFBE123C);

  // ── Tertiary ───────────────────────────────────────────────────────────────

  /// Mint — success, completion, growth, victory (Day).
  static const Color tertiary = Color(0xFF10B981);

  /// Emerald — success, victory, growth (Night).
  static const Color tertiaryNight = Color(0xFF34D399);

  // ── Warning ────────────────────────────────────────────────────────────────

  /// Amber — reminders, streak break (Day).
  static const Color warning = Color(0xFFF59E0B);

  /// Gold — reminders, warnings (Night).
  static const Color warningNight = Color(0xFFFBBF24);

  // ── Danger / Error ─────────────────────────────────────────────────────────

  /// Red — errors, defeat, broken streak (shared across both modes).
  static const Color error = Color(0xFFEF4444);

  // ── Achievement ────────────────────────────────────────────────────────────

  /// Gold for trophies & badges.
  static const Color gold = Color(0xFFFFD700);

  // ══════════════════════════════════════════════════════════════════
  //  UTILITY
  // ══════════════════════════════════════════════════════════════════

  /// Semi-transparent modal scrim.
  static const Color scrim = Color(0x80000000);

  /// Convenience transparent constant.
  static const Color transparent = Colors.transparent;
}

import 'package:flutter/material.dart';

/// Premium Glass Design System — Animation Tokens
///
/// Implements the timing and curve constants from DESIGN.md §4.1.
///
/// All durations and curves are sourced directly from the design spec.
/// Use these constants everywhere in the app to guarantee motion consistency.
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AppAnimations.cardPressDuration,
///   curve: AppAnimations.cardPressCurve,
/// )
/// ```
abstract final class AppAnimations {
  // ══════════════════════════════════════════════════════════════════
  //  DURATIONS  (DESIGN.md §4.1)
  // ══════════════════════════════════════════════════════════════════

  /// Page transition: slide + fade.  400 ms
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  /// Button press feedback.  150 ms
  static const Duration buttonPressDuration = Duration(milliseconds: 150);

  /// Card press / tap feedback.  200 ms
  static const Duration cardPressDuration = Duration(milliseconds: 200);

  /// Modal / bottom-sheet opening.  300 ms
  static const Duration modalOpenDuration = Duration(milliseconds: 300);

  /// Modal / bottom-sheet closing.  200 ms
  static const Duration modalCloseDuration = Duration(milliseconds: 200);

  /// Progress-bar fill animation.  800 ms
  static const Duration progressBarFillDuration = Duration(milliseconds: 800);

  /// Streak badge idle pulse cycle.  2 000 ms (infinite loop)
  static const Duration streakBadgePulseDuration = Duration(milliseconds: 2000);

  /// Check-in success full sequence.  600 ms
  static const Duration checkinSuccessDuration = Duration(milliseconds: 600);

  /// Number / score counter change.  400 ms
  static const Duration numberCounterDuration = Duration(milliseconds: 400);

  /// WebSocket notification slide-in.  250 ms
  static const Duration wsNotificationDuration = Duration(milliseconds: 250);

  /// WebSocket notification auto-dismiss fade.  200 ms
  static const Duration wsNotificationDismissDuration =
      Duration(milliseconds: 200);

  /// Confetti burst duration.  1 500 ms
  static const Duration confettiDuration = Duration(milliseconds: 1500);

  // ══════════════════════════════════════════════════════════════════
  //  CURVES  (DESIGN.md §4.1)
  // ══════════════════════════════════════════════════════════════════

  /// Page transition out — smooth deceleration.
  static const Curve pageTransitionCurve = Curves.easeOutCubic;

  /// Button press — fast ease-out for snappy feel.
  static const Curve buttonPressCurve = Curves.easeOut;

  /// Card press — gentle ease-out.
  static const Curve cardPressCurve = Curves.easeOut;

  /// Modal open — spring-like, damping ≈ 0.8 (approximated with fastOutSlowIn).
  static const Curve modalOpenCurve = Curves.fastOutSlowIn;

  /// Modal close — simple ease-in.
  static const Curve modalCloseCurve = Curves.easeIn;

  /// Progress bar fill — heavy deceleration for satisfying fill.
  static const Curve progressBarFillCurve = Curves.easeOutQuart;

  /// Streak badge pulse — smooth in-out breathing loop.
  static const Curve streakBadgePulseCurve = Curves.easeInOut;

  /// Check-in success spring.
  static const Curve checkinSuccessCurve = Curves.elasticOut;

  /// Number counter ease-out expo.
  static const Curve numberCounterCurve = Curves.easeOutExpo;

  /// WebSocket notification slide-in.
  static const Curve wsNotificationCurve = Curves.fastOutSlowIn;

  // ══════════════════════════════════════════════════════════════════
  //  SPRING PHYSICS  (for Hero / check-in animations)
  // ══════════════════════════════════════════════════════════════════

  /// Default spring simulation for modal / check-in success.
  /// damping = 0.8, stiffness = 100.
  static SpringDescription get defaultSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 14.0, // ≈ critically damped at 0.8 ratio
  );

  // ══════════════════════════════════════════════════════════════════
  //  KEYFRAME PROFILES  (DESIGN.md §4.2 — descriptive constants)
  // ══════════════════════════════════════════════════════════════════

  // ── Button Press ─────────────────────────────────────────────────────────
  /// Target scale for button-press-down feedback.
  static const double buttonPressScaleDown = 0.96;

  /// Target opacity for button-press-down feedback.
  static const double buttonPressOpacityDown = 0.85;

  // ── Card Press ────────────────────────────────────────────────────────────
  /// Target scale for card-press feedback.
  static const double cardPressScaleDown = 0.98;

  // ── Page Transition ───────────────────────────────────────────────────────
  /// New screen slides in from this fractional X offset.
  static const double pageEnterOffsetX = 1.0; // 100 %

  /// Old screen slides out to this fractional X offset.
  static const double pageExitOffsetX = -0.3; // -30 %

  // ── Check-in Success ─────────────────────────────────────────────────────
  /// Phase 1 — button shrink.
  static const double checkinButtonScaleDown = 0.95;

  /// Phase 2 — button over-shoot expand.
  static const double checkinButtonScaleUp = 1.1;

  // ── Streak Badge Pulse ────────────────────────────────────────────────────
  /// Peak scale during idle breathing animation.
  static const double streakBadgePulseMaxScale = 1.08;

  /// Minimum streak count before pulse engages.
  static const int streakBadgePulseThreshold = 3;

  // ── WS Notification Snackbar auto-dismiss delay ───────────────────────────
  /// Time the notification stays visible before starting its fade-out.
  static const Duration wsNotificationVisibleDuration =
      Duration(seconds: 4);
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  StreakBadge
// ──────────────────────────────────────────────────────────────────────────────

/// Displays the current streak count with a fire icon.
///
/// When [streak] ≥ [pulseThreshold] (default 1) the badge enters an infinite
/// breathing pulse: scale 1.0 → 1.05 and opacity 1.0 → 0.85 over a 2-second
/// `easeInOut` cycle, matching DESIGN.md §4.2 "Streak Badge Pulse".
///
/// When [streak] is 0 or below [pulseThreshold] the badge is rendered at rest
/// (no animation, slightly dimmed opacity).
///
/// ```dart
/// StreakBadge(streak: 7)
/// StreakBadge(streak: 42, size: StreakBadgeSize.large)
/// ```
enum StreakBadgeSize { small, medium, large }

class StreakBadge extends StatefulWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    this.size = StreakBadgeSize.medium,
    this.pulseThreshold = 1,
  });

  /// Current streak count. Zero renders the badge as inactive.
  final int streak;

  /// Visual size variant.
  final StreakBadgeSize size;

  /// Minimum streak value that activates the pulse animation.
  final int pulseThreshold;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak != widget.streak ||
        oldWidget.pulseThreshold != widget.pulseThreshold) {
      _syncAnimation();
    }
  }

  bool get _isActive => widget.streak >= widget.pulseThreshold;

  void _syncAnimation() {
    if (_isActive) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Size tokens ───────────────────────────────────────────────────────────

  double get _iconSize => switch (widget.size) {
    StreakBadgeSize.small  => 14.0,
    StreakBadgeSize.medium => 18.0,
    StreakBadgeSize.large  => 24.0,
  };

  double get _fontSize => switch (widget.size) {
    StreakBadgeSize.small  => 12.0,
    StreakBadgeSize.medium => 15.0,
    StreakBadgeSize.large  => 20.0,
  };

  EdgeInsetsGeometry get _padding => switch (widget.size) {
    StreakBadgeSize.small  => const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    StreakBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    StreakBadgeSize.large  => const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  };

  double get _gapWidth => switch (widget.size) {
    StreakBadgeSize.small  => AppSpacing.xxs,
    StreakBadgeSize.medium => AppSpacing.xs,
    StreakBadgeSize.large  => AppSpacing.sm,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseOpacity = _isActive ? 1.0 : 0.5;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale   = _isActive ? _scale.value   : 1.0;
        final opacity = _isActive ? _opacity.value : baseOpacity;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: _StreakBadgeChrome(
        streak: widget.streak,
        iconSize: _iconSize,
        fontSize: _fontSize,
        padding: _padding,
        gapWidth: _gapWidth,
        isActive: _isActive,
        isDark: isDark,
      ),
    );
  }
}

// ── Chrome (static layer, not rebuilt per-tick) ────────────────────────────

class _StreakBadgeChrome extends StatelessWidget {
  const _StreakBadgeChrome({
    required this.streak,
    required this.iconSize,
    required this.fontSize,
    required this.padding,
    required this.gapWidth,
    required this.isActive,
    required this.isDark,
  });

  final int streak;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double gapWidth;
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: isActive
            ? AppGradients.streak  // fire: yellow → orange → red-orange
            : null,
        color: isActive
            ? null
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withAlpha(0x40),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: iconSize,
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          SizedBox(width: gapWidth),
          Text(
            '$streak',
            style: AppTypography.button.copyWith(
              fontSize: fontSize,
              color: isActive
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  NumberCounter
// ──────────────────────────────────────────────────────────────────────────────

/// Animated number display that cross-fades between old and new values.
///
/// When [value] changes:
/// 1. The old number slides **upward** and fades out.
/// 2. The new number slides **in from below** and fades in.
///
/// Both transitions run simultaneously over **400 ms** (`easeOutExpo`),
/// matching DESIGN.md §4.1 "Number counter change".
///
/// ```dart
/// NumberCounter(
///   value: streak,
///   style: AppTypography.numeralHero,
/// )
/// ```
class NumberCounter extends StatefulWidget {
  const NumberCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutExpo,
    this.prefix,
    this.suffix,
  });

  final int value;

  /// Text style for the number. Defaults to [AppTypography.numeralMedium].
  final TextStyle? style;

  final Duration duration;
  final Curve curve;

  /// Optional string prepended to the number (e.g. "#").
  final String? prefix;

  /// Optional string appended to the number (e.g. " pts").
  final String? suffix;

  @override
  State<NumberCounter> createState() => _NumberCounterState();
}

class _NumberCounterState extends State<NumberCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _t; // 0 → 1 over duration

  late int _displayedValue;   // the "current" shown value (new)
  late int _previousValue;    // the outgoing value

  @override
  void initState() {
    super.initState();
    _displayedValue = widget.value;
    _previousValue  = widget.value;

    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _ctrl, curve: widget.curve);
  }

  @override
  void didUpdateWidget(NumberCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue  = oldWidget.value;
      _displayedValue = widget.value;
      _ctrl.forward(from: 0.0);
    }

    if (oldWidget.duration != widget.duration) {
      _ctrl.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(int v) =>
      '${widget.prefix ?? ''}$v${widget.suffix ?? ''}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = widget.style ??
        AppTypography.numeralMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        );

    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value; // 0.0 → 1.0

        // Slide distance: half the approximate line height
        final slideDistance = (style.fontSize ?? 16) * (style.height ?? 1.2) * 0.6;

        return SizedBox(
          // Fix the height to the tallest of the two frames to prevent jumping
          height: (style.fontSize ?? 16) * (style.height ?? 1.2),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            children: [
              // ── Outgoing (old) ─────────────────────────────────────────
              if (t < 1.0)
                Transform.translate(
                  offset: Offset(0, -slideDistance * t),
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Text(_format(_previousValue), style: style),
                  ),
                ),

              // ── Incoming (new) ─────────────────────────────────────────
              Transform.translate(
                offset: Offset(0, slideDistance * (1.0 - t)),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(_format(_displayedValue), style: style),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

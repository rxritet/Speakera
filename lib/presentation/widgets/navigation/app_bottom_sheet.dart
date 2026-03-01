import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  AppBottomSheet
// ──────────────────────────────────────────────────────────────────────────────

/// Стеклянный модальный боттом-шит с пружинной анимацией и хэндлом.
///
/// ```dart
/// await AppBottomSheet.show(
///   context: context,
///   builder: (ctx) => Column(children: [Text('Hello')]),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
  });

  final Widget child;

  /// Внутренние отступы. По умолчанию — base со всех сторон.
  final EdgeInsetsGeometry? padding;

  /// Показывать хэндл (по умолчанию `true`).
  final bool showHandle;

  // ── Статический вызов ───────────────────────────────────────────────────

  /// Открывает шит с пружинной анимацией.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool showHandle = true,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      _SpringBottomSheetRoute<T>(
        builder: (ctx) => AppBottomSheet(
          showHandle: showHandle,
          padding: padding,
          child: builder(ctx),
        ),
        barrierDismissible: barrierDismissible,
        isScrollControlled: isScrollControlled,
      ),
    );
  }

  // ── Сборка ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Цвета стекла как у GlassCardVariant.elevated.
    final bgColor = isDark
        ? AppColors.darkGlassBackground
        : AppColors.lightGlassBackground;
    final borderColor = isDark
        ? AppColors.darkGlassBorder.withAlpha(0x14)   // 8%
        : AppColors.lightGlassBorder.withAlpha(0x42); // 26%

    // Тень и свечение primary в тёмной теме.
    final boxShadows = [
      // Основная тень.
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 0x52 : 0x30),
        blurRadius: isDark ? 40 : 20,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
      if (isDark)
        BoxShadow(
          color: AppColors.primaryNight.withAlpha(0x40),
          blurRadius: 20,
          spreadRadius: 0,
        ),
    ];

    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(
          AppSpacing.base,
          showHandle ? AppSpacing.lg : AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base + MediaQuery.of(context).viewInsets.bottom,
        );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXxl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: boxShadows,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const SizedBox(height: AppSpacing.sm),
                _HandleBar(isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
              ],
              Padding(padding: resolvedPadding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Хэндл ───────────────────────────────────────────────────────────────────

class _HandleBar extends StatelessWidget {
  const _HandleBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkTextMuted.withAlpha(0x52)
            : AppColors.lightTextMuted.withAlpha(0x80),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  Маршрут с пружинной физикой
// ──────────────────────────────────────────────────────────────────────────────

/// [PopupRoute] с пружинной анимацией открытия и ease-in закрытием.
class _SpringBottomSheetRoute<T> extends PopupRoute<T> {
  _SpringBottomSheetRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.isScrollControlled = false,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;

  @override
  final bool barrierDismissible;

  @override
  String? get barrierLabel => 'BottomSheet';

  @override
  Color get barrierColor => AppColors.scrim;

  // Длительность используется только при закрытии — открытие управляется пружиной.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

  @override
  Duration get reverseTransitionDuration =>
      AppAnimations.modalCloseDuration; // 200 мс

  // ── Пружинная анимация открытия ──────────────────────────────────────────

  @override
  TickerFuture didPush() {
    // super требуется для @mustCallSuper; затем заменяем анимацию на пружину.
    super.didPush();
    return controller!.animateWith(
      SpringSimulation(
        AppAnimations.defaultSpring, // масса=1, жёсткость=100, демпфирование=14
        0.0,
        1.0,
        0.0,
      ),
    );
  }

  // ── Анимация перехода (слайд снизу) ──────────────────────────────────────

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Слайд снизу вверх — прямое значение пружины без дополнительных кривых.
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(animation);

    // Плавное появление за первые 40% анимации.
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      ),
    );
  }
}

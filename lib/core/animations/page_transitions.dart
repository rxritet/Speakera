import 'package:flutter/material.dart';

import 'app_animations.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  AppPageRoute
// ──────────────────────────────────────────────────────────────────────────────

/// Маршрут с анимацией слайда и затуханием по DESIGN.md §4.1.
///
/// Новый экран въезжает справа (+100 % X), старый уходит влево (−0.3 X)
/// с затемнением до 70 %. Длительность — 400 мс, кривая — easeOutCubic.
///
/// ```dart
/// Navigator.of(context).push(
///   AppPageRoute(builder: (ctx) => DetailScreen()),
/// );
/// ```
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration: AppAnimations.pageTransitionDuration,   // 400 мс
          reverseTransitionDuration:
              AppAnimations.pageTransitionDuration,                    // 400 мс
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: _buildTransitions,
        );

  // ── Transition builder (static so it can be reused by generateRoute) ─────

  static Widget _buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // ── Entering page ────────────────────────────────────────────────────

    // Slide: 100 % X → 0 % X (right edge → centre)
    final enterSlide = Tween<Offset>(
      begin: Offset(AppAnimations.pageEnterOffsetX, 0.0),  // +1.0
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppAnimations.pageTransitionCurve,           // easeOutCubic
      ),
    );

    // Fade: 0 → 1 over the first 60 % of the transition
    final enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // ── Leaving page (secondary animation) ──────────────────────────────

    // Slide: 0 % X → −30 % X (centre → slight left)
    final exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(AppAnimations.pageExitOffsetX, 0.0),     // -0.3
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppAnimations.pageTransitionCurve,
      ),
    );

    // Fade: 1 → 0.7 — keeps previous screen visible but dimmed
    final exitFade = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppAnimations.pageTransitionCurve,
      ),
    );

    return SlideTransition(
      position: exitSlide,
      child: FadeTransition(
        opacity: exitFade,
        child: SlideTransition(
          position: enterSlide,
          child: FadeTransition(
            opacity: enterFade,
            child: child,
          ),
        ),
      ),
    );
  }

  // ── Генератор именованных маршрутов ──────────────────────────────────────────

  /// Замена [MaterialApp.onGenerateRoute] — оборачивает билдеры в [AppPageRoute].
  ///
  /// ```dart
  /// MaterialApp(
  ///   onGenerateRoute: AppPageRoute.generateRoute({
  ///     '/home':   (ctx) => HomeScreen(),
  ///     '/detail': (ctx) => DetailScreen(),
  ///   }),
  /// )
  /// ```
  static RouteFactory generateRoute(
      Map<String, WidgetBuilder> routes) {
    return (settings) {
      final builder = routes[settings.name];
      if (builder == null) return null;
      return AppPageRoute(builder: builder, settings: settings);
    };
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  AppSharedAxisTransition
// ──────────────────────────────────────────────────────────────────────────────

/// Вспомогательный класс для использования стандартного перехода
/// в [AnimatedSwitcher] и аналогичных виджетах.
abstract final class AppSharedAxisTransition {
  AppSharedAxisTransition._();

  /// Горизонтальный переход (cовпадает с [AppPageRoute]).
  static Widget horizontal(Widget child, Animation<double> animation) {
    final slide = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppAnimations.pageTransitionCurve,
      ),
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: child),
    );
  }

  /// Вертикальный переход — подходит для экранов в стиле модального окна.
  static Widget vertical(Widget child, Animation<double> animation) {
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppAnimations.pageTransitionCurve,
      ),
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: child),
    );
  }
}

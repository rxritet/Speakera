/// Premium Glass Design System — Spacing & Sizing Scale
///
/// Based on a 4 pt base grid. Use semantic names instead of raw numbers
/// to keep the design consistent across the codebase.
abstract final class AppSpacing {
  // ── Base spacing (4 pt grid) ─────────────────────────────────────────────

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  // ── Semantic spacing ─────────────────────────────────────────────────────

  /// Standard inner padding for cards and containers.
  static const double cardPadding = xl; // 24

  /// Padding for screen-level horizontal gutters.
  static const double screenPadding = base; // 16

  /// Gap between stacked list/card items.
  static const double itemGap = md; // 12

  /// Gap between tightly related inline elements.
  static const double inlineGap = sm; // 8

  /// Gap between form fields.
  static const double formFieldGap = base; // 16

  /// Vertical section separator.
  static const double sectionGap = xxl; // 32

  // ── Border radii ──────────────────────────────────────────────────────────

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0; // pill / circular

  /// Standard card corner radius.
  static const double cardRadius = radiusXl; // 20

  /// Button corner radius.
  static const double buttonRadius = radiusLg; // 16

  // ── Icon sizes ────────────────────────────────────────────────────────────

  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Avatar / image sizes ─────────────────────────────────────────────────

  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 80.0;

  // ── Component heights ─────────────────────────────────────────────────────

  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
}

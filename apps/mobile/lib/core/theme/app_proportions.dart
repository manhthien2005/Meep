// No dart:ui import needed — all values are plain doubles.

/// Maps Figma proportions (frame 412×917) to runtime sizes.
abstract final class AppProportions {
  static const double figmaFrameWidth = 412.0;
  static const double figmaFrameHeight = 917.0;

  // ── Camera / Photo ────────────────────────────────────────────────────────

  /// Square photo size. Width-driven (6 px inset each side) but capped by the
  /// available height so the square + controls below never overflow on short
  /// or narrow screens. [screenH] is the full screen height; we reserve room
  /// for the top bar, dots, action bar and bottom rows (~340 px of chrome).
  static const double _photoSideInset = 12;
  static const double _verticalChromeReserve = 340;
  static double photoSize(double screenW, [double? screenH]) {
    final byWidth = screenW - _photoSideInset;
    if (screenH == null) return byWidth;
    final byHeight = screenH - _verticalChromeReserve;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  /// Gap between the caption dots row and the action bar below it.
  /// Figma intent: 4–6 px — keep tight.
  static const double dotsToBarGap = 5;

  /// Pill bottom margin inside photo. Figma: 29/400 = 7.25% of photo size.
  static const double pillBottomRatio = 29 / 400;
  static double pillBottomInPhoto(double photoSize) =>
      photoSize * pillBottomRatio;

  // ── Note pill ─────────────────────────────────────────────────────────────

  /// Pill total width. Figma: 126/412 → 30.6%.
  static const double pillWidthRatio = 126 / figmaFrameWidth;
  static double pillWidth(double screenW) => screenW * pillWidthRatio;

  /// Pill chrome = icon(22) + iconGap(6) + paddingH(15×2) = 58.
  static const double pillChrome = 58.0;

  /// Font size inside pill. Figma: 14px on 412, bumped to 15 for legibility.
  static const double pillFontRatio = 15 / figmaFrameWidth;
  static double pillFontSize(double screenW) => screenW * pillFontRatio;

  // ── Capture Button ────────────────────────────────────────────────────────

  static const double captureOuterRatio = 79 / figmaFrameWidth;
  static const double captureInnerToOuterRatio = 69 / 79;
  static const double captureRingWidth = 3;

  static double captureOuter(double screenW) => screenW * captureOuterRatio;
  static double captureInner(double screenW) =>
      captureOuter(screenW) * captureInnerToOuterRatio;

  // ── Side icons ────────────────────────────────────────────────────────────

  static const double sideIconRatio = 36 / figmaFrameWidth;
  static double sideIconSize(double screenW) => screenW * sideIconRatio;

  static const double captureRowGapRatio = 60 / figmaFrameWidth;
  static double captureRowGap(double screenW) => screenW * captureRowGapRatio;

  // ── Caption dots ──────────────────────────────────────────────────────────

  // Figma 442:2354 — dots on 412px frame
  static const double _dotActiveSizeFigma = 8;
  static const double _dotSpacingFigma =
      8; // gap between dots (16px center-to-center - 8px dot)
  static const double _dotsTopGapFigma = 16;

  static const double dotActiveRatio = _dotActiveSizeFigma / figmaFrameWidth;
  static const double dotSpacingRatio = _dotSpacingFigma / figmaFrameWidth;
  static const double dotsTopGapRatio = _dotsTopGapFigma / figmaFrameWidth;

  static double dotActiveSize(double screenW) => screenW * dotActiveRatio;
  static double dotSpacing(double screenW) => screenW * dotSpacingRatio;
  static double dotsTopGap(double screenW) => screenW * dotsTopGapRatio;

  // ── Audience row ─────────────────────────────────────────────────────────

  static const double audienceAvatarRatio = 30 / figmaFrameWidth;
  static double audienceAvatarSize(double screenW) =>
      screenW * audienceAvatarRatio;

  // ── Modal sheet ───────────────────────────────────────────────────────────

  static const double captionModalHeightRatio = 528 / 917;
  static const double shareModalHeightRatio = 265 / 917;

  // ── Grid view ─────────────────────────────────────────────────────────────

  static const double gridGap = 3;
  static const int gridColumns = 3;
  static const double gridHPaddingRatio = 10 / figmaFrameWidth;
  static double gridHPadding(double screenW) => screenW * gridHPaddingRatio;

  // ── Dual camera PiP ───────────────────────────────────────────────────────

  /// PiP (front camera) size as ratio of photo frame. Figma: ~120/400 = 30%.
  static const double pipSizeRatio = 0.30;

  /// PiP margin from top-right corner. Figma: 12px on 400px frame.
  static const double pipMarginRatio = 12 / 400;

  /// PiP corner radius. Figma: 16px.
  static const double pipCornerRadius = 16;

  static double pipSize(double photoSize) => photoSize * pipSizeRatio;
  static double pipMargin(double photoSize) => photoSize * pipMarginRatio;
}

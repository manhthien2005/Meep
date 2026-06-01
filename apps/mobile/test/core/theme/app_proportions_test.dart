import 'package:flutter_test/flutter_test.dart';

import 'package:meep/core/theme/app_proportions.dart';

void main() {
  // Reference device width used across the design system (Figma frame 412).
  const w = 412.0;

  group('AppProportions capture/preview bar sizing', () {
    test('capture button bumped ~15% over Figma 79px', () {
      // 92/412 * 412 = 92px on the reference frame.
      expect(AppProportions.captureOuter(w), closeTo(92, 0.5));
    });

    test('side icon bumped ~15% over Figma 36px', () {
      expect(AppProportions.sideIconSize(w), closeTo(44, 0.5));
    });

    test('side icon stays smaller than the capture button', () {
      expect(
        AppProportions.sideIconSize(w),
        lessThan(AppProportions.captureOuter(w)),
      );
    });

    test('inner circle keeps Figma 69/79 ratio of the (larger) outer', () {
      expect(
        AppProportions.captureInner(w),
        closeTo(AppProportions.captureOuter(w) * 69 / 79, 0.5),
      );
    });

    test('the whole bar row fits within screen width', () {
      // center + 2 side buttons + 2 gaps + 6px padding each side must not
      // exceed the frame width, or the Row overflows.
      final rowWidth = AppProportions.captureOuter(w) +
          AppProportions.sideIconSize(w) * 2 +
          AppProportions.captureRowGap(w) * 2 +
          12; // 6px horizontal padding each side
      expect(rowWidth, lessThanOrEqualTo(w));
    });
  });
}

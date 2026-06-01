import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/core/theme/app_proportions.dart';
import 'package:meep/features/feed/presentation/capture_action_bar.dart';
import 'package:meep/shared/widgets/app_camera_button.dart';
import 'package:meep/shared/widgets/app_circle_icon_button.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(412, 917)),
          child: Scaffold(body: Center(child: w)),
        ),
      );

  final expectedCenter = AppProportions.captureOuter(412);
  final expectedSide = AppProportions.sideIconSize(412);

  group('CaptureActionBar — camera config', () {
    Widget cameraBar() => wrap(
          CaptureActionBar(
            config: CameraBarConfig(
              onCapture: () {},
              onAlbum: () {},
              onFlip: () {},
              isCapturing: false,
            ),
          ),
        );

    testWidgets('capture button uses the bumped center size', (tester) async {
      await tester.pumpWidget(cameraBar());
      final btn = tester.widget<AppCameraButton>(find.byType(AppCameraButton));
      expect(btn.size, closeTo(expectedCenter, 0.5));
    });

    testWidgets('album side icon uses the bumped side size', (tester) async {
      await tester.pumpWidget(cameraBar());
      final box = tester.getSize(find.byIcon(Icons.image_outlined).first);
      // _SideBtn wraps the icon in a size×size SizedBox.
      expect(box.width, closeTo(expectedSide, 0.5));
    });
  });

  group('CaptureActionBar — preview config', () {
    Widget previewBar({bool canSend = true}) => wrap(
          CaptureActionBar(
            config: PreviewBarConfig(
              onCancel: () {},
              onSend: () {},
              onSparkles: () {},
              isUploading: false,
              canSend: canSend,
            ),
          ),
        );

    testWidgets('send button uses the bumped center size', (tester) async {
      await tester.pumpWidget(previewBar());
      final send = tester.widget<AppCircleIconButton>(
        find.widgetWithIcon(AppCircleIconButton, Icons.send),
      );
      expect(send.size, closeTo(expectedCenter, 0.5));
    });

    testWidgets('cancel + sparkles use the bumped side size', (tester) async {
      await tester.pumpWidget(previewBar());
      final cancel = tester.widget<AppCircleIconButton>(
        find.widgetWithIcon(AppCircleIconButton, Icons.close),
      );
      final sparkles = tester.widget<AppCircleIconButton>(
        find.widgetWithIcon(AppCircleIconButton, Icons.auto_awesome),
      );
      expect(cancel.size, closeTo(expectedSide, 0.5));
      expect(sparkles.size, closeTo(expectedSide, 0.5));
    });
  });
}

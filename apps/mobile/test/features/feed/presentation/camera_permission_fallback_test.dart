import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/camera_state.dart';
import 'package:meep/features/feed/presentation/widgets/camera_permission_fallback.dart';

/// Fake notifier — trả state cố định, override retry() để không gọi camera
/// plugin thật (availableCameras throws ngoài integration test).
class _FakeCameraController extends AppCameraController {
  _FakeCameraController(this._initial);

  final CameraState _initial;
  int retryCalls = 0;

  @override
  CameraState build() => _initial;

  @override
  Future<void> retry() async {
    retryCalls++;
  }
}

void main() {
  Future<_FakeCameraController> pump(
    WidgetTester tester,
    CameraState state,
  ) async {
    late _FakeCameraController fake;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appCameraControllerProvider.overrideWith(() {
            fake = _FakeCameraController(state);
            return fake;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CameraPermissionFallback()),
        ),
      ),
    );
    return fake;
  }

  testWidgets('permission denied → message VN + "Thử lại" + "Mở Cài đặt"',
      (tester) async {
    await pump(
      tester,
      const CameraState(
        permissionState: CameraPermissionState.denied,
        error: 'Meep cần quyền truy cập máy ảnh để chụp ảnh',
      ),
    );

    expect(
      find.text('Meep cần quyền truy cập máy ảnh để chụp ảnh'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Mở Cài đặt'), findsOneWidget);
  });

  testWidgets('non-permission error → "Thử lại" nhưng KHÔNG có "Mở Cài đặt"',
      (tester) async {
    await pump(
      tester,
      const CameraState(error: 'Không tìm thấy máy ảnh trên thiết bị'),
    );

    expect(find.text('Không tìm thấy máy ảnh trên thiết bị'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Mở Cài đặt'), findsNothing);
  });

  testWidgets('tap "Thử lại" → gọi controller.retry()', (tester) async {
    final fake = await pump(
      tester,
      const CameraState(
        permissionState: CameraPermissionState.denied,
        error: 'Meep cần quyền truy cập máy ảnh để chụp ảnh',
      ),
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(fake.retryCalls, 1);
  });
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_camera_controller.freezed.dart';
part 'app_camera_controller.g.dart';

@freezed
class CameraState with _$CameraState {
  const factory CameraState({
    @Default(false) bool isInitialized,
    @Default(false) bool isFrontCamera,
    @Default(false) bool flashEnabled,
    @Default(false) bool isCapturing,
  }) = _CameraState;
}

/// Camera controller — named AppCameraController to avoid conflict
/// with the `camera` package's CameraController.
@riverpod
class AppCameraController extends _$AppCameraController {
  @override
  CameraState build() => const CameraState();

  Future<void> initialize() async {
    // TODO(FE/T5/KhoaLND): initialize camera
    throw UnimplementedError('initialize — TODO: FE/T5/KhoaLND');
  }

  Future<String?> capture() async {
    // TODO(FE/T6/KhoaLND): capture photo, return local path
    throw UnimplementedError('capture — TODO: FE/T6/KhoaLND');
  }

  void toggleCamera() {
    // TODO(FE/T7/KhoaLND): flip front/back
    throw UnimplementedError('toggleCamera — TODO: FE/T7/KhoaLND');
  }

  void toggleFlash() {
    // TODO(FE/T8/KhoaLND): toggle flash
    throw UnimplementedError('toggleFlash — TODO: FE/T8/KhoaLND');
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_state.freezed.dart';

enum CameraMode { single, dual }

enum CameraLens { back, front }

@freezed
class CameraState with _$CameraState {
  const factory CameraState({
    @Default(CameraMode.single) CameraMode mode,
    @Default(false) bool isInitialized,
    @Default(false) bool isFrontCamera, // Used in single mode only
    @Default(false) bool flashEnabled,
    @Default(false) bool isCapturing,
    // Dual mode fields
    @Default(CameraLens.back) CameraLens activeLens,
    String? backPhotoPath,
    String? frontPhotoPath,
    String? error,
  }) = _CameraState;
}

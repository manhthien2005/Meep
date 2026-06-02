import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/application/camera_state.dart';

part 'app_camera_controller.g.dart';

/// Named AppCameraController to avoid conflict with camera package's CameraController.
@riverpod
class AppCameraController extends _$AppCameraController {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];

  @override
  CameraState build() {
    ref.onDispose(() => _cameraCtrl?.dispose());
    return const CameraState();
  }

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        state = state.copyWith(error: 'No camera found');
        return;
      }

      await _initializeCamera(
        state.mode == CameraMode.single
            ? (state.isFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back)
            : (state.activeLens == CameraLens.back
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setMode(CameraMode mode) async {
    if (state.mode == mode) return;
    final wasInit = state.isInitialized;
    await _disposeController();
    state = state.copyWith(
      mode: mode,
      isInitialized: false,
      isFrontCamera: mode == CameraMode.dual ? false : state.isFrontCamera,
      activeLens: mode == CameraMode.dual ? CameraLens.front : CameraLens.back,
      backPhotoPath: mode == CameraMode.dual ? state.backPhotoPath : null,
      frontPhotoPath: mode == CameraMode.dual ? state.frontPhotoPath : null,
    );
    if (wasInit) await initialize();
  }

  Future<void> setActiveLens(CameraLens lens) async {
    if (state.mode != CameraMode.dual) return;
    await _switchToLens(lens);
  }

  Future<void> _initializeCamera(CameraLensDirection direction) async {
    final camera = _cameraForLens(_cameras, direction);
    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    _cameraCtrl = ctrl;
    final minZoom = await ctrl.getMinZoomLevel();
    final maxZoom = await ctrl.getMaxZoomLevel();
    state = state.copyWith(
      isInitialized: true,
      error: null,
      minZoom: minZoom,
      maxZoom: maxZoom,
      zoomLevel: 1.0,
    );
    await _applyFlashForActiveLens(direction);
  }

  /// Apply the user's flashEnabled preference to the live controller, but only
  /// if the active lens is back — front-facing capture doesn't trigger the
  /// physical flash, so we keep that lens at FlashMode.off regardless.
  Future<void> _applyFlashForActiveLens(CameraLensDirection direction) async {
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final wantFlash =
        state.flashEnabled && direction == CameraLensDirection.back;
    await ctrl.setFlashMode(wantFlash ? FlashMode.always : FlashMode.off);
  }

  /// Returns local file path on success, null on failure or double-tap.
  Future<String?> capture() async {
    if (_cameraCtrl == null ||
        !_cameraCtrl!.value.isInitialized ||
        state.isCapturing) {
      return null;
    }

    // Single mode: normal capture
    if (state.mode == CameraMode.single) {
      state = state.copyWith(isCapturing: true);
      try {
        final file = await _cameraCtrl!.takePicture();
        return file.path;
      } catch (e) {
        debugPrint('capture error: $e');
        return null;
      } finally {
        state = state.copyWith(isCapturing: false);
      }
    }

    // Dual mode: capture active lens, then switch to the other
    return _captureInDualMode();
  }

  Future<String?> _captureInDualMode() async {
    state = state.copyWith(isCapturing: true);
    try {
      final file = await _cameraCtrl!.takePicture();
      final path = file.path;

      // Save photo to the appropriate slot
      if (state.activeLens == CameraLens.back) {
        state = state.copyWith(backPhotoPath: path);
        // Default sequence: front first, then back.
        if (state.frontPhotoPath == null) {
          await _switchToLens(CameraLens.front);
        }
      } else {
        state = state.copyWith(frontPhotoPath: path);
        // Default sequence: front first, then back.
        if (state.backPhotoPath == null) {
          await _switchToLens(CameraLens.back);
        }
      }

      return path;
    } catch (e) {
      debugPrint('dual capture error: $e');
      return null;
    } finally {
      state = state.copyWith(isCapturing: false);
    }
  }

  /// Retake a specific photo in dual mode
  Future<void> retakePhoto(CameraLens lens) async {
    if (state.mode != CameraMode.dual) return;

    // Clear the photo and switch to that lens
    if (lens == CameraLens.back) {
      state = state.copyWith(backPhotoPath: null);
    } else {
      state = state.copyWith(frontPhotoPath: null);
    }

    await _switchToLens(lens);
  }

  Future<void> _switchToLens(CameraLens lens) async {
    if (state.activeLens == lens && state.isInitialized) return;

    await _disposeController();
    state = state.copyWith(activeLens: lens, isInitialized: false);

    await _initializeCamera(
      lens == CameraLens.back
          ? CameraLensDirection.back
          : CameraLensDirection.front,
    );
  }

  /// Switch between single and dual camera modes
  Future<void> switchMode() async {
    final newMode =
        state.mode == CameraMode.single ? CameraMode.dual : CameraMode.single;

    // Clear dual mode photos when switching to single
    if (newMode == CameraMode.single) {
      state = state.copyWith(
        mode: newMode,
        backPhotoPath: null,
        frontPhotoPath: null,
        activeLens: CameraLens.back,
      );
    } else {
      // Switching to dual mode: start with back camera
      state = state.copyWith(
        mode: newMode,
        activeLens: CameraLens.back,
        backPhotoPath: null,
        frontPhotoPath: null,
      );
    }

    // Reinitialize camera for the new mode
    await _disposeController();
    state = state.copyWith(isInitialized: false);
    await initialize();
  }

  /// Check if both photos are captured in dual mode
  bool get hasBothPhotos =>
      state.backPhotoPath != null && state.frontPhotoPath != null;

  /// Toggle camera in single mode only
  Future<void> toggleCamera() async {
    if (state.mode != CameraMode.single) return;
    final wasInit = state.isInitialized;
    await _disposeController();
    final flippingToFront = !state.isFrontCamera;
    state = state.copyWith(
      isFrontCamera: flippingToFront,
      isInitialized: false,
      // Flash is a back-lens-only feature; flipping to front turns it off so
      // the UI button reflects what the next capture will actually do.
      flashEnabled: flippingToFront ? false : state.flashEnabled,
    );
    if (wasInit) await initialize();
  }

  /// Toggle flash for back-lens capture. Front lens is always FlashMode.off —
  /// see [_applyFlashForActiveLens]. State always tracks user intent so the
  /// preference is restored when switching back to a back lens.
  Future<void> toggleFlash() async {
    final next = !state.flashEnabled;
    state = state.copyWith(flashEnabled: next);
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final activeDirection = ctrl.description.lensDirection;
    await _applyFlashForActiveLens(activeDirection);
  }

  /// Pinch-to-zoom entry point. Clamps to the live lens's reported range so
  /// callers can multiply by a raw scale delta without bothering with bounds.
  /// State updates synchronously and the native zoom call is fire-and-forget —
  /// awaiting it would queue per-frame onScaleUpdate callbacks behind the
  /// platform channel and make the pinch feel laggy.
  void setZoom(double level) {
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final clamped = level.clamp(state.minZoom, state.maxZoom);
    if (clamped == state.zoomLevel) return;
    state = state.copyWith(zoomLevel: clamped);
    unawaited(ctrl.setZoomLevel(clamped));
  }

  /// Drop the frozen back/front photos kept on the dual viewfinder after a
  /// successful capture. Called once we've pushed the preview route so the
  /// camera screen is clean if the user navigates back.
  Future<void> clearDualPhotos() async {
    if (state.mode != CameraMode.dual) return;
    state = state.copyWith(backPhotoPath: null, frontPhotoPath: null);
    if (state.activeLens != CameraLens.back) {
      await _switchToLens(CameraLens.back);
    }
  }

  void stopPreview() => _cameraCtrl?.pausePreview();
  void resumePreview() => _cameraCtrl?.resumePreview();

  CameraController? get cameraController => _cameraCtrl;

  Future<void> _disposeController() async {
    await _cameraCtrl?.dispose();
    _cameraCtrl = null;
    state = state.copyWith(isInitialized: false);
  }

  CameraDescription _cameraForLens(
    List<CameraDescription> cameras,
    CameraLensDirection direction,
  ) =>
      cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );
}

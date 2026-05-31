class CapturePreviewArgs {
  const CapturePreviewArgs.single({
    required this.imagePath,
  })  : backPhotoPath = null,
        frontPhotoPath = null,
        activePrimaryLensIsFront = false;

  const CapturePreviewArgs.dual({
    required this.backPhotoPath,
    required this.frontPhotoPath,
    required this.activePrimaryLensIsFront,
  }) : imagePath = null;

  final String? imagePath;
  final String? backPhotoPath;
  final String? frontPhotoPath;
  final bool activePrimaryLensIsFront;

  bool get isDual => backPhotoPath != null && frontPhotoPath != null;
}

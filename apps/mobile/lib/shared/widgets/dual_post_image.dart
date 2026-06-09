import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_proportions.dart';

/// Dual-camera PiP layout: one lens fills the frame, the other is shown as a
/// small top-right preview. Back camera is primary by default.
class DualPostImage extends StatefulWidget {
  const DualPostImage({
    super.key,
    required this.backImageUrl,
    required this.frontImageUrl,
    this.initialPrimaryIsFront = false,
    this.enableSwapOnTap = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String backImageUrl;
  final String frontImageUrl;
  final bool initialPrimaryIsFront;
  final bool enableSwapOnTap;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  State<DualPostImage> createState() => _DualPostImageState();
}

class _DualPostImageState extends State<DualPostImage> {
  late bool _primaryIsFront;

  @override
  void initState() {
    super.initState();
    _primaryIsFront = widget.initialPrimaryIsFront;
  }

  @override
  void didUpdateWidget(DualPostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backImageUrl != widget.backImageUrl ||
        oldWidget.frontImageUrl != widget.frontImageUrl ||
        oldWidget.initialPrimaryIsFront != widget.initialPrimaryIsFront) {
      _primaryIsFront = widget.initialPrimaryIsFront;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary =
        _primaryIsFront ? widget.frontImageUrl : widget.backImageUrl;
    final secondary =
        _primaryIsFront ? widget.backImageUrl : widget.frontImageUrl;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth;
        final pipSize = AppProportions.pipSize(frameSize);
        final pipMargin = AppProportions.pipMargin(frameSize);

        return Stack(
          children: [
            Positioned.fill(
              child: _NetworkImage(
                url: primary,
                memCacheWidth: widget.memCacheWidth,
                memCacheHeight: widget.memCacheHeight,
              ),
            ),
            Positioned(
              top: pipMargin,
              right: pipMargin,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppProportions.pipCornerRadius),
                child: SizedBox(
                  width: pipSize,
                  height: pipSize,
                  child: _NetworkImage(
                    url: secondary,
                    memCacheWidth: widget.memCacheWidth,
                    memCacheHeight: widget.memCacheHeight,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!widget.enableSwapOnTap) return content;
    return Semantics(
      button: true,
      label: 'Đổi ảnh cam trước/sau',
      child: GestureDetector(
        onTap: () => setState(() => _primaryIsFront = !_primaryIsFront),
        child: content,
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.url,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String url;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const ColoredBox(
        color: AppColors.bw800,
        child: Center(
          child: Icon(Icons.broken_image, color: AppColors.bw600),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (_, __) => const ColoredBox(color: AppColors.bw800),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.bw800,
        child: Icon(Icons.broken_image, color: AppColors.bw600),
      ),
    );
  }
}

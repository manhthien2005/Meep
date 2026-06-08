import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

const _cSheetBg = Color(0xFF252627);
const _cButtonFill = Color(0xFF394041);

/// Bottom sheet "Chia sẻ đến..." cho ảnh post.
///
/// Figma: Profile `573:3648` / Streak `633:3546` — cùng layout.
/// Reused bởi Profile module + Streak module.
///
/// Logic:
/// - **Chia sẻ** → `Share.shareUri(post.coverImageUrl)` native
/// - **Messenger / Instagram** → TODO post-MVP (cần add `url_launcher` package — leader-gated)
/// - **Tin nhắn** → disabled M3 (Chat module Tier 1 sau)
/// - **Lưu** → `http.get(coverImageUrl)` + `Gal.putImageBytes`
/// - **Xoá** → chỉ hiện khi `isAuthor` → `postController.deletePost`
class SharePhotoSheet extends ConsumerWidget {
  const SharePhotoSheet({
    super.key,
    required this.post,
    required this.isAuthor,
  });

  final Post post;
  final bool isAuthor;

  static Future<void> show(
    BuildContext context, {
    required Post post,
    required bool isAuthor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SharePhotoSheet(post: post, isAuthor: isAuthor),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 265,
      child: AppBottomSheet(
        backgroundColor: _cSheetBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text(
              'Chia sẻ đến...',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 24 / 18,
                color: AppColors.bw100,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ShareTarget(
                    iconAsset: 'assets/icons/ic_share_outline.svg',
                    outerColor: const Color(0xFF656c6d),
                    innerColor: const Color(0xFF656c6d),
                    label: 'Chia sẻ',
                    isIcon: true,
                    onTap: () => _onNativeShare(context),
                  ),
                  _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_messenger.svg',
                    outerColor: const Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Messenger',
                    isIcon: false,
                    onTap: () => _onMessengerShare(context),
                  ),
                  _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_instagram.svg',
                    outerColor: const Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Instagram',
                    isIcon: false,
                    onTap: () => _onInstagramShare(context),
                  ),
                  const _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_sms.svg',
                    outerColor: Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Tin nhắn',
                    isIcon: false,
                    enabled: false, // M3: Chat module disabled
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      iconAsset: 'assets/icons/ic_download.svg',
                      label: 'Lưu',
                      onTap: () => _onSave(context),
                    ),
                  ),
                  if (isAuthor) ...[
                    const SizedBox(width: 19),
                    Expanded(
                      child: _ActionButton(
                        iconAsset: 'assets/icons/ic_trash.svg',
                        label: 'Xoá',
                        onTap: () => _onDelete(context, ref),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _onNativeShare(BuildContext context) async {
    final url = post.coverImageUrl;
    Navigator.of(context).pop();
    if (url.isEmpty) return;
    await Share.shareUri(Uri.parse(url));
  }

  // TODO(ST3+/post-MVP): Messenger/Instagram deeplink cần `url_launcher` package
  // — leader-gated dependency add. Hiện tại chỉ pop sheet (placeholder match
  // behavior của ShareModal trong Feed module).
  void _onMessengerShare(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onInstagramShare(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _onSave(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = post.coverImageUrl;
    Navigator.of(context).pop();
    if (url.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(url));
      await Gal.putImageBytes(response.bodyBytes);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã lưu ảnh')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể lưu ảnh, thử lại')),
      );
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      await ref.read(postControllerProvider.notifier).deletePost(post.postId);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể xoá, thử lại')),
      );
    }
  }
}

// ─── Share target (outer ring + inner circle + logo/icon + label) ────────────

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.outerColor,
    required this.innerColor,
    required this.isIcon,
    this.iconAsset,
    this.logoAsset,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final Color outerColor;
  final Color innerColor;
  final bool isIcon;
  final String? iconAsset;
  final String? logoAsset;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outerColor,
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: innerColor,
              ),
              child: Center(
                child: isIcon && iconAsset != null
                    ? SvgPicture.asset(
                        iconAsset!,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.bw100,
                          BlendMode.srcIn,
                        ),
                      )
                    : logoAsset != null
                        ? SvgPicture.asset(
                            logoAsset!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          )
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw100),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Semantics(
        button: enabled,
        label: label,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );
  }
}

// ─── Action button (Lưu / Xoá) ───────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _cButtonFill,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.bw100,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 24 / 18,
                  color: AppColors.bw100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

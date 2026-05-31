import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

const _cSheetBg = Color(0xFF252627);
const _cButtonFill = Color(0xFF394041);

class SharePhotoSheet extends StatelessWidget {
  const SharePhotoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SharePhotoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ShareTarget(
                    iconAsset: 'assets/icons/ic_share_outline.svg',
                    outerColor: Color(0xFF656c6d),
                    innerColor: Color(0xFF656c6d),
                    label: 'Chia sẻ',
                    isIcon: true,
                  ),
                  _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_messenger.svg',
                    outerColor: Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Messenger',
                    isIcon: false,
                  ),
                  _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_instagram.svg',
                    outerColor: Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Instagram',
                    isIcon: false,
                  ),
                  _ShareTarget(
                    logoAsset: 'assets/icons/ic_logo_sms.svg',
                    outerColor: Color(0xFFDEE5E6),
                    innerColor: Colors.transparent,
                    label: 'Tin nhắn',
                    isIcon: false,
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
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 19),
                  Expanded(
                    child: _ActionButton(
                      iconAsset: 'assets/icons/ic_trash.svg',
                      label: 'Xoá',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
  });

  final String label;
  final Color outerColor;
  final Color innerColor;
  final bool isIcon;
  final String? iconAsset;
  final String? logoAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer ring (50px) visible as border + inner content (42px)
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

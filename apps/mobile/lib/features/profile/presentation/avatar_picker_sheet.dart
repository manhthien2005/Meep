import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';

// ─── SVG icon paths — từ Figma 573:3629 ──────────────────────────────────────
const _iGallery = 'assets/icons/ic_gallery.svg'; // gallery-vertical-end
const _iCamera = 'assets/icons/ic_camera.svg'; // camera
const _iTrash = 'assets/icons/ic_trash.svg'; // trash-2

// ─── Missing design token — #2B2B2B → sheetBackground ───────────────────────
const _cSheetBg = Color(0xFF2B2B2B);
const _cRemove = Color(0xFFE43700); // AppColors.error800

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 265,
      child: AppBottomSheet(
        backgroundColor: _cSheetBg,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Chỉnh sửa ảnh đại diện',
                style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    _SheetOption(
                      icon: SvgPicture.asset(
                        _iGallery,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.bw100,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Chọn từ thư viện',
                      labelColor: AppColors.bw100,
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO(T6): image_picker.pickImage(source: gallery) → compress → updateAvatar()
                      },
                    ),
                    _SheetOption(
                      icon: SvgPicture.asset(
                        _iCamera,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.bw100,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Chụp ảnh',
                      labelColor: AppColors.bw100,
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO(T6): image_picker.pickImage(source: camera) → compress → updateAvatar()
                      },
                    ),
                    _SheetOption(
                      icon: SvgPicture.asset(
                        _iTrash,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          _cRemove,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Gỡ ảnh hiện tại',
                      labelColor: _cRemove,
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO(T6): removeAvatar() → avatarUrl = null → hiện initials
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ảnh hồ sơ của bạn sẽ được hiển thị cho tất cả bạn bè của bạn.',
                      style: AppTextStyles.xsSemiBold
                          .copyWith(color: _cSheetLabel),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _cSheetLabel = Color(0xFFDDDDDD);

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                SizedBox(width: 20, height: 20, child: icon),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTextStyles.mdRegular.copyWith(color: labelColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

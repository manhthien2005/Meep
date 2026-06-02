import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';

/// 3 hành động trong Menu nhật ký (read mode topbar ellipsis).
enum DiaryMenuAction { edit, delete, share }

/// Menu nhật ký — bottom sheet trong Canvas read mode.
///
/// Figma `769:5255` (Menu nhật ký đã viết). Card trắng cornerRadius 20 với
/// 3 options: Chỉnh sửa / Xóa / Chia sẻ. Nút "Xong" card riêng dưới.
///
/// Mở qua [show], trả về [DiaryMenuAction] đã chọn (null nếu dismiss/Xong).
class DiaryMenuSheet extends StatelessWidget {
  const DiaryMenuSheet({super.key});

  /// Mở sheet, trả về action đã chọn (null nếu user tap Xong / scrim).
  static Future<DiaryMenuAction?> show(BuildContext context) {
    return showModalBottomSheet<DiaryMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const DiaryMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 0, 17, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card trắng — 3 options
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 26, 24),
              decoration: BoxDecoration(
                color: AppColors.bw100, // #F9FCFC
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    iconAsset: 'assets/icons/ic_diary_pencil.svg',
                    label: 'Chỉnh sửa',
                    onTap: () => Navigator.of(context).pop(
                      DiaryMenuAction.edit,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuItem(
                    iconAsset: 'assets/icons/ic_diary_trash.svg',
                    label: 'Xóa nhật ký',
                    onTap: () => Navigator.of(context).pop(
                      DiaryMenuAction.delete,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuItem(
                    iconAsset: 'assets/icons/ic_diary_share.svg',
                    label: 'Chia sẻ',
                    onTap: () => Navigator.of(context).pop(
                      DiaryMenuAction.share,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nút "Xong" — card trắng riêng
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bw100, // #F9FCFC
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Xong',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bw800, // #252627
                    height: 22 / 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 hàng option: icon + label.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
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
      label: label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, width: 20, height: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.bw800, // #252627
                height: 22 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

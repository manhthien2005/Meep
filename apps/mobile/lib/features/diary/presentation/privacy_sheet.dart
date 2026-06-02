import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/data/diary_entry.dart';

/// Privacy Sheet — chọn Riêng tư / Công khai cho nhật ký.
///
/// Figma `718:4643` (Privacy Sheet - Nhật ký). Card trắng bo góc 20 với
/// 2 options (checkbox tròn) + nút "Xong". Selected → checkbox Turquoise/500
/// có check; unselected → nền BW/400 + border BW/600.
///
/// Mở qua [show], trả về [DiaryPrivacy] đã chọn (null nếu dismiss).
class PrivacySheet extends StatefulWidget {
  const PrivacySheet({super.key, required this.initial});

  /// Privacy hiện tại của entry (highlight option tương ứng khi mở).
  final DiaryPrivacy initial;

  /// Mở sheet, trả về privacy đã chọn khi tap [Xong]. Null nếu dismiss.
  static Future<DiaryPrivacy?> show(
    BuildContext context, {
    required DiaryPrivacy initial,
  }) {
    return showModalBottomSheet<DiaryPrivacy>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PrivacySheet(initial: initial),
    );
  }

  @override
  State<PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<PrivacySheet> {
  late DiaryPrivacy _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 0, 17, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card trắng — 2 options
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 27, 26, 25),
              decoration: BoxDecoration(
                color: AppColors.bw100, // #F9FCFC
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PrivacyOption(
                    iconAsset: 'assets/icons/ic_diary_lock.svg',
                    label: 'Riêng tư',
                    selected: _selected == DiaryPrivacy.private,
                    onTap: () =>
                        setState(() => _selected = DiaryPrivacy.private),
                  ),
                  const SizedBox(height: 24),
                  _PrivacyOption(
                    iconAsset: 'assets/icons/ic_diary_globe.svg',
                    label: 'Công khai',
                    selected: _selected == DiaryPrivacy.public,
                    onTap: () =>
                        setState(() => _selected = DiaryPrivacy.public),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nút "Xong" — card trắng riêng
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_selected),
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

/// 1 hàng option: icon + label + checkbox tròn (trái → phải).
class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
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
            const Spacer(),
            _RoundCheckbox(checked: selected),
          ],
        ),
      ),
    );
  }
}

/// Checkbox tròn — checked: Turquoise/500 + dấu check; unchecked: BW/400 +
/// border BW/600.
class _RoundCheckbox extends StatelessWidget {
  const _RoundCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.turquoise500 : AppColors.bw400, // #00DEEE
        border: Border.all(
          color: checked ? AppColors.turquoise500 : AppColors.bw600, // #656C6D
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 11, color: AppColors.bw100)
          : null,
    );
  }
}

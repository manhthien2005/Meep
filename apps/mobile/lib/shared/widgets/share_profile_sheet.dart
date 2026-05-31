import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

const _cBg = Color(0xFF2B2B2B);
const _cSubtext = Color(0xFFBABABA);
const _cLogoBox = Color(0xFFFFFFFF);
const _cLogomark = Color(0xFF004B54);

const _titleStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 24 / 18,
);

class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({
    super.key,
    required this.uid,
    required this.username,
    this.title,
  });

  final String uid;
  final String username;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required String uid,
    required String username,
    String? title,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          ShareProfileSheet(uid: uid, username: username, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileLink = 'meep://profile/$username';
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _cBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 55,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(6.5),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28, 6, 28, 30 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _cLogoBox,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(11, 14, 11, 13),
                      child: SvgPicture.asset(
                        'assets/icons/ic_logo_sheet.svg',
                        colorFilter: const ColorFilter.mode(
                          _cLogomark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? 'Kết bạn với tôi trên Meep nhé!',
                            style: _titleStyle.copyWith(color: AppColors.bw100),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profileLink,
                            style: AppTextStyles.smRegular
                                .copyWith(color: _cSubtext),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 27),
                _SheetOption(
                  icon: 'assets/icons/ic_message_circle_check.svg',
                  label: 'Gửi qua Messenger',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO(T6/HanDHG): open Messenger deep link
                  },
                ),
                const SizedBox(height: 10),
                _SheetOption(
                  icon: 'assets/icons/ic_link.svg',
                  label: 'Sao chép liên kết',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: profileLink));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép liên kết')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(AppColors.bw100, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.mdRegular.copyWith(
                color: AppColors.bw100,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

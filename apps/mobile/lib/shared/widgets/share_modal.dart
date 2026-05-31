import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/shared/widgets/app_circle_icon_button.dart';
import 'package:share_plus/share_plus.dart';

class ShareModal extends ConsumerWidget {
  const ShareModal({
    super.key,
    required this.post,
    required this.isAuthor,
  });

  final Post post;
  final bool isAuthor;

  // Figma 580:2813 — circle target diameter inside 50×74 cell.
  static const double _targetCircleSize = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bw600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chia sẻ đến...',
            style: TextStyle(
              color: AppColors.bw100,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareTarget(
                label: 'Chia sẻ',
                icon: Icons.ios_share,
                color: AppColors.bw700,
                onTap: () {
                  Navigator.of(context).pop();
                  Share.shareUri(Uri.parse(post.coverImageUrl));
                },
              ),
              _ShareTarget(
                label: 'Messenger',
                icon: Icons.messenger_outline,
                color: const Color(0xFF0084FF),
                onTap: () => Navigator.of(context).pop(),
              ),
              _ShareTarget(
                label: 'Instagram',
                icon: Icons.camera_alt_outlined,
                color: const Color(0xFFE1306C),
                onTap: () => Navigator.of(context).pop(),
              ),
              _ShareTarget(
                label: 'Tin nhắn',
                icon: Icons.message_outlined,
                color: AppColors.bw700,
                enabled: false, // M2: Chat module disabled
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.download_outlined,
                  label: 'Lưu',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final response =
                        await http.get(Uri.parse(post.coverImageUrl));
                    await Gal.putImageBytes(response.bodyBytes);
                  },
                ),
              ),
              if (isAuthor) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.delete_outline,
                    label: 'Xoá',
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(postControllerProvider.notifier)
                          .deletePost(post.postId);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCircleIconButton(
          icon: icon,
          size: ShareModal._targetCircleSize,
          backgroundColor: color,
          iconColor: Colors.white,
          iconScale: 0.5,
          onPressed: enabled ? onTap : null,
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.bw100,
              fontSize: 12,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.bw800,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.bw100, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.bw100,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

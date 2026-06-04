import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/notification/application/notification_state.dart';

/// Figma component `Noti` — overlay notification banner.
///
/// UX: single-tap = open the screen the notification points at (giống
/// Android tray, Locket, Snapchat); long-press = "Tắt thông báo" (suppress
/// banners cho session, vẫn nhận push tray). Auto-dismiss sau 4s do timer
/// trong [NotificationController]. Expand/collapse + 2 actions trong Figma
/// đã được lược bỏ vì conflict với tap-to-open — quan trọng hơn.

const _bannerWidth = 364.0;
const _bannerHeight = 65.0;
const _logoSize = 40.0;

const _senderNameStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 18 / 13,
);

const _timestampStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 11,
  fontWeight: FontWeight.w300,
  height: 15 / 11,
);

const _previewStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 13,
  fontWeight: FontWeight.w300,
  height: 18 / 13,
);

class NotificationBanner extends StatefulWidget {
  const NotificationBanner({
    super.key,
    required this.payload,
    required this.onTap,
    required this.onSuppress,
  });

  final BannerPayload payload;

  /// Tap → consume payload + route. Caller (main.dart) gọi
  /// `notificationController.openBannerAsTap()` để emit `OpenedAppPayload`
  /// cho router consume.
  final VoidCallback onTap;

  /// Long-press → suppress banner cho phiên hiện tại (push tray vẫn nhận).
  final VoidCallback onSuppress;

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: _bannerWidth,
        height: _bannerHeight,
        decoration: BoxDecoration(
          color: const Color(0xE02D2D2F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            onLongPress: widget.onSuppress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_logo_sheet.svg',
                    width: _logoSize,
                    height: _logoSize,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.payload.title,
                                style: _senderNameStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(widget.payload.timestamp),
                              style: _timestampStyle.copyWith(
                                color: AppColors.bw500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.payload.body,
                          style: _previewStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

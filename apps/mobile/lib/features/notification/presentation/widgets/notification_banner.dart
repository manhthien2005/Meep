import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/notification/application/notification_state.dart';

/// Figma component `Noti` — overlay notification banner.
///
/// Collapsed (h=65, `765:4981`): logo + senderName + timestamp + chevron-down
/// + message preview.
/// Expanded (h=112, `765:4766`): same top row + [Trả lời] + [Tắt thông báo].

const _bannerWidth = 364.0;
const _collapsedHeight = 65.0;
const _expandedHeight = 112.0;
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

const _actionStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 16 / 12,
);

class NotificationBanner extends StatefulWidget {
  const NotificationBanner({
    super.key,
    required this.payload,
    required this.onSuppress,
  });

  final BannerPayload payload;
  final VoidCallback onSuppress;

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: _bannerWidth,
        height: _expanded ? _expandedHeight : _collapsedHeight,
        decoration: BoxDecoration(
          color: const Color(0xE02D2D2F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row ──────────────────────────────────────────
                  Row(
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
                                  style: _timestampStyle,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.bw500,
                                  size: 18,
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
                  // ── Expanded actions ─────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // TODO(N/T4/KhoaLND): wire to Chat 1-1 module
                                    },
                                    child: Text(
                                      'Trả lời',
                                      textAlign: TextAlign.center,
                                      style: _actionStyle.copyWith(
                                        color: AppColors.bw500,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: AppColors.bw500.withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: widget.onSuppress,
                                    child: Text(
                                      'Tắt thông báo',
                                      textAlign: TextAlign.center,
                                      style: _actionStyle.copyWith(
                                        color: AppColors.bw500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
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

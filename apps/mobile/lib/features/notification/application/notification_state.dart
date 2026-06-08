import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_state.freezed.dart';

/// Trạng thái quyền thông báo (Android 13+ POST_NOTIFICATIONS).
///
/// - [unknown]: chưa kiểm tra / chưa hỏi.
/// - [granted]: đã cấp → FCM hoạt động.
/// - [denied]: từ chối nhưng còn hỏi lại được → show rationale dialog.
/// - [permanentlyDenied]: từ chối vĩnh viễn (chọn "Don't allow") → chỉ bật
///   được trong Cài đặt hệ thống → show fallback banner + "Mở Cài đặt".
enum NotificationPermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied
}

@freezed
class BannerPayload with _$BannerPayload {
  const factory BannerPayload({
    required String title,
    required String body,
    required DateTime timestamp,
    @Default({}) Map<String, String> data,
  }) = _BannerPayload;
}

/// Pending deep-link emitted when user taps an FCM notification while the
/// app is alive (background → foreground). The router listens for changes
/// and routes once, then calls `consumeOpenedAppMessage` to clear.
///
/// Wrapped instead of using raw `RemoteMessage` so freezed `==` can compare
/// distinct deliveries — same `messageId` is treated as the same payload
/// (FCM dedupe guarantee), so re-emits with the same id are no-ops.
@freezed
class OpenedAppPayload with _$OpenedAppPayload {
  const factory OpenedAppPayload({
    required String messageId,
    @Default({}) Map<String, String> data,
  }) = _OpenedAppPayload;
}

@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default(NotificationPermissionStatus.unknown)
    NotificationPermissionStatus permissionStatus,
    @Default(false) bool bannerSuppressed,
    BannerPayload? currentBanner,
    OpenedAppPayload? lastOpenedApp,
  }) = _NotificationState;
}

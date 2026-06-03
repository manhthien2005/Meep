import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_state.freezed.dart';

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
    @Default(false) bool fcmPermissionDenied,
    @Default(false) bool bannerSuppressed,
    BannerPayload? currentBanner,
    OpenedAppPayload? lastOpenedApp,
  }) = _NotificationState;
}

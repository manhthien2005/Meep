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

@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default(false) bool fcmPermissionDenied,
    @Default(false) bool bannerSuppressed,
    BannerPayload? currentBanner,
  }) = _NotificationState;
}

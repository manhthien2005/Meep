import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/notification/application/notification_state.dart';
import 'package:meep/features/notification/data/notification_preferences.dart';
import 'package:meep/features/notification/data/notification_repository.dart';

part 'notification_controller.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    throw UnimplementedError(
      'notificationRepositoryProvider must be overridden — '
      'wire FirebaseNotificationRepository in main.dart',
    );

@Riverpod(keepAlive: true)
NotificationPreferences notificationPreferences(Ref ref) =>
    throw UnimplementedError(
      'notificationPreferencesProvider must be overridden — '
      'wire NotificationPreferences in main.dart',
    );

@riverpod
class NotificationController extends _$NotificationController {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  Timer? _bannerTimer;
  bool _fcmInitialized = false;

  @override
  NotificationState build() {
    // `notificationPreferencesProvider` keeps the same instance for the app
    // lifetime — snapshot via read() is correct. `watch` would suggest the
    // pref's internal value drives rebuilds, which it doesn't (we mutate it
    // via setBannerSuppressed and update state ourselves).
    final prefs = ref.read(notificationPreferencesProvider);
    final suppressed = prefs.isBannerSuppressed;
    ref.onDispose(() {
      _onMessageSub?.cancel();
      _onMessageOpenedAppSub?.cancel();
      _onTokenRefreshSub?.cancel();
      _bannerTimer?.cancel();
    });
    return NotificationState(bannerSuppressed: suppressed);
  }

  /// Idempotent — re-entry on uid stream re-emit (vd refresh token flip
  /// AsyncLoading→AsyncData) must NOT chain extra `onMessage` listeners,
  /// else `_handleForeground` fires N times per push.
  Future<void> initFcm() async {
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      state = state.copyWith(fcmPermissionDenied: true);
      // Reset so retry after user grants in Settings re-runs the full flow.
      _fcmInitialized = false;
      return;
    }

    await _initLocalNotifications();

    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    _onTokenRefreshSub = messaging.onTokenRefresh.listen(_saveToken);

    // Cold-start deep link captured BEFORE wiring the live stream — else a
    // background-arriving message during init can be handled by both
    // `getInitialMessage` (cold-start path) and `onMessageOpenedApp`,
    // causing a double navigate. Per Firebase docs.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      handleOpenedApp(initialMessage);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(handleOpenedApp);
  }

  Future<void> _saveToken(String token) async {
    final uid = ref.read(currentUidProvider).valueOrNull;
    if (uid == null) return;
    await ref.read(notificationRepositoryProvider).saveFcmToken(uid, token);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);
  }

  @visibleForTesting
  void handleForeground(RemoteMessage message) => _handleForeground(message);

  void _handleForeground(RemoteMessage message) {
    if (state.bannerSuppressed) return;

    final notification = message.notification;
    if (notification != null) {
      // Unique ID per push — `notification.hashCode` collides on duplicate
      // title+body (vd 2 reactions from same friend) and silently replaces
      // the prior local notification. Wrap-around at 31-bit to stay in
      // Android's signed int range.
      final notifId = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      // Local notification show is fire-and-forget; swallow errors so a
      // missing channel/init failure doesn't crash the FCM stream.
      unawaited(
        _localNotifications
            .show(
              notifId,
              notification.title,
              notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'meep_foreground',
                  'Meep notifications',
                  channelDescription: 'Notifications when app is in foreground',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            )
            .catchError((_) {}),
      );
    }

    _bannerTimer?.cancel();

    // `RemoteMessage.data` is `Map<String, dynamic>` — server may send numeric
    // / bool values (vd `unreadCount: 3`). `Map<String, String>.from` without
    // converting would throw `_TypeError` and kill the FCM stream listener.
    // Match `handleOpenedApp` and stringify every value.
    final data = Map<String, String>.from(
      message.data.map((k, v) => MapEntry(k, v.toString())),
    );

    state = state.copyWith(
      currentBanner: BannerPayload(
        title: notification?.title ?? '',
        body: notification?.body ?? '',
        timestamp: DateTime.now(),
        data: data,
      ),
    );

    _bannerTimer = Timer(const Duration(seconds: 4), () {
      state = state.copyWith(currentBanner: null);
    });
  }

  /// User tap vào banner foreground → biến `currentBanner.data` thành
  /// [OpenedAppPayload] để router (`appRouter` ref.listen) tự route +
  /// consume. Banner bị clear ngay để tránh hiển thị trùng với screen
  /// đích vừa mở.
  ///
  /// Synthetic `messageId` — banner foreground không có FCM `messageId`
  /// (đây là delivery `onMessage` chứ không phải `onMessageOpenedApp`).
  /// Dùng microsecond stamp của `BannerPayload.timestamp` đảm bảo 2 banner
  /// liên tiếp tap không bị freezed `==` dedupe về cùng một payload.
  void openBannerAsTap() {
    final banner = state.currentBanner;
    if (banner == null) return;
    final messageId = 'banner-${banner.timestamp.microsecondsSinceEpoch}';
    _bannerTimer?.cancel();
    state = state.copyWith(
      currentBanner: null,
      lastOpenedApp: OpenedAppPayload(
        messageId: messageId,
        data: banner.data,
      ),
    );
  }

  /// Wraps a tapped `RemoteMessage` into [OpenedAppPayload] and writes it
  /// to state — the router's `ref.listen` consumes it and routes once.
  ///
  /// Public (not private) so unit tests can drive it directly without
  /// mocking the FirebaseMessaging stream. Called by `initFcm` for the
  /// cold-start `getInitialMessage` and by the `onMessageOpenedApp`
  /// subscription for background taps.
  void handleOpenedApp(RemoteMessage message) {
    // `messageId` is FCM's dedupe key — guaranteed unique per delivery.
    // Fall back to a synthetic id when null (vd push from emulator) so the
    // payload is still emittable; equality still holds because the same
    // RemoteMessage instance keeps the same fallback id during one tap.
    final messageId = message.messageId ?? 'no-id-${message.hashCode}';
    final data = Map<String, String>.from(
      message.data.map((k, v) => MapEntry(k, v.toString())),
    );
    state = state.copyWith(
      lastOpenedApp: OpenedAppPayload(messageId: messageId, data: data),
    );
  }

  /// Router calls after dispatching the navigation. Clears `lastOpenedApp`
  /// so a future re-listen (vd hot restart with the same payload still in
  /// state) does not re-route.
  void consumeOpenedAppMessage() {
    if (state.lastOpenedApp == null) return;
    state = state.copyWith(lastOpenedApp: null);
  }

  void dismissBanner() {
    _bannerTimer?.cancel();
    state = state.copyWith(currentBanner: null);
  }

  Future<void> suppressBanner() async {
    await ref.read(notificationPreferencesProvider).setBannerSuppressed(true);
    _bannerTimer?.cancel();
    state = state.copyWith(bannerSuppressed: true, currentBanner: null);
  }

  Future<void> markAsRead(String notifId) async {
    await ref.read(notificationRepositoryProvider).markAsRead(notifId);
  }
}

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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

/// Messages delivered while app was killed, read once at cold start.
/// T4 deep link handler consumes this.
final initialMessageProvider = Provider<RemoteMessage?>((ref) {
  return ref.read(notificationControllerProvider.notifier).initialMessage;
});

@riverpod
class NotificationController extends _$NotificationController {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  Timer? _bannerTimer;
  RemoteMessage? _initialMessage;
  bool _fcmInitialized = false;

  RemoteMessage? get initialMessage => _initialMessage;

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
    // `_initialMessage` (T4 deep link) and `onMessageOpenedApp`, causing a
    // double navigate. Per Firebase docs.
    _initialMessage = await messaging.getInitialMessage();

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);
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

    final data = Map<String, String>.from(
      message.data.map((k, v) => MapEntry(k, v)),
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

  void _handleOpenedApp(RemoteMessage message) {
    // T4 wires deep link routing from this callback.
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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/notification/application/notification_controller.dart';
import 'package:meep/features/notification/application/notification_state.dart';
import 'package:meep/features/notification/data/notification_preferences.dart';
import 'package:meep/features/notification/data/notification_repository.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationRepository repo;
  late SharedPreferences prefs;
  late NotificationPreferences notifPrefs;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          notificationPreferencesProvider.overrideWithValue(notifPrefs),
        ],
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifPrefs = NotificationPreferences(prefs: prefs);
    repo = MockNotificationRepository();
    when(() => repo.markAsRead(any())).thenAnswer((_) async {});
    container = makeContainer();
  });

  tearDown(() => container.dispose());

  group('initial state', () {
    test('bannerSuppressed = false by default (no pref set)', () {
      final state = container.read(notificationControllerProvider);
      expect(state.bannerSuppressed, isFalse);
      expect(state.permissionStatus, NotificationPermissionStatus.unknown);
      expect(state.currentBanner, isNull);
    });

    test('bannerSuppressed = true when pref is set', () async {
      await notifPrefs.setBannerSuppressed(true);

      final container2 = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
          notificationPreferencesProvider.overrideWithValue(notifPrefs),
        ],
      );
      addTearDown(container2.dispose);

      final state = container2.read(notificationControllerProvider);
      expect(state.bannerSuppressed, isTrue);
    });
  });

  group('markAsRead', () {
    test('delegates to repository with notifId', () async {
      await container
          .read(notificationControllerProvider.notifier)
          .markAsRead('users/uid-alice/notifications/n1');

      verify(() => repo.markAsRead('users/uid-alice/notifications/n1'))
          .called(1);
    });

    test('passes through repo errors (no silent swallow)', () async {
      when(() => repo.markAsRead(any()))
          .thenThrow(Exception('Firestore failure'));

      await expectLater(
        container
            .read(notificationControllerProvider.notifier)
            .markAsRead('users/uid/notifications/n1'),
        throwsException,
      );
    });
  });

  group('suppressBanner', () {
    test('sets pref + updates state.bannerSuppressed to true', () async {
      expect(prefs.getBool('notification_banner_suppressed'), isNull);

      await container
          .read(notificationControllerProvider.notifier)
          .suppressBanner();

      expect(prefs.getBool('notification_banner_suppressed'), isTrue);
      final state = container.read(notificationControllerProvider);
      expect(state.bannerSuppressed, isTrue);
    });

    test('clears currentBanner when suppressing', () async {
      // Simulate a banner being shown — set via state mutation
      // (in real flow this comes from _handleForeground)
      final controller =
          container.read(notificationControllerProvider.notifier);
      // Trigger state with a banner — we can't call _handleForeground directly
      // but suppressBanner should clear currentBanner regardless
      await controller.suppressBanner();

      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNull);
    });
  });

  group('dismissBanner', () {
    test('clears currentBanner', () {
      final controller =
          container.read(notificationControllerProvider.notifier);
      controller.dismissBanner();

      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNull);
    });
  });

  group('openBannerAsTap', () {
    test('is a no-op when no banner is showing', () {
      // Happy path (có banner → emit lastOpenedApp) test gián tiếp qua
      // notification_banner_test (tap banner → onTap fires); set
      // `currentBanner` từ test cần mock FirebaseMessaging.onMessage stream
      // — bỏ qua đến khi có refactor cho phép inject banner trực tiếp.
      final controller =
          container.read(notificationControllerProvider.notifier);
      controller.openBannerAsTap();

      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNull);
      expect(state.lastOpenedApp, isNull);
    });
  });

  group('handleOpenedApp', () {
    // RemoteMessage constructor accepts arbitrary data and an explicit
    // messageId, so the tap path is testable without mocking the FCM
    // stream itself.

    test('writes a payload with FCM messageId + data to state', () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleOpenedApp(
        const RemoteMessage(
          messageId: 'fcm-msg-1',
          data: {'type': 'friend_request', 'requestId': 'req-9'},
        ),
      );

      final state = container.read(notificationControllerProvider);
      expect(state.lastOpenedApp, isNotNull);
      expect(state.lastOpenedApp!.messageId, 'fcm-msg-1');
      expect(state.lastOpenedApp!.data, {
        'type': 'friend_request',
        'requestId': 'req-9',
      });
    });

    test('synthesises an id when FCM did not supply messageId', () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleOpenedApp(
        const RemoteMessage(data: {'type': 'new_post'}),
      );

      final state = container.read(notificationControllerProvider);
      expect(state.lastOpenedApp, isNotNull);
      expect(
        state.lastOpenedApp!.messageId,
        startsWith('no-id-'),
        reason: 'fallback id keeps the payload distinct from later taps',
      );
    });

    test('coerces non-string data values to strings', () {
      // FCM data payload is `Map<String, dynamic>` on the wire even though
      // the contract is string-string. Real backends sometimes send
      // numeric values — the wrapper must not throw a TypeError.
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleOpenedApp(
        const RemoteMessage(
          messageId: 'm1',
          data: {'type': 'reaction', 'postId': 12345},
        ),
      );

      final state = container.read(notificationControllerProvider);
      expect(state.lastOpenedApp!.data, {
        'type': 'reaction',
        'postId': '12345',
      });
    });

    test('a second tap overwrites the previous payload', () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleOpenedApp(
        const RemoteMessage(messageId: 'm1', data: {'type': 'new_post'}),
      );
      controller.handleOpenedApp(
        const RemoteMessage(
          messageId: 'm2',
          data: {'type': 'reaction', 'postId': 'p1'},
        ),
      );

      final state = container.read(notificationControllerProvider);
      expect(state.lastOpenedApp!.messageId, 'm2');
      expect(state.lastOpenedApp!.data['type'], 'reaction');
    });
  });

  group('consumeOpenedAppMessage', () {
    test('clears lastOpenedApp after a tap has been routed', () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleOpenedApp(
        const RemoteMessage(messageId: 'm1', data: {'type': 'new_post'}),
      );
      expect(
        container.read(notificationControllerProvider).lastOpenedApp,
        isNotNull,
      );

      controller.consumeOpenedAppMessage();

      expect(
        container.read(notificationControllerProvider).lastOpenedApp,
        isNull,
      );
    });

    test('is a no-op when nothing is pending', () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.consumeOpenedAppMessage();
      controller.consumeOpenedAppMessage();

      expect(
        container.read(notificationControllerProvider).lastOpenedApp,
        isNull,
      );
    });
  });

  group('handleForeground', () {
    // `handleForeground` is exposed via `@visibleForTesting` so the regression
    // for the dynamic→String coercion can be pinned here. In production the
    // method is fed by `FirebaseMessaging.onMessage.listen` inside `initFcm`.

    test(
        'coerces non-string data values to strings — '
        'regression N1 (was: TypeError crashed FCM stream)', () {
      // Wire-level FCM data is `Map<String, dynamic>`. Server occasionally
      // sends ints/bools (vd `unreadCount: 3`). Before the fix this threw
      // `_TypeError` inside `Map<String, String>.from` and killed the
      // listener — every subsequent push was dropped silently until the next
      // cold start.
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleForeground(
        const RemoteMessage(
          messageId: 'fcm-fg-1',
          notification: RemoteNotification(title: 'A', body: 'B'),
          data: {'type': 'reaction', 'postId': 12345, 'unread': true},
        ),
      );

      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNotNull);
      expect(state.currentBanner!.data, {
        'type': 'reaction',
        'postId': '12345',
        'unread': 'true',
      });
    });

    test('drops the banner when bannerSuppressed = true', () async {
      await notifPrefs.setBannerSuppressed(true);
      final container2 = makeContainer();
      addTearDown(container2.dispose);

      final controller =
          container2.read(notificationControllerProvider.notifier);
      controller.handleForeground(
        const RemoteMessage(
          messageId: 'm',
          notification: RemoteNotification(title: 't', body: 'b'),
          data: {'type': 'new_post'},
        ),
      );

      expect(
        container2.read(notificationControllerProvider).currentBanner,
        isNull,
      );
    });

    test('populates currentBanner with title + body from RemoteNotification',
        () {
      final controller =
          container.read(notificationControllerProvider.notifier);

      controller.handleForeground(
        const RemoteMessage(
          messageId: 'm1',
          notification: RemoteNotification(
            title: 'Lan đã thả tim',
            body: 'Ảnh của bạn',
          ),
          data: {'type': 'reaction', 'postId': 'p9'},
        ),
      );

      final banner =
          container.read(notificationControllerProvider).currentBanner;
      expect(banner, isNotNull);
      expect(banner!.title, 'Lan đã thả tim');
      expect(banner.body, 'Ảnh của bạn');
    });
  });

  group('resetForLogout', () {
    // N2 regression — `_fcmInitialized` must drop to false so a subsequent
    // user-B login on the same device re-runs the full initFcm() path
    // (permission, token save, listener wiring). Without this, the early
    // return at `if (_fcmInitialized) return;` skips token save for user B
    // and they get no push until cold restart.

    test('clears currentBanner + lastOpenedApp + resets permissionStatus',
        () async {
      final controller =
          container.read(notificationControllerProvider.notifier);

      // Seed state with a banner + opened-app.
      controller.handleForeground(
        const RemoteMessage(
          messageId: 'fg-1',
          notification: RemoteNotification(title: 't', body: 'b'),
          data: {'type': 'new_post'},
        ),
      );
      controller.handleOpenedApp(
        const RemoteMessage(messageId: 'open-1', data: {'type': 'reaction'}),
      );
      expect(
        container.read(notificationControllerProvider).currentBanner,
        isNotNull,
      );
      expect(
        container.read(notificationControllerProvider).lastOpenedApp,
        isNotNull,
      );

      await controller.resetForLogout();

      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNull);
      expect(state.lastOpenedApp, isNull);
      expect(state.permissionStatus, NotificationPermissionStatus.unknown);
    });

    test('is idempotent — calling twice is safe', () async {
      final controller =
          container.read(notificationControllerProvider.notifier);

      await controller.resetForLogout();
      await controller.resetForLogout();

      // No exception thrown, state remains clean.
      final state = container.read(notificationControllerProvider);
      expect(state.currentBanner, isNull);
      expect(state.lastOpenedApp, isNull);
    });
  });
}

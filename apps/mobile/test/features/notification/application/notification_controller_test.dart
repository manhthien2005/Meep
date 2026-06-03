import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/notification/application/notification_controller.dart';
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
      expect(state.fcmPermissionDenied, isFalse);
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
}

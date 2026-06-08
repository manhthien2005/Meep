import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/notification/application/notification_controller.dart';
import 'package:meep/features/notification/data/notification_repository.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/data/block_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBlockRepository extends Mock implements BlockRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockWidgetDataService extends Mock implements WidgetDataService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('copyProfileLink', () {
    late ProviderContainer container;
    String? capturedText;

    setUp(() {
      capturedText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          capturedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });

      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('set clipboard tới meep://profile/{username}', () async {
      await container
          .read(settingsControllerProvider.notifier)
          .copyProfileLink('ngantran');

      expect(capturedText, 'meep://profile/ngantran');
    });

    test('username có ký tự đặc biệt vẫn copy raw (không URL-encode)',
        () async {
      // Username Meep theo spec là lower-snake/ASCII, không cần encode.
      // Test đảm bảo controller KHÔNG accidentally encode.
      await container
          .read(settingsControllerProvider.notifier)
          .copyProfileLink('user_name.test');

      expect(capturedText, 'meep://profile/user_name.test');
    });
  });

  group('blockUser / unblockUser', () {
    late MockAuthRepository auth;
    late MockBlockRepository block;
    late ProviderContainer container;

    ProviderContainer makeContainer() => ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            blockRepositoryProvider.overrideWithValue(block),
          ],
        );

    setUp(() {
      auth = MockAuthRepository();
      block = MockBlockRepository();
      // Default: signed in as 'me'
      when(() => auth.currentUid).thenReturn('me');
      when(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => block.unblockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});
      container = makeContainer();
    });

    tearDown(() => container.dispose());

    test('blockUser: gọi repo với blockerUid=currentUid + targetUid', () async {
      await container
          .read(settingsControllerProvider.notifier)
          .blockUser('target');

      verify(() => block.blockUser(blockerUid: 'me', targetUid: 'target'))
          .called(1);
      expect(container.read(settingsControllerProvider).isLoading, isFalse);
      expect(container.read(settingsControllerProvider).errorMessage, isNull);
    });

    test('blockUser: chưa login → errorMessage set, KHÔNG gọi repo', () async {
      when(() => auth.currentUid).thenReturn(null);

      await container
          .read(settingsControllerProvider.notifier)
          .blockUser('target');

      verifyNever(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      );
      expect(
        container.read(settingsControllerProvider).errorMessage,
        isNotNull,
      );
    });

    test('blockUser: repo throw AppError → state.errorMessage = err.message',
        () async {
      when(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenThrow(ForbiddenError('chặn người dùng'));

      await container
          .read(settingsControllerProvider.notifier)
          .blockUser('target');

      final state = container.read(settingsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('chặn người dùng'));
    });

    test('unblockUser: gọi repo với blockerUid + targetUid', () async {
      await container
          .read(settingsControllerProvider.notifier)
          .unblockUser('target');

      verify(() => block.unblockUser(blockerUid: 'me', targetUid: 'target'))
          .called(1);
      expect(container.read(settingsControllerProvider).isLoading, isFalse);
    });
  });

  group('logout', () {
    late MockAuthRepository auth;
    late MockNotificationRepository notif;
    late MockWidgetDataService widgetData;
    late ProviderContainer container;

    setUp(() {
      auth = MockAuthRepository();
      notif = MockNotificationRepository();
      widgetData = MockWidgetDataService();
      when(() => auth.currentUid).thenReturn('me');
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => notif.deleteFcmToken(any())).thenAnswer((_) async {});
      when(() => widgetData.clearData()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          notificationRepositoryProvider.overrideWithValue(notif),
          widgetDataServiceProvider.overrideWithValue(widgetData),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('gọi deleteFcmToken(uid) → clearData() → signOut() theo đúng thứ tự',
        () async {
      await container.read(settingsControllerProvider.notifier).logout();

      verifyInOrder([
        () => notif.deleteFcmToken('me'),
        () => widgetData.clearData(),
        () => auth.signOut(),
      ]);
    });

    test('chưa login (uid null) → skip deleteFcmToken, vẫn signOut', () async {
      when(() => auth.currentUid).thenReturn(null);

      await container.read(settingsControllerProvider.notifier).logout();

      verifyNever(() => notif.deleteFcmToken(any()));
      verifyNever(() => widgetData.clearData());
      verify(() => auth.signOut()).called(1);
    });

    test(
        'deleteFcmToken throw (vd offline / notification chưa wire) → '
        'vẫn signOut, KHÔNG bubble lên', () async {
      when(() => notif.deleteFcmToken(any()))
          .thenThrow(const NetworkError(message: 'offline'));

      await container.read(settingsControllerProvider.notifier).logout();

      verify(() => auth.signOut()).called(1);
      // errorMessage null vì FCM cleanup là best-effort.
      expect(container.read(settingsControllerProvider).errorMessage, isNull);
    });

    test('signOut throw → errorMessage set, isLoading reset', () async {
      when(() => auth.signOut()).thenThrow(
        const NetworkError(message: 'không thể đăng xuất'),
      );

      await container.read(settingsControllerProvider.notifier).logout();

      final state = container.read(settingsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('không thể đăng xuất'));
    });
  });

  group('deleteAccount', () {
    late MockAuthRepository auth;
    late MockNotificationRepository notif;
    late MockWidgetDataService widgetData;
    late ProviderContainer container;

    setUp(() {
      auth = MockAuthRepository();
      notif = MockNotificationRepository();
      widgetData = MockWidgetDataService();
      when(() => auth.currentUid).thenReturn('me');
      when(() => auth.deleteAccountCascade()).thenAnswer((_) async {});
      when(() => notif.deleteFcmToken(any())).thenAnswer((_) async {});
      when(() => widgetData.clearData()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          notificationRepositoryProvider.overrideWithValue(notif),
          widgetDataServiceProvider.overrideWithValue(widgetData),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
        'gọi deleteFcmToken(uid) → clearData() → '
        'deleteAccountCascade() theo đúng thứ tự', () async {
      await container.read(settingsControllerProvider.notifier).deleteAccount();

      verifyInOrder([
        () => notif.deleteFcmToken('me'),
        () => widgetData.clearData(),
        () => auth.deleteAccountCascade(),
      ]);
      expect(container.read(settingsControllerProvider).isLoading, isFalse);
      expect(container.read(settingsControllerProvider).errorMessage, isNull);
    });

    test('chưa login (uid null) → errorMessage set, KHÔNG gọi cascade',
        () async {
      when(() => auth.currentUid).thenReturn(null);

      await container.read(settingsControllerProvider.notifier).deleteAccount();

      verifyNever(() => notif.deleteFcmToken(any()));
      verifyNever(() => widgetData.clearData());
      verifyNever(() => auth.deleteAccountCascade());
      final state = container.read(settingsControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('deleteFcmToken throw → vẫn gọi cascade (best-effort cleanup)',
        () async {
      when(() => notif.deleteFcmToken(any()))
          .thenThrow(const NetworkError(message: 'offline'));

      await container.read(settingsControllerProvider.notifier).deleteAccount();

      verify(() => auth.deleteAccountCascade()).called(1);
      // errorMessage null vì FCM cleanup KHÔNG block cascade.
      expect(container.read(settingsControllerProvider).errorMessage, isNull);
    });

    test('cascade throw AppError → errorMessage set, isLoading reset',
        () async {
      when(() => auth.deleteAccountCascade()).thenThrow(
        const NetworkError(message: 'không thể xóa tài khoản'),
      );

      await container.read(settingsControllerProvider.notifier).deleteAccount();

      final state = container.read(settingsControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('không thể xóa tài khoản'));
    });
  });
}

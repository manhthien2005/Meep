import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/notification/application/notification_controller.dart';
import 'package:meep/features/notification/data/notification_repository.dart';
import 'package:meep/features/settings/presentation/delete_account_dialog.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  group('DeleteAccountDialog', () {
    late _MockAuthRepository auth;
    late _MockNotificationRepository notif;

    setUp(() {
      auth = _MockAuthRepository();
      notif = _MockNotificationRepository();
      // Default: signed in as email user.
      when(() => auth.currentUid).thenReturn('me');
      when(() => auth.currentProviderId).thenReturn('password');
      when(() => auth.reauthenticateWithPassword(any()))
          .thenAnswer((_) async {});
      when(() => auth.reauthenticateWithGoogle()).thenAnswer((_) async {});
      when(() => auth.deleteAccountCascade()).thenAnswer((_) async {});
      when(() => notif.deleteFcmToken(any())).thenAnswer((_) async {});
    });

    Widget harness() => ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            notificationRepositoryProvider.overrideWithValue(notif),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => DeleteAccountDialog.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );

    Future<void> openStep1(WidgetTester tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> openStep2(WidgetTester tester) async {
      await openStep1(tester);
      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();
    }

    testWidgets('step 1 — confirm xoá tài khoản (nút đỏ "Xoá")',
        (tester) async {
      await openStep1(tester);

      expect(
        find.text('Bạn có chắc muốn xoá tài khoản này không?'),
        findsOneWidget,
      );
      expect(find.text('Xoá'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
    });

    testWidgets(
        'step 2 email user: hiện password field + caption "nhập mật khẩu"',
        (tester) async {
      await openStep2(tester);

      expect(find.text('Xác thực lại'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu để xác nhận'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        'step 2 Google user: KHÔNG hiện password field, caption "Chạm xác nhận"',
        (tester) async {
      when(() => auth.currentProviderId).thenReturn('google.com');

      await openStep2(tester);

      expect(find.text('Xác thực lại'), findsOneWidget);
      expect(
        find.text('Chạm xác nhận để xác thực lại với Google'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('step 2 email: mật khẩu rỗng → hiện lỗi, KHÔNG submit',
        (tester) async {
      await openStep2(tester);

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.text('Xác thực lại'), findsOneWidget);
      verifyNever(() => auth.reauthenticateWithPassword(any()));
    });

    testWidgets(
        'step 2 email: reauth success → gọi deleteAccountCascade → pop true',
        (tester) async {
      await openStep2(tester);

      await tester.enterText(find.byType(TextField), 'correct-password');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      verify(() => auth.reauthenticateWithPassword('correct-password'))
          .called(1);
      verify(() => auth.deleteAccountCascade()).called(1);
      // Dialog đã pop → step 2 widget không còn.
      expect(find.text('Xác thực lại'), findsNothing);
    });

    testWidgets(
        'step 2 email: reauth wrong password → hiện lỗi inline, dialog VẪN mở',
        (tester) async {
      when(() => auth.reauthenticateWithPassword(any())).thenThrow(
        const UnauthenticatedError(message: 'Mật khẩu không đúng'),
      );

      await openStep2(tester);

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu không đúng'), findsOneWidget);
      // Dialog vẫn mở để user thử lại.
      expect(find.text('Xác thực lại'), findsOneWidget);
      // Không gọi cascade khi reauth fail.
      verifyNever(() => auth.deleteAccountCascade());
    });

    testWidgets(
        'step 2 Google: user dismiss picker (OperationCancelled) → '
        'dialog VẪN mở, KHÔNG hiện lỗi', (tester) async {
      when(() => auth.currentProviderId).thenReturn('google.com');
      when(() => auth.reauthenticateWithGoogle())
          .thenThrow(const OperationCancelledError());

      await openStep2(tester);
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Dialog vẫn mở, không có error message.
      expect(find.text('Xác thực lại'), findsOneWidget);
      expect(
        find.text('Chạm xác nhận để xác thực lại với Google'),
        findsOneWidget,
      );
      verifyNever(() => auth.deleteAccountCascade());
    });

    testWidgets(
        'step 2 Google: reauth success → gọi deleteAccountCascade → pop true',
        (tester) async {
      when(() => auth.currentProviderId).thenReturn('google.com');

      await openStep2(tester);
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      verify(() => auth.reauthenticateWithGoogle()).called(1);
      verify(() => auth.deleteAccountCascade()).called(1);
      expect(find.text('Xác thực lại'), findsNothing);
    });

    testWidgets('step 2: cascade throw → hiện lỗi inline, dialog VẪN mở',
        (tester) async {
      when(() => auth.deleteAccountCascade()).thenThrow(
        const NetworkError(message: 'Mất kết nối khi xóa tài khoản'),
      );

      await openStep2(tester);
      await tester.enterText(find.byType(TextField), 'pwd');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Mất kết nối khi xóa tài khoản'), findsOneWidget);
      expect(find.text('Xác thực lại'), findsOneWidget);
    });
  });
}

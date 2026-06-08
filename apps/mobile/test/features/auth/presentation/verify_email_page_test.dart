import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/auth/presentation/verify_email_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.watchUid()).thenAnswer((_) => const Stream.empty());
    when(() => repo.currentUid).thenReturn('u1');
    when(() => repo.currentProviderId).thenReturn('password');
    when(() => repo.currentEmail).thenReturn('alice@example.com');
    when(() => repo.isEmailVerified).thenReturn(false);
    when(() => repo.reloadUser()).thenAnswer((_) async {});
    when(() => repo.sendEmailVerification()).thenAnswer((_) async {});
  });

  Widget wrap() => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: VerifyEmailPage()),
      );

  testWidgets('renders email + verify + resend affordances', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump(); // settle initState post-frame poll

    expect(find.textContaining('alice@example.com'), findsOneWidget);
    expect(find.text('Tôi đã xác minh'), findsOneWidget);
    expect(find.text('Chưa nhận được email? Gửi lại'), findsOneWidget);
    expect(find.text('Đổi tài khoản'), findsOneWidget);
  });

  testWidgets('tap "Tôi đã xác minh" → reloadUser called', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Tôi đã xác minh'));
    await tester.pump();

    verify(() => repo.reloadUser()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('tap "Gửi lại" → sendEmailVerification + cooldown',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Chưa nhận được email? Gửi lại'));
    await tester.pump();

    verify(() => repo.sendEmailVerification()).called(1);
    // Cooldown kicks in → resend text switches to countdown.
    expect(find.textContaining('Gửi lại sau'), findsOneWidget);
  });

  testWidgets('resend lỗi → hiện message tiếng Việt', (tester) async {
    when(() => repo.sendEmailVerification())
        .thenThrow(const NetworkError(message: 'Không có kết nối mạng'));
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Chưa nhận được email? Gửi lại'));
    await tester.pump();

    expect(find.text('Không có kết nối mạng'), findsOneWidget);
  });

  testWidgets('tap "Đổi tài khoản" → signOut', (tester) async {
    when(() => repo.signOut()).thenAnswer((_) async {});
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Đổi tài khoản'));
    await tester.pump();

    verify(() => repo.signOut()).called(1);
  });
}

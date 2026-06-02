import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/settings/application/blocked_user_view.dart';
import 'package:meep/features/settings/application/blocked_users_provider.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/data/block_repository.dart';
import 'package:meep/features/settings/presentation/blocked_accounts_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBlockRepository extends Mock implements BlockRepository {}

void main() {
  Widget harness(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: BlockedAccountsPage()),
    );
  }

  group('BlockedAccountsPage', () {
    testWidgets('stream rỗng → empty state với CTA tiếng Việt', (tester) async {
      await tester.pumpWidget(
        harness([
          blockedUsersProvider.overrideWith((_) => Stream.value(const [])),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có tài khoản bị chặn nào'), findsOneWidget);
      expect(
        find.text('Bạn có thể chặn một ai đó từ trang Bạn bè'),
        findsOneWidget,
      );
    });

    testWidgets('stream có data → list hiện username + nút Bỏ chặn',
        (tester) async {
      await tester.pumpWidget(
        harness([
          blockedUsersProvider.overrideWith(
            (_) => Stream.value(const [
              BlockedUserView(uid: 'u1', username: 'Lauren'),
            ]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lauren'), findsOneWidget);
      expect(find.text('Bỏ chặn'), findsOneWidget);
      expect(find.text('Tài khoản bị chặn'), findsOneWidget);
    });

    testWidgets('stream error → error state, không crash', (tester) async {
      await tester.pumpWidget(
        harness([
          blockedUsersProvider.overrideWith(
            (_) => Stream.error(Exception('network down')),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Không thể tải danh sách'),
        findsOneWidget,
      );
    });

    testWidgets('tap "Bỏ chặn" → confirm dialog → [Xác nhận] → gọi controller',
        (tester) async {
      final block = MockBlockRepository();
      final auth = MockAuthRepository();
      when(() => auth.currentUid).thenReturn('me');
      when(
        () => block.unblockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        harness([
          authRepositoryProvider.overrideWithValue(auth),
          blockRepositoryProvider.overrideWithValue(block),
          blockedUsersProvider.overrideWith(
            (_) => Stream.value(const [
              BlockedUserView(uid: 'target', username: 'Lauren'),
            ]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc muốn bỏ chặn tài khoản này không?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      verify(() => block.unblockUser(blockerUid: 'me', targetUid: 'target'))
          .called(1);
    });

    testWidgets('[Huỷ] dialog → không gọi controller, list giữ nguyên',
        (tester) async {
      final block = MockBlockRepository();
      final auth = MockAuthRepository();
      when(() => auth.currentUid).thenReturn('me');

      await tester.pumpWidget(
        harness([
          authRepositoryProvider.overrideWithValue(auth),
          blockRepositoryProvider.overrideWithValue(block),
          blockedUsersProvider.overrideWith(
            (_) => Stream.value(const [
              BlockedUserView(uid: 'target', username: 'Lauren'),
            ]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      verifyNever(
        () => block.unblockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      );
      expect(find.text('Lauren'), findsOneWidget);
    });
  });
}

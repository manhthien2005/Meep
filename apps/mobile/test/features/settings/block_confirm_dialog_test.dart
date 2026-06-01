import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/settings/application/settings_controller.dart';
import 'package:meep/features/settings/data/block_repository.dart';
import 'package:meep/features/settings/presentation/block_confirm_dialog.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBlockRepository extends Mock implements BlockRepository {}

void main() {
  Widget harness(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => BlockConfirmDialog.show(
                  context,
                  targetUid: 'target-uid',
                  targetName: 'Lauren',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('BlockConfirmDialog', () {
    late MockAuthRepository auth;
    late MockBlockRepository block;

    setUp(() {
      auth = MockAuthRepository();
      block = MockBlockRepository();
      when(() => auth.currentUid).thenReturn('me');
    });

    testWidgets('render — title Chặn {name} + nút Chặn + Bỏ qua',
        (tester) async {
      when(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        harness([
          authRepositoryProvider.overrideWithValue(auth),
          blockRepositoryProvider.overrideWithValue(block),
        ]),
      );
      await openDialog(tester);

      expect(find.text('Chặn Lauren?'), findsOneWidget);
      expect(find.text('Chặn'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
    });

    testWidgets(
        'tap Chặn → gọi controller.blockUser(targetUid) → button đổi "Đã chặn!"',
        (tester) async {
      when(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        harness([
          authRepositoryProvider.overrideWithValue(auth),
          blockRepositoryProvider.overrideWithValue(block),
        ]),
      );
      await openDialog(tester);

      await tester.tap(find.text('Chặn'));
      await tester.pumpAndSettle();

      verify(
        () => block.blockUser(blockerUid: 'me', targetUid: 'target-uid'),
      ).called(1);
      expect(find.text('Đã chặn!'), findsOneWidget);
      expect(find.text('Chặn'), findsNothing);
    });

    testWidgets('controller throw error → button giữ "Chặn", cho phép retry',
        (tester) async {
      when(
        () => block.blockUser(
          blockerUid: any(named: 'blockerUid'),
          targetUid: any(named: 'targetUid'),
        ),
      ).thenThrow(ForbiddenError('chặn người dùng'));

      await tester.pumpWidget(
        harness([
          authRepositoryProvider.overrideWithValue(auth),
          blockRepositoryProvider.overrideWithValue(block),
        ]),
      );
      await openDialog(tester);

      await tester.tap(find.text('Chặn'));
      await tester.pumpAndSettle();

      // Vẫn nút "Chặn", KHÔNG đổi "Đã chặn!"
      expect(find.text('Chặn'), findsOneWidget);
      expect(find.text('Đã chặn!'), findsNothing);
    });
  });
}

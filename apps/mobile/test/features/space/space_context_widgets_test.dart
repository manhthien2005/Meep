import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_repository.dart';
import 'package:meep/features/space/presentation/space_context_bottom_sheet.dart';
import 'package:meep/features/space/presentation/widgets/space_context_badge.dart';
import 'package:meep/features/space/presentation/widgets/space_list_tile.dart';

class MockSpaceRepository extends Mock implements SpaceRepository {}

/// Subclass override `build()` để inject Space initial value cho test.
/// Riverpod codegen notifier `overrideWith` cần factory tạo notifier mới
/// với build() returning desired state — không thể set state ngoài lifecycle.
class _TestCurrentSpace extends CurrentSpace {
  _TestCurrentSpace(this.initialValue);

  final Space? initialValue;

  @override
  Space? build() => initialValue;
}

Space _spaceFixture({
  required String spaceId,
  String name = 'Family',
  String iconEmoji = '👨‍👩‍👧‍👦',
  String colorHex = '#BFD5FF',
  int memberCount = 3,
}) {
  return Space(
    spaceId: spaceId,
    name: name,
    iconEmoji: iconEmoji,
    colorHex: colorHex,
    creatorId: 'creator',
    memberCount: memberCount,
    memberIds: const ['creator', 'm2', 'm3'],
    createdAt: DateTime(2026, 6, 1),
  );
}

void main() {
  group('SpaceContextBadge', () {
    testWidgets('renders SizedBox.shrink when currentSpace is null',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SpaceContextBadge()),
          ),
        ),
      );

      expect(find.text('Đang gửi: Family'), findsNothing);
      expect(find.byType(SpaceContextBadge), findsOneWidget);
    });

    testWidgets('shows "Đang gửi: [name]" + emoji when Space is active',
        (tester) async {
      final space =
          _spaceFixture(spaceId: 's1', name: 'Family', iconEmoji: '🏠');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSpaceProvider.overrideWith(() => _TestCurrentSpace(space)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceContextBadge()),
          ),
        ),
      );

      expect(find.text('Đang gửi: Family'), findsOneWidget);
      expect(find.text('🏠'), findsOneWidget);
    });
  });

  group('SpaceListTile', () {
    testWidgets('renders "Tất cả bạn bè" when space is null', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceListTile(
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Tất cả bạn bè'), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      // Selected check
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.byType(SpaceListTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders Space name + memberCount when space is non-null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceListTile(
              space: _spaceFixture(spaceId: 's1', name: 'Trip', memberCount: 5),
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('5 thành viên'), findsOneWidget);
      // Not selected → no check icon
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('parse colorHex hợp lệ → icon background dùng đúng color',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceListTile(
              space: _spaceFixture(spaceId: 's1', colorHex: '#FF5733'),
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find Container có color = parsed #FF5733
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasColored = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is! BoxDecoration) return false;
        return decoration.color == const Color(0xFFFF5733);
      });
      expect(hasColored, isTrue);
    });
  });

  group('SpaceContextBottomSheet', () {
    setUpAll(() {
      // mocktail fallback cho String stream arg.
      registerFallbackValue('');
    });

    testWidgets('shows "Chưa đăng nhập" when uid is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceContextBottomSheet()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Chưa đăng nhập'), findsOneWidget);
    });

    testWidgets('shows empty state when user has 0 spaces', (tester) async {
      final repo = MockSpaceRepository();
      when(() => repo.watchMySpaces(any())).thenAnswer(
        (_) => Stream.value(<Space>[]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('user1')),
            spaceRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceContextBottomSheet()),
          ),
        ),
      );
      await tester.pump(); // resolve currentUidProvider
      await tester.pump(); // resolve stream

      expect(find.text('Tất cả bạn bè'), findsOneWidget);
      expect(find.text('Bạn chưa tham gia Space nào'), findsOneWidget);
    });

    testWidgets(
        'lists All friends + user spaces; selection check on current Space',
        (tester) async {
      final repo = MockSpaceRepository();
      final spaces = [
        _spaceFixture(spaceId: 's1', name: 'Family'),
        _spaceFixture(spaceId: 's2', name: 'Trip', memberCount: 5),
      ];
      when(() => repo.watchMySpaces(any())).thenAnswer(
        (_) => Stream.value(spaces),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('user1')),
            spaceRepositoryProvider.overrideWithValue(repo),
            currentSpaceProvider
                .overrideWith(() => _TestCurrentSpace(spaces[0])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceContextBottomSheet()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Tất cả bạn bè'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      // Family is selected → 1 check_circle icon trong list.
      // (All friends row also có thể có check, nhưng Family is current so
      // chỉ Family tile có check.)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}

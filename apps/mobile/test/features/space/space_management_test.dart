import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/data/space_member.dart';
import 'package:meep/features/space/data/space_repository.dart';
import 'package:meep/features/space/presentation/space_management_sheet.dart';
import 'package:meep/features/space/presentation/widgets/delete_space_dialog.dart';
import 'package:meep/features/space/presentation/widgets/kick_member_dialog.dart';
import 'package:meep/features/space/presentation/widgets/leave_space_dialog.dart';

class MockSpaceRepository extends Mock implements SpaceRepository {}

Space _spaceFixture({
  required String spaceId,
  required String creatorId,
  String name = 'Family',
  List<String>? memberIds,
}) {
  return Space(
    spaceId: spaceId,
    name: name,
    iconEmoji: '👨‍👩‍👧‍👦',
    colorHex: '#BFD5FF',
    creatorId: creatorId,
    memberCount: memberIds?.length ?? 1,
    memberIds: memberIds ?? [creatorId],
    createdAt: DateTime(2026, 6, 1),
  );
}

SpaceMember _memberFixture({required String uid, bool isCreator = false}) {
  return SpaceMember(
    uid: uid,
    role: isCreator ? SpaceRole.creator : SpaceRole.member,
    joinedAt: DateTime(2026, 6, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('SpaceManagementSheet — role-based actions', () {
    testWidgets('member sees only "Rời khỏi Space" button', (tester) async {
      final repo = MockSpaceRepository();
      final space = _spaceFixture(
        spaceId: 's1',
        creatorId: 'alice',
        memberIds: ['alice', 'bob'],
      );
      when(() => repo.watchSpace(any())).thenAnswer(
        (_) => Stream.value(space),
      );
      when(() => repo.watchMembers(any())).thenAnswer(
        (_) => Stream.value([
          _memberFixture(uid: 'alice', isCreator: true),
          _memberFixture(uid: 'bob'),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spaceRepositoryProvider.overrideWithValue(repo),
            currentUidProvider.overrideWith((ref) => Stream.value('bob')),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceManagementSheet(spaceId: 's1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quản lý Family'), findsOneWidget);
      expect(find.text('Rời khỏi Space'), findsOneWidget);
      // Creator-only actions should be hidden
      expect(find.text('Xoá thành viên'), findsNothing);
      expect(find.text('Xoá Space'), findsNothing);
    });

    testWidgets('creator sees all 3 actions', (tester) async {
      final repo = MockSpaceRepository();
      final space = _spaceFixture(
        spaceId: 's1',
        creatorId: 'alice',
        memberIds: ['alice', 'bob'],
      );
      when(() => repo.watchSpace(any())).thenAnswer(
        (_) => Stream.value(space),
      );
      when(() => repo.watchMembers(any())).thenAnswer(
        (_) => Stream.value([
          _memberFixture(uid: 'alice', isCreator: true),
          _memberFixture(uid: 'bob'),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spaceRepositoryProvider.overrideWithValue(repo),
            currentUidProvider.overrideWith((ref) => Stream.value('alice')),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceManagementSheet(spaceId: 's1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi Space'), findsOneWidget);
      expect(find.text('Xoá thành viên'), findsOneWidget);
      expect(find.text('Xoá Space'), findsOneWidget);
    });

    testWidgets('shows deleted body when watchSpace emits null',
        (tester) async {
      final repo = MockSpaceRepository();
      when(() => repo.watchSpace(any())).thenAnswer(
        (_) => Stream.value(null),
      );
      when(() => repo.watchMembers(any())).thenAnswer(
        (_) => Stream.value(<SpaceMember>[]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spaceRepositoryProvider.overrideWithValue(repo),
            currentUidProvider.overrideWith((ref) => Stream.value('alice')),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceManagementSheet(spaceId: 's1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Space đã bị xoá hoặc bạn không còn quyền truy cập.'),
        findsOneWidget,
      );
    });
  });

  group('Confirm dialogs', () {
    testWidgets('showLeaveSpaceDialog returns true on confirm', (tester) async {
      late Future<bool> resultFuture;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  resultFuture = showLeaveSpaceDialog(
                    context,
                    spaceName: 'Family',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Rời khỏi Family?'), findsOneWidget);
      await tester.tap(find.text('Rời khỏi'));
      await tester.pumpAndSettle();

      expect(await resultFuture, isTrue);
    });

    testWidgets('showLeaveSpaceDialog returns false on cancel', (tester) async {
      late Future<bool> resultFuture;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  resultFuture = showLeaveSpaceDialog(
                    context,
                    spaceName: 'Family',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(await resultFuture, isFalse);
    });

    testWidgets('showDeleteSpaceDialog has warning copy + destructive label',
        (tester) async {
      late Future<bool> resultFuture;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  resultFuture = showDeleteSpaceDialog(
                    context,
                    spaceName: 'Trip',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Xoá Trip?'), findsOneWidget);
      expect(find.textContaining('không thể hoàn tác'), findsOneWidget);
      expect(find.text('Xoá Space'), findsOneWidget);

      await tester.tap(find.text('Xoá Space'));
      await tester.pumpAndSettle();
      expect(await resultFuture, isTrue);
    });
  });

  group('showKickMemberDialog', () {
    testWidgets('returns null khi candidates rỗng (chỉ có creator)',
        (tester) async {
      late Future<String?> resultFuture;
      final space = _spaceFixture(spaceId: 's1', creatorId: 'alice');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  resultFuture = showKickMemberDialog(
                    context,
                    space: space,
                    members: [_memberFixture(uid: 'alice', isCreator: true)],
                    displayNames: const {'alice': 'Alice'},
                    avatarUrls: const {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(await resultFuture, isNull);
      // No dialog rendered — không có member nào để kick.
      expect(find.text('Xoá thành viên'), findsNothing);
    });

    testWidgets('picker → confirm → returns picked uid', (tester) async {
      late Future<String?> resultFuture;
      final space = _spaceFixture(
        spaceId: 's1',
        creatorId: 'alice',
        memberIds: ['alice', 'bob'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  resultFuture = showKickMemberDialog(
                    context,
                    space: space,
                    members: [
                      _memberFixture(uid: 'alice', isCreator: true),
                      _memberFixture(uid: 'bob'),
                    ],
                    displayNames: const {'alice': 'Alice', 'bob': 'Bob'},
                    avatarUrls: const {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Picker hiện chỉ Bob (alice = creator filtered).
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      // Confirm dialog hiện với name của Bob.
      expect(find.text('Xoá Bob khỏi Space?'), findsOneWidget);
      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();

      expect(await resultFuture, 'bob');
    });
  });
}

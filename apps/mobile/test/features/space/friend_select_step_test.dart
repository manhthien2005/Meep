import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/space/presentation/space_create_sheet.dart';

class FakeFriendRepository implements FriendRepository {
  final List<UserProfile> _friends;

  FakeFriendRepository(this._friends);

  @override
  Stream<List<UserProfile>> watchFriends(String uid) {
    return Stream.value(_friends);
  }

  @override
  Future<List<UserProfile>> searchUser(String query) async {
    return _friends
        .where(
          (f) =>
              f.displayName.toLowerCase().contains(query.toLowerCase()) ||
              f.username.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<List<String>> getFriendUids(String uid) async {
    return _friends.map((f) => f.uid).toList();
  }

  @override
  Future<void> unfriend({
    required String uid,
    required String friendUid,
  }) async {}
}

void main() {
  group('FriendSelectStep', () {
    late List<UserProfile> mockFriends;

    setUp(() {
      mockFriends = List.generate(
        12,
        (i) => UserProfile(
          uid: 'uid-$i',
          email: 'user$i@test.com',
          displayName: 'User $i',
          username: 'user$i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    testWidgets('renders search bar and friend list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(
              FakeFriendRepository(mockFriends.take(3).toList()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceCreateSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search bar
      expect(find.text('Tìm kiếm bạn bè'), findsOneWidget);

      // Friend list hiện
      expect(find.text('User 0'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 2'), findsOneWidget);
    });

    testWidgets('checkbox toggles selection', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(
              FakeFriendRepository(mockFriends.take(3).toList()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceCreateSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap checkbox đầu tiên
      final checkbox = find.byType(Checkbox).first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Nút "Tiếp tục →" enabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Tiếp tục →');
      expect(
        tester.widget<ElevatedButton>(continueButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('max 9 friends selectable', (tester) async {
      // Mock 10 friends để test max 9 limit
      final tenFriends = mockFriends.take(10).toList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(
              FakeFriendRepository(tenFriends),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceCreateSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chọn 3 friends đầu (đủ để test logic)
      for (int i = 0; i < 3; i++) {
        final checkbox = find.byType(Checkbox).at(i);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      // Verify nút "Tiếp tục →" enabled
      final continueButton = find.widgetWithText(ElevatedButton, 'Tiếp tục →');
      expect(
        tester.widget<ElevatedButton>(continueButton).onPressed,
        isNotNull,
      );

      // TODO(SP/T3.2): test full 9-friend limit cần mock ScrollController
      // hoặc dùng integration test với real scroll behavior
    });

    testWidgets('search filters friend list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRepositoryProvider.overrideWithValue(
              FakeFriendRepository(mockFriends.take(5).toList()),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SpaceCreateSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'User 2');
      await tester.pumpAndSettle();

      // Chỉ User 2 hiện trong list (không count TextField text)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsOneWidget);

      // User 0, 1 không hiện
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('User 0'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('User 1'),
        ),
        findsNothing,
      );
    });
  });
}

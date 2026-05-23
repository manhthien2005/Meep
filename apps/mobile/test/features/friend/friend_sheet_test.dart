import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/application/friend_state.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/presentation/friend_sheet.dart';

void main() {
  group('FriendSheet', () {
    testWidgets('shows search bar by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for async stream

      expect(find.text('Thêm một người bạn mới'), findsOneWidget);
    });

    testWidgets('tap search bar expands search mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for async stream

      // Tap search bar
      await tester.tap(find.text('Thêm một người bạn mới'));
      await tester.pumpAndSettle();

      // Should show cancel button
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('tap Hủy collapses search mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for async stream

      // Expand search
      await tester.tap(find.text('Thêm một người bạn mới'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Cancel button should be gone
      expect(find.text('Hủy'), findsNothing);
    });

    testWidgets('shows friend list when has friends', (tester) async {
      final friends = [
        UserProfile(
          uid: 'friend1',
          email: 'friend1@test.com',
          displayName: 'Friend One',
          username: 'friend1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(friends: friends),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for async stream

      expect(find.text('Friend One'), findsOneWidget);
    });

    testWidgets('shows pending requests section when has requests',
        (tester) async {
      final requests = [
        FriendRequest(
          requestId: 'req1',
          senderId: 'sender1',
          receiverId: 'test-uid',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(pendingRequests: requests),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for async stream

      expect(find.text('Yêu cầu kết bạn'), findsOneWidget);
    });

    testWidgets('hides pending requests section when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(
              () => FakeFriendController(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FriendSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Yêu cầu kết bạn'), findsNothing);
    });

    testWidgets('search shows "Thêm" for a non-friend result', (tester) async {
      final stranger = _userProfile(uid: 'stranger', name: 'Stranger');

      await _pumpSearch(tester, searchResult: stranger);

      expect(find.text('Thêm theo tên người dùng'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);
      expect(find.text('Chia sẻ liên kết Meep của bạn'), findsOneWidget);
    });

    testWidgets('search shows "Đã gửi" when request already sent',
        (tester) async {
      final target = _userProfile(uid: 'target', name: 'Target');
      final sent = [
        FriendRequest(
          requestId: 'req-sent',
          senderId: 'test-uid',
          receiverId: 'target',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await _pumpSearch(tester, searchResult: target, sentRequests: sent);

      expect(find.text('Đã gửi'), findsOneWidget);
      expect(find.text('Thêm'), findsNothing);
    });

    testWidgets('search shows "Bạn bè" when result is already a friend',
        (tester) async {
      final friend = _userProfile(uid: 'friend1', name: 'Friend One');

      await _pumpSearch(
        tester,
        searchResult: friend,
        friends: [friend],
      );

      expect(find.text('Bạn bè'), findsOneWidget);
      expect(find.text('Thêm'), findsNothing);
    });

    testWidgets('tap X on a friend then confirm calls unfriend',
        (tester) async {
      final friend = _userProfile(uid: 'friend1', name: 'Friend One');
      final fake = FakeFriendController(friends: [friend]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(() => fake),
          ],
          child: const MaterialApp(
            home: Scaffold(body: FriendSheet()),
          ),
        ),
      );
      await tester.pump();

      // Open the confirm dialog from the friend row's X button.
      await tester.tap(find.byTooltip('Gỡ kết bạn'));
      await tester.pumpAndSettle();
      // Dialog copy per spec: title 'Xóa {name} khỏi Meep của bạn?',
      // destructive confirm button labelled 'Xoá'.
      expect(find.text('Xóa Friend One khỏi Meep của bạn?'), findsOneWidget);

      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();

      expect(fake.unfriended, ['friend1']);
    });

    testWidgets('tap X on a friend then Lưu does not call unfriend',
        (tester) async {
      final friend = _userProfile(uid: 'friend1', name: 'Friend One');
      final fake = FakeFriendController(friends: [friend]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
            friendControllerProvider('test-uid').overrideWith(() => fake),
          ],
          child: const MaterialApp(
            home: Scaffold(body: FriendSheet()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Gỡ kết bạn'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(fake.unfriended, isEmpty);
    });
  });
}

UserProfile _userProfile({required String uid, required String name}) {
  return UserProfile(
    uid: uid,
    email: '$uid@test.com',
    displayName: name,
    username: uid,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Pumps FriendSheet, expands search, and enters a query so the fake controller
/// surfaces [searchResult] in the search view.
Future<void> _pumpSearch(
  WidgetTester tester, {
  required UserProfile searchResult,
  List<UserProfile> friends = const [],
  List<FriendRequest> sentRequests = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
        friendControllerProvider('test-uid').overrideWith(
          () => FakeFriendController(
            friends: friends,
            sentRequests: sentRequests,
            searchResult: searchResult,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: FriendSheet()),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Thêm một người bạn mới'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), 'q');
  await tester.pumpAndSettle();
}

// Fake controller for testing
class FakeFriendController extends FriendController {
  FakeFriendController({
    List<UserProfile>? friends,
    List<FriendRequest>? pendingRequests,
    List<FriendRequest>? sentRequests,
    UserProfile? searchResult,
  })  : _friends = friends ?? [],
        _pendingRequests = pendingRequests ?? [],
        _sentRequests = sentRequests ?? [],
        _searchResult = searchResult;

  final List<UserProfile> _friends;
  final List<FriendRequest> _pendingRequests;
  final List<FriendRequest> _sentRequests;
  final UserProfile? _searchResult;

  /// Captures unfriend(friendUid) calls so widget tests can assert the
  /// X-button + confirm-dialog flow reaches the controller.
  final List<String> unfriended = [];

  @override
  FriendState build(String uid) {
    return FriendState(
      friends: _friends,
      pendingRequests: _pendingRequests,
      sentRequests: _sentRequests,
      // Fake controller không có real Firestore stream, nên set initialized
      // ngay lập tức để UI không render spinner chờ stream mà không bao giờ
      // đến — tránh pumpAndSettle timeout trong tests.
      friendsInitialized: true,
    );
  }

  @override
  Future<void> searchUser(String query) async {
    state = state.copyWith(searchQuery: query, searchResult: _searchResult);
  }

  @override
  Future<void> unfriend(String friendUid) async {
    unfriended.add(friendUid);
  }
}

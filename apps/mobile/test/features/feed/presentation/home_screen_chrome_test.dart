import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/chat/application/chat_controller.dart';
import 'package:meep/features/chat/data/conversation.dart';
import 'package:meep/features/chat/data/conversation_repository.dart';
import 'package:meep/features/chat/data/message.dart';
import 'package:meep/features/feed/application/app_camera_controller.dart';
import 'package:meep/features/feed/application/camera_state.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';
import 'package:meep/features/feed/presentation/home_screen.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';
import 'package:meep/shared/models/post.dart';
import 'package:meep/shared/widgets/app_photo_frame.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

class _FakeCameraController extends AppCameraController {
  @override
  CameraState build() => const CameraState(
        error: 'Camera disabled in widget tests',
      );

  @override
  Future<void> initialize() async {}

  @override
  void resumePreview() {}

  @override
  void stopPreview() {}
}

class _FakePostRepository implements PostRepository {
  @override
  String newPostId() => 'post-id';

  @override
  Future<Post> createPost(Post post) async => post;

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<List<Post>> getPostsByAuthor(String authorId) async => const [];

  @override
  Future<Post?> getPost(String postId) async => null;

  @override
  Stream<List<Post>> watchFeed(String uid, {String? spaceId}) {
    return Stream.value(const []);
  }
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<void> deleteImage(String storagePath) async {}

  @override
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName = 'photo.jpg',
  }) async {
    return 'https://example.com/photo.jpg';
  }
}

class _FakeFriendRepository implements FriendRepository {
  @override
  Future<List<String>> getFriendUids(String uid) async => const [];

  @override
  Future<PublicProfile?> searchUser(String username) async => null;

  @override
  Future<void> unfriend(String pairId) async {}

  @override
  Stream<List<PublicProfile>> watchFriends(String uid) {
    return Stream.value(const []);
  }
}

class _FakeFriendRequestRepository implements FriendRequestRepository {
  @override
  Future<void> acceptFriendRequest(String requestId) async {}

  @override
  Future<void> cancelFriendRequest(String requestId) async {}

  @override
  Future<void> declineFriendRequest(String requestId) async {}

  @override
  Future<void> sendFriendRequest({
    required String senderUid,
    required String receiverUid,
  }) async {}

  @override
  Stream<List<FriendRequest>> watchPendingRequests(String receiverUid) {
    return Stream.value(const []);
  }

  @override
  Stream<List<FriendRequest>> watchSentRequests(String senderUid) {
    return Stream.value(const []);
  }
}

class _FakeConversationRepository implements ConversationRepository {
  @override
  Future<Conversation> getOrCreateConversation({
    required String uid,
    required String otherUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {}

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? senderDisplayName,
    String? quotedPostId,
  }) async {}

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    return Stream.value(const []);
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId, {int limit = 50}) {
    return Stream.value(const []);
  }
}

UserProfile _profile() {
  final now = DateTime.utc(2026, 6, 9);
  return UserProfile(
    uid: 'uid-me',
    email: 'me@example.com',
    displayName: 'Meep User',
    username: 'meep',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetDataService widgetDataService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    widgetDataService = WidgetDataService(prefs: prefs);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appCameraControllerProvider.overrideWith(_FakeCameraController.new),
          currentUidProvider.overrideWith((ref) => Stream.value('uid-me')),
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(_profile())),
          postRepositoryProvider.overrideWithValue(_FakePostRepository()),
          storageRepositoryProvider.overrideWithValue(_FakeStorageRepository()),
          friendRepositoryProvider.overrideWithValue(_FakeFriendRepository()),
          friendRequestRepositoryProvider
              .overrideWithValue(_FakeFriendRequestRepository()),
          conversationRepositoryProvider
              .overrideWithValue(_FakeConversationRepository()),
          widgetDataServiceProvider.overrideWithValue(widgetDataService),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('topbar and taskbar overlay the full-height PageView',
      (tester) async {
    await pumpHome(tester);

    final pageViewRect = tester.getRect(find.byKey(const Key('homePageView')));
    final topbarRect = tester.getRect(find.byKey(const Key('homeTopBar')));
    final taskbarRect = tester.getRect(find.byKey(const Key('homeTaskbar')));
    final frameRect = tester.getRect(find.byType(AppPhotoFrame));

    expect(pageViewRect.top, 0);
    expect(pageViewRect.bottom, tester.view.physicalSize.height);
    expect(pageViewRect.top, lessThan(topbarRect.bottom));
    expect(frameRect.top, greaterThan(topbarRect.bottom + 8));
    expect(pageViewRect.bottom, greaterThan(taskbarRect.top));
    expect(
      taskbarRect.top,
      greaterThan(tester.view.physicalSize.height * 0.75),
    );
    expect(find.byType(AppTaskbar), findsOneWidget);
  });
}

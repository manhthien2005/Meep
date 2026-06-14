import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/auth/data/auth_repository.dart';
import 'package:meep/features/auth/data/public_profile.dart';
import 'package:meep/features/auth/data/user_profile.dart';
import 'package:meep/features/auth/data/user_repository.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';
import 'package:meep/features/friend/application/friend_controller.dart';
import 'package:meep/features/friend/data/friend_repository.dart';
import 'package:meep/features/friend/data/friend_request.dart';
import 'package:meep/features/friend/data/friend_request_repository.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';
import 'package:meep/shared/models/post.dart';

class MeepIntegrationHarness {
  MeepIntegrationHarness._({
    required this.container,
    required this.auth,
    required this.users,
    required this.posts,
    required this.friends,
    required this.friendRequests,
    required this.reactions,
  });

  final ProviderContainer container;
  final InMemoryAuthRepository auth;
  final InMemoryUserRepository users;
  final InMemoryPostRepository posts;
  final InMemoryFriendRepository friends;
  final InMemoryFriendRequestRepository friendRequests;
  final InMemoryReactionRepository reactions;

  static Future<MeepIntegrationHarness> create({
    UserProfile? signedInProfile,
    Iterable<PublicProfile> publicProfiles = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final auth = InMemoryAuthRepository();
    final users = InMemoryUserRepository();
    final posts = InMemoryPostRepository();
    final friends = InMemoryFriendRepository(users);
    final friendRequests = InMemoryFriendRequestRepository();
    final reactions = InMemoryReactionRepository();

    for (final profile in publicProfiles) {
      users.seedPublicProfile(profile);
    }
    if (signedInProfile != null) {
      users.seedProfile(signedInProfile);
      auth.seedSignedIn(
        uid: signedInProfile.uid,
        email: signedInProfile.email,
        displayName: signedInProfile.displayName,
      );
    }

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users),
        postRepositoryProvider.overrideWithValue(posts),
        storageRepositoryProvider.overrideWithValue(
          const InMemoryStorageRepository(),
        ),
        postImageCompressorProvider.overrideWithValue(
          (_) async => const [0xFF, 0xD8, 0xFF],
        ),
        friendRepositoryProvider.overrideWithValue(friends),
        friendRequestRepositoryProvider.overrideWithValue(friendRequests),
        reactionRepositoryProvider.overrideWithValue(reactions),
        widgetDataServiceProvider.overrideWithValue(
          WidgetDataService(prefs: prefs),
        ),
      ],
    );

    return MeepIntegrationHarness._(
      container: container,
      auth: auth,
      users: users,
      posts: posts,
      friends: friends,
      friendRequests: friendRequests,
      reactions: reactions,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await auth.dispose();
    await users.dispose();
    await posts.dispose();
    await friendRequests.dispose();
    await reactions.dispose();
  }
}

class InMemoryAuthRepository implements AuthRepository {
  final _uidController = StreamController<String?>.broadcast();
  final _accounts = <String, _Account>{};

  _Account? _current;
  int verificationEmailCount = 0;

  @override
  String? get currentUid => _current?.uid;

  @override
  String? get currentEmail => _current?.email;

  @override
  String? get currentDisplayName => _current?.displayName;

  @override
  bool get isEmailVerified => _current?.emailVerified ?? false;

  @override
  String? get currentProviderId => _current == null ? null : 'password';

  void seedSignedIn({
    required String uid,
    required String email,
    required String displayName,
    String password = 'pass1234',
  }) {
    final account = _Account(
      uid: uid,
      email: email,
      password: password,
      displayName: displayName,
      emailVerified: true,
    );
    _accounts[email] = account;
    _current = account;
  }

  @override
  Stream<String?> watchUid() async* {
    yield _current?.uid;
    yield* _uidController.stream;
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      throw const ValidationError(message: 'Email already exists');
    }
    final uid =
        'uid-${email.split('@').first.replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    final account = _Account(
      uid: uid,
      email: email,
      password: password,
      displayName: '',
      emailVerified: false,
    );
    _accounts[email] = account;
    _current = account;
    _uidController.add(uid);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const UnauthenticatedError(message: 'Sai email hoặc mật khẩu');
    }
    _current = account;
    _uidController.add(account.uid);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _uidController.add(null);
  }

  @override
  Future<bool> isEmailAvailable(String email) async =>
      !_accounts.containsKey(email);

  @override
  Future<void> sendEmailVerification() async {
    if (_current == null) throw const UnauthenticatedError();
    verificationEmailCount++;
  }

  @override
  Future<void> deleteCurrentUser() async {
    final current = _current;
    if (current == null) return;
    _accounts.remove(current.email);
    await signOut();
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> revalidateSession() async {}

  @override
  Future<void> signInWithGoogle() async {
    throw const OperationCancelledError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<String> verifyPasswordResetCode({required String oobCode}) async =>
      currentEmail ?? 'test@example.com';

  @override
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {}

  @override
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {}

  @override
  Future<void> reauthenticateWithPassword(String password) async {}

  @override
  Future<void> reauthenticateWithGoogle() async {}

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> deleteAccountCascade() async {
    await deleteCurrentUser();
  }

  Future<void> dispose() => _uidController.close();
}

class _Account {
  _Account({
    required this.uid,
    required this.email,
    required this.password,
    required this.displayName,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final String password;
  final String displayName;
  final bool emailVerified;
}

class InMemoryUserRepository implements UserRepository {
  final _profiles = <String, UserProfile>{};
  final _publicProfiles = <String, PublicProfile>{};
  final _profileControllers = <String, StreamController<UserProfile?>>{};
  final _publicControllers = <String, StreamController<PublicProfile?>>{};

  void seedProfile(UserProfile profile) {
    _profiles[profile.uid] = profile;
    seedPublicProfile(
      PublicProfile(
        uid: profile.uid,
        displayName: profile.displayName,
        username: profile.username,
        avatarUrl: profile.avatarUrl,
        updatedAt: profile.updatedAt,
      ),
    );
  }

  void seedPublicProfile(PublicProfile profile) {
    _publicProfiles[profile.uid] = profile;
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
    final publicProfile = PublicProfile(
      uid: profile.uid,
      displayName: profile.displayName,
      username: profile.username,
      avatarUrl: profile.avatarUrl,
      updatedAt: profile.updatedAt,
    );
    _publicProfiles[profile.uid] = publicProfile;
    _profileController(profile.uid).add(profile);
    _publicController(profile.uid).add(publicProfile);
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => _profiles[uid];

  @override
  Future<PublicProfile?> getPublicProfile(String uid) async =>
      _publicProfiles[uid];

  @override
  Future<bool> isUsernameAvailable(String username) async =>
      !_publicProfiles.values.any((p) => p.username == username);

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profiles[uid];
    yield* _profileController(uid).stream;
  }

  @override
  Stream<PublicProfile?> watchPublicProfile(String uid) async* {
    yield _publicProfiles[uid];
    yield* _publicController(uid).stream;
  }

  StreamController<UserProfile?> _profileController(String uid) =>
      _profilesControllerFor(uid, _profileControllers);

  StreamController<PublicProfile?> _publicController(String uid) =>
      _profilesControllerFor(uid, _publicControllers);

  StreamController<T?> _profilesControllerFor<T>(
    String uid,
    Map<String, StreamController<T?>> controllers,
  ) =>
      controllers.putIfAbsent(uid, () => StreamController<T?>.broadcast());

  Future<void> dispose() async {
    for (final controller in _profileControllers.values) {
      await controller.close();
    }
    for (final controller in _publicControllers.values) {
      await controller.close();
    }
  }
}

class InMemoryPostRepository implements PostRepository {
  final _feedController = StreamController<List<Post>>.broadcast();
  final _posts = <Post>[];
  int _nextPost = 1;

  List<Post> get createdPosts => List.unmodifiable(_posts);

  void seedPost(Post post) {
    _posts.add(post);
    _emit();
  }

  @override
  String newPostId() => 'post-${_nextPost++}';

  @override
  Future<Post> createPost(Post post) async {
    _posts.add(post);
    _emit();
    return post;
  }

  @override
  Stream<List<Post>> watchFeed(String uid, {String? spaceId}) async* {
    yield _visiblePosts(uid, spaceId: spaceId);
    yield* _feedController.stream.map(
      (_) => _visiblePosts(uid, spaceId: spaceId),
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post.postId == postId);
    _emit();
  }

  @override
  Future<List<Post>> getPostsByAuthor(String authorId) async =>
      _posts.where((post) => post.authorId == authorId).toList();

  @override
  Future<Post?> getPost(String postId) async {
    for (final post in _posts) {
      if (post.postId == postId) return post;
    }
    return null;
  }

  List<Post> _visiblePosts(String uid, {String? spaceId}) {
    final filtered = spaceId == null
        ? _posts
        : _posts.where((post) => post.spaceIds.contains(spaceId));
    final result = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  void _emit() => _feedController.add(List.unmodifiable(_posts));

  Future<void> dispose() => _feedController.close();
}

class InMemoryStorageRepository implements StorageRepository {
  const InMemoryStorageRepository();

  @override
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName = 'photo.jpg',
  }) async =>
      'memory://posts/$uid/$postId/$fileName';

  @override
  Future<void> deleteImage(String storagePath) async {}
}

class InMemoryFriendRepository implements FriendRepository {
  InMemoryFriendRepository(this._users);

  final InMemoryUserRepository _users;
  final _friendsByUid = <String, List<PublicProfile>>{};

  void seedFriend(String uid, PublicProfile friend) {
    _friendsByUid.update(
      uid,
      (friends) => [...friends, friend],
      ifAbsent: () => [friend],
    );
  }

  @override
  Future<PublicProfile?> searchUser(String username) async {
    final lower = username.toLowerCase();
    for (final profile in _users._publicProfiles.values) {
      if (profile.username == lower) return profile;
    }
    return null;
  }

  @override
  Stream<List<PublicProfile>> watchFriends(String uid) =>
      Stream.value(List.unmodifiable(_friendsByUid[uid] ?? const []));

  @override
  Future<List<String>> getFriendUids(String uid) async =>
      (_friendsByUid[uid] ?? const []).map((profile) => profile.uid).toList();

  @override
  Future<void> unfriend(String pairId) async {}
}

class InMemoryFriendRequestRepository implements FriendRequestRepository {
  final _requests = <FriendRequest>[];
  final _changes = StreamController<void>.broadcast();

  List<FriendRequest> sentFrom(String uid) =>
      _requests.where((request) => request.senderId == uid).toList();

  @override
  Stream<List<FriendRequest>> watchPendingRequests(String receiverUid) async* {
    yield _pendingFor(receiverUid);
    yield* _changes.stream.map((_) => _pendingFor(receiverUid));
  }

  @override
  Stream<List<FriendRequest>> watchSentRequests(String senderUid) async* {
    yield _sentFor(senderUid);
    yield* _changes.stream.map((_) => _sentFor(senderUid));
  }

  @override
  Future<void> sendFriendRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    if (senderUid == receiverUid) {
      throw const ValidationError(message: 'Không thể tự kết bạn');
    }
    final exists = _requests.any(
      (request) =>
          request.senderId == senderUid &&
          request.receiverId == receiverUid &&
          request.status == FriendRequestStatus.pending,
    );
    if (exists) return;

    final now = DateTime.now();
    _requests.add(
      FriendRequest(
        requestId: 'req-$senderUid-$receiverUid',
        senderId: senderUid,
        receiverId: receiverUid,
        status: FriendRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    _replaceStatus(requestId, FriendRequestStatus.accepted);
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    _replaceStatus(requestId, FriendRequestStatus.cancelled);
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    _replaceStatus(requestId, FriendRequestStatus.declined);
  }

  List<FriendRequest> _pendingFor(String receiverUid) => _requests
      .where(
        (request) =>
            request.receiverId == receiverUid &&
            request.status == FriendRequestStatus.pending,
      )
      .toList();

  List<FriendRequest> _sentFor(String senderUid) => _requests
      .where(
        (request) =>
            request.senderId == senderUid &&
            request.status == FriendRequestStatus.pending,
      )
      .toList();

  void _replaceStatus(String requestId, FriendRequestStatus status) {
    final index =
        _requests.indexWhere((request) => request.requestId == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class InMemoryReactionRepository implements ReactionRepository {
  final _reactions = <String, List<Reaction>>{};
  final _controllers = <String, StreamController<List<Reaction>>>{};

  List<Reaction> forPost(String postId) =>
      List.unmodifiable(_reactions[postId] ?? const []);

  @override
  Stream<List<Reaction>> watchReactions(String postId) async* {
    yield forPost(postId);
    yield* _controller(postId).stream;
  }

  @override
  Future<Reaction?> getMyReaction({
    required String postId,
    required String uid,
  }) async {
    for (final reaction in _reactions[postId] ?? const <Reaction>[]) {
      if (reaction.reactorUid == uid) return reaction;
    }
    return null;
  }

  @override
  Future<void> upsertReaction({
    required String postId,
    required String reactorUid,
    required String reactorName,
    String? reactorAvatarUrl,
    required String emoji,
  }) async {
    final current = [...(_reactions[postId] ?? const <Reaction>[])];
    final next = Reaction(
      reactorUid: reactorUid,
      reactorName: reactorName,
      reactorAvatarUrl: reactorAvatarUrl,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    final index = current.indexWhere((r) => r.reactorUid == reactorUid);
    if (index == -1) {
      current.add(next);
    } else {
      current[index] = next;
    }
    _reactions[postId] = current;
    _controller(postId).add(forPost(postId));
  }

  @override
  Future<void> deleteReaction({
    required String postId,
    required String reactorUid,
  }) async {
    _reactions[postId] = [
      for (final reaction in _reactions[postId] ?? const <Reaction>[])
        if (reaction.reactorUid != reactorUid) reaction,
    ];
    _controller(postId).add(forPost(postId));
  }

  StreamController<List<Reaction>> _controller(String postId) =>
      _controllers.putIfAbsent(
        postId,
        () => StreamController<List<Reaction>>.broadcast(),
      );

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}

UserProfile testUserProfile({
  String uid = 'uid-me',
  String email = 'me@example.com',
  String displayName = 'Meep Tester',
  String username = 'meep',
}) =>
    UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      username: username,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

PublicProfile testPublicProfile({
  required String uid,
  required String displayName,
  required String username,
}) =>
    PublicProfile(
      uid: uid,
      displayName: displayName,
      username: username,
      updatedAt: DateTime(2026, 6, 1),
    );

Post testPost({
  required String postId,
  required String authorId,
  String authorName = 'Friend',
  String? imageUrl,
}) =>
    Post(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      imageUrl: imageUrl ?? 'https://example.com/$postId.jpg',
      audienceType: AudienceType.all,
      createdAt: DateTime(2026, 6, 1),
    );

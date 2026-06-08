import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';
import 'package:meep/features/feed/presentation/feed_section.dart';
import 'package:meep/features/feed/presentation/widgets/feed_error_view.dart';
import 'package:meep/features/reaction/application/reaction_controller.dart';
import 'package:meep/features/reaction/data/reaction_repository.dart';
import 'package:meep/features/widget/application/widget_data_service.dart';
import 'package:meep/shared/models/post.dart';

class _MockReactionRepository extends Mock implements ReactionRepository {}

class _FakeStorageRepo implements StorageRepository {
  @override
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName = 'photo.jpg',
  }) async =>
      '';

  @override
  Future<void> deleteImage(String storagePath) async {}
}

/// Repo điều khiển được watchFeed cho từng case (data/empty/error). newPostId
/// + các method khác không dùng trong FeedSection render path.
class _StubPostRepo implements PostRepository {
  _StubPostRepo(this._feed);

  final Stream<List<Post>> _feed;

  @override
  Stream<List<Post>> watchFeed(String uid, {String? spaceId}) => _feed;

  @override
  String newPostId() => 'x';

  @override
  Future<Post> createPost(Post post) async => post;

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<List<Post>> getPostsByAuthor(String authorId) async => const [];

  @override
  Future<Post?> getPost(String postId) async => null;
}

Post _post({required String postId, required String authorId}) => Post(
      postId: postId,
      authorId: authorId,
      authorName: 'Author',
      imageUrl: 'https://example.com/$postId.jpg',
      audienceType: AudienceType.all,
      createdAt: DateTime(2026, 5, 27),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final WidgetDataService testWidgetDataService;

  setUpAll(() async {
    registerFallbackValue('');

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testWidgetDataService = WidgetDataService(prefs: prefs);
  });

  const myUid = 'uid-me';

  Future<void> pump(WidgetTester tester, Stream<List<Post>> feed) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final reactionRepo = _MockReactionRepository();
    when(() => reactionRepo.watchReactions(any()))
        .thenAnswer((_) => const Stream.empty());

    // FeedSection render OwnPostCard/FriendPostCard có thể push route khi tap —
    // GoRouter stub đủ cho render (không tap navigation trong test này).
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const CustomScrollView(
            slivers: [FeedSection()],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // LAYER-001: uid qua currentUidProvider — KHÔNG bind FirebaseAuth.
          currentUidProvider.overrideWith((ref) => Stream.value(myUid)),
          postRepositoryProvider.overrideWithValue(_StubPostRepo(feed)),
          storageRepositoryProvider.overrideWithValue(_FakeStorageRepo()),
          reactionRepositoryProvider.overrideWithValue(reactionRepo),
          widgetDataServiceProvider.overrideWithValue(testWidgetDataService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(); // settle stream first emission
  }

  testWidgets('own post → OwnPostCard (no Firebase binding needed)',
      (tester) async {
    await pump(
      tester,
      Stream.value([_post(postId: 'p1', authorId: myUid)]),
    );
    await tester.pump();
    expect(find.byType(OwnPostCard), findsOneWidget);
    expect(find.byType(FriendPostCard), findsNothing);
  });

  testWidgets('friend post → FriendPostCard', (tester) async {
    await pump(
      tester,
      Stream.value([_post(postId: 'p2', authorId: 'someone-else')]),
    );
    await tester.pump();
    expect(find.byType(FriendPostCard), findsOneWidget);
    expect(find.byType(OwnPostCard), findsNothing);
  });

  testWidgets('empty feed → "Chưa có ảnh nào"', (tester) async {
    await pump(tester, Stream.value(const []));
    await tester.pump();
    expect(find.text('Chưa có ảnh nào'), findsOneWidget);
  });

  testWidgets('error feed → FeedErrorView với nút "Thử lại"', (tester) async {
    await pump(tester, Stream.error(Exception('boom')));
    await tester.pump();
    expect(find.byType(FeedErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}

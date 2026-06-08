import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/post_controller.dart';
import 'package:meep/features/feed/data/post_repository.dart';
import 'package:meep/features/feed/data/storage_repository.dart';
import 'package:meep/shared/models/post.dart';

/// LAYER-002: PostController.submit() không còn chạm `FirebaseAuth.instance`
/// hay `FirebaseFirestore.instance` — uid qua currentUidProvider, postId qua
/// PostRepository.newPostId(). Test xác minh các short-circuit + mint id đi
/// đúng đường repository, KHÔNG bind Firebase.
class _FakePostRepo implements PostRepository {
  int newPostIdCalls = 0;

  @override
  String newPostId() {
    newPostIdCalls++;
    return 'minted-1';
  }

  @override
  Future<Post> createPost(Post post) async => post;

  @override
  Stream<List<Post>> watchFeed(String uid, {String? spaceId}) =>
      const Stream.empty();

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<List<Post>> getPostsByAuthor(String authorId) async => const [];

  @override
  Future<Post?> getPost(String postId) async => null;
}

class _FakeStorageRepo implements StorageRepository {
  @override
  Future<String> uploadImage({
    required String uid,
    required String postId,
    required List<int> bytes,
    required String mimeType,
    String fileName = 'photo.jpg',
  }) async =>
      'http://img/$postId';

  @override
  Future<void> deleteImage(String storagePath) async {}
}

void main() {
  late _FakePostRepo postRepo;

  ProviderContainer makeContainer({String? uid = 'uid1'}) {
    postRepo = _FakePostRepo();
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWith((ref) => Stream.value(uid)),
        postRepositoryProvider.overrideWithValue(postRepo),
        storageRepositoryProvider.overrideWithValue(_FakeStorageRepo()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PostController.submit — short-circuits', () {
    test('returns false when uid is null (signed out)', () async {
      final container = makeContainer(uid: null);
      await container.read(currentUidProvider.future);

      final notifier = container.read(postControllerProvider.notifier)
        ..setPendingImage('/tmp/photo.jpg');

      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(postRepo.newPostIdCalls, 0); // không mint khi chưa có uid
    });

    test('returns false + error when select audience has no recipient',
        () async {
      final container = makeContainer();
      await container.read(currentUidProvider.future);

      final notifier = container.read(postControllerProvider.notifier)
        ..setPendingImage('/tmp/photo.jpg')
        ..setAudience(AudienceType.select, const []);

      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(
        container.read(postControllerProvider).errorMessage,
        'Chọn ít nhất 1 người nhận hoặc 1 Space',
      );
      expect(postRepo.newPostIdCalls, 0);
    });
  });

  group('PostController.submit — postId mint qua repository (LAYER-002)', () {
    test('mints postId via PostRepository.newPostId() before upload', () async {
      final container = makeContainer();
      await container.read(currentUidProvider.future);

      final notifier = container.read(postControllerProvider.notifier)
        ..setPendingImage('/tmp/photo.jpg');

      // Compress dùng platform channel → fail trong unit test → submit dừng
      // sau khi đã mint postId. Đủ để chứng minh id đến từ repository (không
      // phải FirebaseFirestore.instance trong controller).
      final ok = await notifier.submit();

      expect(ok, isFalse);
      expect(postRepo.newPostIdCalls, 1);
      expect(
        container.read(postControllerProvider).errorMessage,
        'Không thể xử lý ảnh',
      );
    });
  });
}

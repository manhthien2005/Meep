import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/application/caption_service.dart';
import 'package:meep/features/feed/application/caption_service_impl.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/post_state.dart';
import 'package:meep/features/feed/data/post.dart';

part 'post_controller.g.dart';

@Riverpod(keepAlive: false)
CaptionService captionService(Ref ref) => CaptionServiceImpl();

@riverpod
class PostController extends _$PostController {
  static const int _compressQuality = 85;
  static const int _maxWidthPx = 1080;
  static const int _maxSizeBytes = 1 * 1024 * 1024; // 1 MB target

  @override
  PostState build() => const PostState();

  void setPendingImage(String path) => state = state.copyWith(
        pendingImagePath: path,
        pendingBackImagePath: null,
        pendingFrontImagePath: null,
        isDualMode: false,
        errorMessage: null,
      );

  void setPendingDualImages({
    required String backPath,
    required String frontPath,
  }) =>
      state = state.copyWith(
        pendingImagePath: null,
        pendingBackImagePath: backPath,
        pendingFrontImagePath: frontPath,
        isDualMode: true,
        errorMessage: null,
      );

  void setCaption(String text) => state = state.copyWith(caption: text);

  Future<void> setCaptionType(CaptionType? type) async {
    state = state.copyWith(captionType: type, caption: null);
    if (type == null) return;
    try {
      final svc = ref.read(captionServiceProvider);
      final resolved = await svc.resolve(type);
      state = state.copyWith(caption: resolved);
    } catch (_) {
      state = state.copyWith(caption: '');
    }
  }

  void setAudience(AudienceType type, List<String> uids) {
    state = state.copyWith(audienceType: type, selectedUids: uids);
  }

  Future<bool> submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    if (state.isDualMode) {
      if (state.pendingBackImagePath == null ||
          state.pendingFrontImagePath == null) {
        return false;
      }
    } else if (state.pendingImagePath == null) {
      return false;
    }

    if (state.audienceType == AudienceType.select &&
        state.selectedUids.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Chọn ít nhất 1 người nhận',
      );
      return false;
    }

    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      final storageRepo = ref.read(storageRepositoryProvider);

      String? imageUrl;
      String? backImageUrl;
      String? frontImageUrl;

      if (state.isDualMode) {
        final backBytes = await _compress(state.pendingBackImagePath!);
        final frontBytes = await _compress(state.pendingFrontImagePath!);
        if (backBytes == null || frontBytes == null) {
          state = state.copyWith(
            isUploading: false,
            errorMessage: 'Không thể xử lý ảnh',
          );
          return false;
        }
        backImageUrl = await storageRepo.uploadImage(
          uid: uid,
          postId: postId,
          bytes: backBytes,
          mimeType: 'image/jpeg',
          fileName: 'back.jpg',
        );
        frontImageUrl = await storageRepo.uploadImage(
          uid: uid,
          postId: postId,
          bytes: frontBytes,
          mimeType: 'image/jpeg',
          fileName: 'front.jpg',
        );
      } else {
        final compressed = await _compress(state.pendingImagePath!);
        if (compressed == null) {
          state = state.copyWith(
            isUploading: false,
            errorMessage: 'Không thể xử lý ảnh',
          );
          return false;
        }
        imageUrl = await storageRepo.uploadImage(
          uid: uid,
          postId: postId,
          bytes: compressed,
          mimeType: 'image/jpeg',
        );
      }

      // Create Firestore post doc
      final postRepo = ref.read(postRepositoryProvider);
      final user = FirebaseAuth.instance.currentUser!;

      final post = Post(
        postId: postId,
        authorId: uid,
        authorName: user.displayName ?? '',
        authorAvatarUrl: user.photoURL,
        imageUrl: imageUrl,
        backImageUrl: backImageUrl,
        frontImageUrl: frontImageUrl,
        isDualCamera: state.isDualMode,
        caption: state.caption,
        captionType: state.captionType,
        audienceType: state.audienceType,
        audienceUids:
            state.audienceType == AudienceType.all ? [] : state.selectedUids,
        createdAt: DateTime.now(),
      );
      await postRepo.createPost(post);

      // Invalidate feed to refresh after successful post
      ref.invalidate(feedControllerProvider);

      state = const PostState();
      return true;
    } catch (_) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Tải ảnh thất bại — thử lại',
      );
      return false;
    }
  }

  Future<void> deletePost(String postId) async {
    final repo = ref.read(postRepositoryProvider);
    await repo.deletePost(postId);
  }

  Future<List<int>?> _compress(String path) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: _maxWidthPx,
        minHeight: _maxWidthPx,
        quality: _compressQuality,
        format: CompressFormat.jpeg,
      );
      if (result == null) return null;
      if (result.length > _maxSizeBytes) {
        // Re-compress at lower quality
        return FlutterImageCompress.compressWithFile(
          path,
          minWidth: _maxWidthPx,
          minHeight: _maxWidthPx,
          quality: 60,
          format: CompressFormat.jpeg,
        );
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}

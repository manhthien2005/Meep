import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/feed/application/caption_service.dart';
import 'package:meep/features/feed/application/caption_service_impl.dart';
import 'package:meep/features/feed/application/feed_controller.dart';
import 'package:meep/features/feed/application/post_state.dart';
import 'package:meep/features/feed/data/post.dart';
import 'package:meep/features/space/application/space_controller.dart';

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

  /// Toggle 1 Space trong `selectedSpaceIds`. KHÔNG ảnh hưởng `selectedUids`
  /// (friends pick lẻ độc lập với Space pick) hoặc `audienceType`.
  void toggleSpace(String spaceId) {
    final current = state.selectedSpaceIds;
    final next = current.contains(spaceId)
        ? current.where((id) => id != spaceId).toList()
        : [...current, spaceId];
    state = state.copyWith(selectedSpaceIds: next);
  }

  /// Set toàn bộ `selectedSpaceIds` (vd reset hoặc bulk select). KHÔNG đổi
  /// `selectedUids` / `audienceType`.
  void setSpaces(List<String> spaceIds) {
    state = state.copyWith(selectedSpaceIds: spaceIds);
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
        state.selectedUids.isEmpty &&
        state.selectedSpaceIds.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Chọn ít nhất 1 người nhận hoặc 1 Space',
      );
      return false;
    }

    state = state.copyWith(isUploading: true, errorMessage: null);
    final postId = FirebaseFirestore.instance.collection('posts').doc().id;
    final storageRepo = ref.read(storageRepositoryProvider);

    String? imageUrl;
    String? backImageUrl;
    String? frontImageUrl;

    // ── Step 1 + 2: compress + upload to Storage ─────────────────────────────
    try {
      if (state.isDualMode) {
        final backBytes = await _compress(state.pendingBackImagePath!);
        final frontBytes = await _compress(state.pendingFrontImagePath!);
        if (backBytes == null || frontBytes == null) {
          _log(
            'compress dual returned null',
            'backBytes=${backBytes?.length} frontBytes=${frontBytes?.length}',
          );
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
          _log('compress single returned null', state.pendingImagePath);
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
    } catch (e, st) {
      _log('upload storage failed', e, st);
      state = state.copyWith(
        isUploading: false,
        errorMessage: _errorMessage('upload', e),
      );
      return false;
    }

    // ── Step 3: create Firestore post doc ────────────────────────────────────
    try {
      final postRepo = ref.read(postRepositoryProvider);
      final user = FirebaseAuth.instance.currentUser!;

      // Empty / whitespace caption → store null so it never renders downstream.
      final trimmedCaption = state.caption?.trim();

      // Multi-Space pick từ AudienceRow. Trùng member giữa các Space →
      // dedupe union ở `memberIds` (Firestore rule check hasAny([uid]) cho
      // collection query `posts WHERE spaceIds array-contains X`).
      final selectedSpaceIds = state.selectedSpaceIds;
      List<String> memberIdsUnion = const [];
      if (selectedSpaceIds.isNotEmpty) {
        final currentUid = ref.read(currentUidProvider).valueOrNull;
        if (currentUid != null) {
          final allSpaces =
              ref.read(spaceControllerProvider(currentUid)).spaces;
          final selectedSpaces = allSpaces
              .where((s) => selectedSpaceIds.contains(s.spaceId))
              .toList();
          final unionSet = <String>{};
          for (final s in selectedSpaces) {
            unionSet.addAll(s.memberIds);
          }
          memberIdsUnion = unionSet.toList();
        }
      }

      // authorName: chữ đầu tiên trong displayName, tối đa 6 ký tự.
      // Dài hơn → cắt còn 6 + "...".
      final rawName = user.displayName?.trim() ?? '';
      final firstName = rawName.split(' ').first;
      final authorName =
          firstName.length <= 6 ? firstName : '${firstName.substring(0, 6)}...';

      final post = Post(
        postId: postId,
        authorId: uid,
        authorName: authorName,
        authorAvatarUrl: user.photoURL ??
            ref.read(currentUserProfileProvider).valueOrNull?.avatarUrl,
        imageUrl: imageUrl,
        backImageUrl: backImageUrl,
        frontImageUrl: frontImageUrl,
        isDualCamera: state.isDualMode,
        caption: (trimmedCaption == null || trimmedCaption.isEmpty)
            ? null
            : trimmedCaption,
        captionType: state.captionType,
        audienceType: state.audienceType,
        audienceUids:
            state.audienceType == AudienceType.all ? [] : state.selectedUids,
        spaceIds: selectedSpaceIds,
        memberIds: memberIdsUnion,
        createdAt: DateTime.now(),
      );
      await postRepo.createPost(post);

      // Invalidate feed to refresh after successful post
      ref.invalidate(feedControllerProvider);

      state = const PostState();
      return true;
    } catch (e, st) {
      _log('create post doc failed', e, st);
      state = state.copyWith(
        isUploading: false,
        errorMessage: _errorMessage('createPost', e),
      );
      return false;
    }
  }

  /// Map an arbitrary error to a user-facing Vietnamese message. Differentiates
  /// FirebaseException by `code` so the UI gives a real hint (permission /
  /// auth / network) instead of one opaque "thử lại" for every failure.
  String _errorMessage(String step, Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'Không có quyền gửi — kiểm tra đăng nhập / quyền truy cập';
        case 'unauthenticated':
          return 'Phiên đăng nhập hết hạn — đăng nhập lại';
        case 'unavailable':
        case 'deadline-exceeded':
        case 'cancelled':
          return 'Mất kết nối — thử lại';
        case 'resource-exhausted':
          return 'Quá tải — chờ một lát rồi thử lại';
        default:
          return 'Tải ảnh thất bại (${e.code}) — thử lại';
      }
    }
    return 'Tải ảnh thất bại — thử lại';
  }

  void _log(String message, [Object? detail, StackTrace? st]) {
    if (!kDebugMode) return;
    final detailStr = detail == null
        ? ''
        : detail is FirebaseException
            ? ' [${detail.runtimeType} code=${detail.code} msg=${detail.message}]'
            : ' [${detail.runtimeType}] $detail';
    debugPrint('[PostController.submit] $message$detailStr');
    if (st != null) debugPrint(st.toString());
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

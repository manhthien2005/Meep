import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/feed/data/post.dart';

part 'post_controller.freezed.dart';
part 'post_controller.g.dart';

@freezed
class PostState with _$PostState {
  const factory PostState({
    @Default(false) bool isUploading,
    String? pendingImagePath,
    String? caption,
    CaptionType? captionType,
    @Default(AudienceType.all) AudienceType audienceType,
    @Default([]) List<String> selectedUids,
    String? errorMessage,
  }) = _PostState;
}

@riverpod
class PostController extends _$PostController {
  @override
  PostState build() => const PostState();

  Future<void> submit() async {
    // TODO(FE/T9/KhoaLND): upload + create Firestore doc
    throw UnimplementedError('submit — TODO: FE/T9/KhoaLND');
  }

  void setCaptionType(CaptionType? type) {
    // TODO(FE/T10/KhoaLND): update captionType + resolve caption text
    throw UnimplementedError('setCaptionType — TODO: FE/T10/KhoaLND');
  }

  void setAudience(AudienceType type, List<String> uids) {
    // TODO(FE/T11/KhoaLND): update audience selection
    throw UnimplementedError('setAudience — TODO: FE/T11/KhoaLND');
  }

  Future<void> deletePost(String postId) async {
    // TODO(FE/T12/KhoaLND): delete post + Storage assets
    throw UnimplementedError('deletePost — TODO: FE/T12/KhoaLND');
  }
}

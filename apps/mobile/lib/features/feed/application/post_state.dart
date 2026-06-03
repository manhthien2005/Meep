import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:meep/features/feed/data/post.dart';

part 'post_state.freezed.dart';

@freezed
class PostState with _$PostState {
  const factory PostState({
    @Default(false) bool isUploading,

    /// Single mode: pendingImagePath is set, dual fields are null.
    /// Dual mode: pendingBackImagePath/pendingFrontImagePath are set, pendingImagePath is null.
    String? pendingImagePath,
    String? pendingBackImagePath,
    String? pendingFrontImagePath,
    @Default(false) bool isDualMode,
    String? caption,
    CaptionType? captionType,
    @Default(AudienceType.all) AudienceType audienceType,

    /// Friends pick lẻ ở AudienceRow (KHÔNG include member từ Space — Space
    /// member sẽ được derive denormalize ở `Post.memberIds` lúc submit).
    @Default([]) List<String> selectedUids,

    /// Multi-Space pick ở AudienceRow. Empty = không gửi vào Space nào.
    /// Trùng member giữa các Space → dedupe ở `Post.memberIds` lúc submit.
    @Default(<String>[]) List<String> selectedSpaceIds,
    String? errorMessage,
  }) = _PostState;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_content_block.freezed.dart';
part 'diary_content_block.g.dart';

enum ContentBlockType { text, image }

enum TextBlockStyle { normal, heading, subheading, quote }

@freezed
class DiaryContentBlock with _$DiaryContentBlock {
  /// Text block — supports 4 styles.
  const factory DiaryContentBlock.text({
    required String value,
    @Default(TextBlockStyle.normal) TextBlockStyle style,
  }) = TextBlock;

  /// Image block — inline image in content area.
  const factory DiaryContentBlock.image({
    required String imageUrl,
  }) = ImageBlock;

  factory DiaryContentBlock.fromJson(Map<String, dynamic> json) =>
      _$DiaryContentBlockFromJson(json);
}

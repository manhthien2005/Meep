import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/presentation/discard_changes_dialog.dart';
import 'package:meep/features/diary/presentation/privacy_sheet.dart';
import 'package:meep/features/diary/presentation/widgets/align_picker.dart';
import 'package:meep/features/diary/presentation/widgets/delete_diary_dialog.dart';
import 'package:meep/features/diary/presentation/widgets/diary_menu_sheet.dart';
import 'package:meep/features/diary/presentation/widgets/polaroid_image_block.dart';
import 'package:meep/features/diary/presentation/widgets/text_style_picker.dart';

/// Re-export [DiaryCanvasMode] để các screen khác (`diary_list_screen`,...)
/// import từ canvas screen như cũ, không phải đổi imports loạt.
/// Definition canonical ở application/diary_controller.dart.
export 'package:meep/features/diary/application/diary_controller.dart'
    show DiaryCanvasMode;

part 'diary_canvas_screen_toolbar.dart';
part 'diary_canvas_screen_dot_grid.dart';

/// Payload pop về khi user tap check ở Canvas (create mode).
///
/// FE-mock only — sau khi wire DiaryRepository, replace bằng `DiaryEntry`
/// (data layer) hoặc gọi controller.saveDraft trực tiếp trong Canvas.
class DiaryDraftResult {
  const DiaryDraftResult({
    required this.caption,
    required this.content,
    required this.mood,
    required this.createdAt,
    required this.privacy,
  });

  final String caption;
  final String content;
  final MoodTemplate mood;
  final DateTime createdAt;
  final DiaryPrivacy privacy;
}

/// Mode của toolbar dưới Canvas (edit/create only).
///
/// - `content`: toolbar chính 4 icon (image / type / align / smile).
/// - `style`: TextStylePicker (size + B/I/U/S).
/// - `align`: AlignPicker (left/center/right/justify) — kiểu Word.
enum _ToolMode { content, style, align }

/// Diary Canvas Screen — block editor / viewer (blog-style).
///
/// Figma: `658:6070` (Canvas), `769:4634` (read mode).
/// Spec: `docs/specs/2026-05-23-diary.md`
///
/// Light theme intentionally — hardcode `#F9FCFC` (KHÔNG dùng Theme.of).
/// Layout: topbar (ngoài box) → box border đen + dots bg (mood zone +
/// content) → content toolbar (ngoài box).
class DiaryCanvasScreen extends StatefulWidget {
  const DiaryCanvasScreen({
    super.key,
    required this.mode,
    this.entryId,
    this.moodTemplate,
    this.initialCaption,
    this.initialContent,
    this.initialImageUrl,
    this.entryDate,
  });

  final DiaryCanvasMode mode;
  final String? entryId;

  /// Mood đã chọn ở picker (create mode). Quyết định mood zone header.
  final MoodTemplate? moodTemplate;

  /// Prefill cho read/edit mode. Khi null:
  /// - caption fallback = mood label (vd "Vui vẻ" cho create).
  /// - content rỗng → hint "Viết nhật ký của bạn...".
  /// - imageUrl null → không render Polaroid.
  final String? initialCaption;
  final String? initialContent;
  final String? initialImageUrl;

  /// Ngày của entry — hiển thị ở topbar center. Khi null (create mode) →
  /// dùng `DateTime.now()` tự động.
  final DateTime? entryDate;

  @override
  State<DiaryCanvasScreen> createState() => _DiaryCanvasScreenState();
}

class _DiaryCanvasScreenState extends State<DiaryCanvasScreen> {
  /// Canvas light theme — alias để giữ semantic rõ ràng trong code.
  /// `bw100` (#F9FCFC) = nền canvas sáng theo spec §Technical approach.
  static const _canvasBg = AppColors.bw100;

  late final TextEditingController _captionController;
  late final TextEditingController _contentController;
  final _contentFocus = FocusNode();

  /// Ngày hiển thị ở topbar. Create mode = today; read/edit = entryDate.
  late final DateTime _displayDate;

  /// Content alignment — default center, user toggle qua toolbar.
  TextAlign _contentAlign = TextAlign.center;

  /// Privacy của entry — default private, đổi qua Privacy sheet.
  DiaryPrivacy _privacy = DiaryPrivacy.private;

  /// Toolbar dưới đang ở mode nào (content / style / align).
  _ToolMode _toolMode = _ToolMode.content;

  /// Text style state (áp cho content). size: 1=Large…4=Small.
  int _textSize = 3;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _strikethrough = false;

  bool get _isReadOnly => widget.mode == DiaryCanvasMode.read;

  @override
  void initState() {
    super.initState();
    // Caption: prefill từ initial nếu có; fallback = tên mood đã chọn.
    _captionController = TextEditingController(
      text: widget.initialCaption ??
          (widget.moodTemplate == null ? '' : _moodLabel(widget.moodTemplate!)),
    );
    // Content: prefill nếu có (read/edit mode), trống cho create mode.
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    // Date hiển thị topbar: entryDate (read/edit) hoặc hôm nay (create).
    _displayDate = widget.entryDate ?? DateTime.now();
  }

  /// Format DateTime → "DD tháng MM" (tiếng Việt, không zero-pad).
  static String _formatDiaryDate(DateTime date) =>
      '${date.day} tháng ${date.month}';

  @override
  void dispose() {
    _captionController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  /// Mood key → tên hiển thị tiếng Việt.
  static String _moodLabel(MoodTemplate t) => switch (t) {
        MoodTemplate.happy => 'Vui vẻ',
        MoodTemplate.bored => 'Chán nản',
        MoodTemplate.tired => 'Mệt mỏi',
        MoodTemplate.shy => 'Ngại ngùng',
        MoodTemplate.sad => 'Buồn bã',
      };

  /// Save handler — tap check ở topbar.
  ///
  /// Create mode (FE mock): pop về list với `DiaryDraftResult` để list
  /// insert entry mới lên đầu. Edit mode: chỉ pop (chưa wire update mock).
  /// Sau khi wire DiaryRepository: gọi controller.save() rồi pop.
  void _handleSave() {
    final mood = widget.moodTemplate;
    if (mood == null) {
      // Defensive — create flow phải pass mood từ picker.
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.mode == DiaryCanvasMode.edit) {
      // TODO(D/T3/HanDHG): edit mode wire khi có DiaryRepository.
      Navigator.of(context).maybePop();
      return;
    }
    final caption = _captionController.text.trim().isEmpty
        ? _moodLabel(mood)
        : _captionController.text.trim();
    Navigator.of(context).pop(
      DiaryDraftResult(
        caption: caption,
        content: _contentController.text,
        mood: mood,
        createdAt: _displayDate,
        privacy: _privacy,
      ),
    );
  }

  /// Mood background asset (hiển thị trong cover circle).
  static String _moodAsset(MoodTemplate t) => 'assets/icons/bg_${t.name}.png';

  Future<void> _openPrivacy() async {
    final picked = await PrivacySheet.show(context, initial: _privacy);
    if (picked != null && mounted) setState(() => _privacy = picked);
  }

  /// Back handler — create mode + có nội dung → DiscardChangesDialog;
  /// read/edit mode → pop trực tiếp.
  Future<void> _handleBack() async {
    final hasContent = _captionController.text.isNotEmpty ||
        _contentController.text.isNotEmpty;
    final shouldConfirm = widget.mode == DiaryCanvasMode.create && hasContent;

    if (!shouldConfirm) {
      // ignore: unawaited_futures
      Navigator.of(context).maybePop();
      return;
    }

    final discard = await DiscardChangesDialog.show(context);
    if (discard == true && mounted) {
      // ignore: unawaited_futures
      Navigator.of(context).maybePop();
    }
  }

  /// Mở Menu nhật ký (read mode topbar ellipsis) — Chỉnh sửa / Xóa / Chia sẻ.
  Future<void> _openMenu() async {
    final action = await DiaryMenuSheet.show(context);
    if (action == null || !mounted) return;

    switch (action) {
      case DiaryMenuAction.edit:
        // Push Canvas edit mode với content hiện tại prefilled. Dùng
        // pushReplacement để back nút trở về Diary list (skip read mode).
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DiaryCanvasScreen(
              mode: DiaryCanvasMode.edit,
              entryId: widget.entryId,
              moodTemplate: widget.moodTemplate,
              initialCaption: _captionController.text,
              initialContent: _contentController.text,
              initialImageUrl: widget.initialImageUrl,
              entryDate: _displayDate,
            ),
          ),
        );
      case DiaryMenuAction.delete:
        final confirmed = await DeleteDiaryDialog.show(context);
        if (confirmed == true && mounted) {
          // TODO(D/T6/HanDHG): gọi DiaryController.deleteEntry(entryId).
          // ignore: unawaited_futures
          Navigator.of(context).maybePop();
        }
      case DiaryMenuAction.share:
        // TODO(D/T7/HanDHG): native share sheet (share_plus với text + cover image).
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopbar(),
            // Box border đen + dots — hug content vertically, width fixed
            // theo margin ngoài. Scroll cả màn khi content vượt screen height.
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildCanvasBox(),
              ),
            ),
            if (!_isReadOnly) _buildToolbar(),
          ],
        ),
      ),
    );
  }

  // ── Toolbar dưới: 3 mode (content / style / align) ──
  Widget _buildToolbar() {
    return switch (_toolMode) {
      _ToolMode.style => TextStylePicker(
          size: _textSize,
          bold: _bold,
          italic: _italic,
          underline: _underline,
          strikethrough: _strikethrough,
          onSizeSelected: (s) => setState(() => _textSize = s),
          onBold: () => setState(() => _bold = !_bold),
          onItalic: () => setState(() => _italic = !_italic),
          onUnderline: () => setState(() => _underline = !_underline),
          onStrikethrough: () =>
              setState(() => _strikethrough = !_strikethrough),
          onClose: () => setState(() => _toolMode = _ToolMode.content),
        ),
      _ToolMode.align => AlignPicker(
          current: _contentAlign,
          onSelected: (a) => setState(() => _contentAlign = a),
          onClose: () => setState(() => _toolMode = _ToolMode.content),
        ),
      _ToolMode.content => _ContentToolbar(
          onType: () => setState(() => _toolMode = _ToolMode.style),
          onAlign: () => setState(() => _toolMode = _ToolMode.align),
        ),
    };
  }

  // ── Topbar: [<] | date (center) | [lock][check] ──
  Widget _buildTopbar() {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Stack(
          children: [
            // Back — căn trái
            Align(
              alignment: Alignment.centerLeft,
              child: _SvgIconBtn(
                asset: 'assets/icons/ic_diary_back.svg',
                semanticLabel: 'Quay lại',
                onTap: _handleBack,
              ),
            ),

            // Date — căn giữa tuyệt đối, format theo entryDate hoặc hôm nay
            Center(
              child: Text(
                _formatDiaryDate(_displayDate),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bw900, // #050F10
                  height: 22 / 16,
                ),
              ),
            ),

            // Trailing — căn phải, 2 icon sát nhau
            Align(
              alignment: Alignment.centerRight,
              child: _isReadOnly
                  ? _SvgIconBtn(
                      asset: 'assets/icons/ic_diary_ellipsis.svg',
                      semanticLabel: 'Tùy chọn',
                      onTap: _openMenu,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SvgIconBtn(
                          // Icon đổi theo privacy: lock (riêng tư) / globe (công khai)
                          asset: _privacy == DiaryPrivacy.public
                              ? 'assets/icons/ic_diary_globe.svg'
                              : 'assets/icons/ic_diary_lock.svg',
                          semanticLabel: 'Quyền riêng tư',
                          onTap: _openPrivacy,
                        ),
                        const SizedBox(width: 6),
                        _SvgIconBtn(
                          asset: 'assets/icons/ic_diary_check.svg',
                          semanticLabel: 'Lưu',
                          onTap: _handleSave,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Box: border đen + dots bg, hug content theo Column ──
  //
  // Width fixed theo parent SingleChildScrollView (full-width - margin 24).
  // Height tự dãn theo content (mood zone + caption + content text).
  // Scroll do parent SingleChildScrollView xử lý.
  Widget _buildCanvasBox() {
    return Container(
      decoration: BoxDecoration(
        color: _canvasBg,
        border: Border.all(color: AppColors.bw800), // #252627
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _DotGridPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoodZone(),
              const SizedBox(height: 28),
              _buildContentArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mood zone: cover (mood image) + caption highlight ──
  Widget _buildMoodZone() {
    final mood = widget.moodTemplate;
    return Column(
      children: [
        // Cover — mood image thuần (không khung tròn để giữ shape gốc)
        SizedBox(
          height: 102,
          child: mood == null
              ? const Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: AppColors.bw500,
                )
              : Image.asset(_moodAsset(mood), fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),

        // Mood caption — highlight nền turquoise (thay line xanh), editable
        IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              // Highlight bút dạ — turquoise400 sáng làm nền nổi bật caption.
              color: AppColors.turquoise400.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
            child: _isReadOnly
                ? Text(
                    _captionController.text,
                    textAlign: TextAlign.center,
                    style: _captionStyle,
                  )
                : TextField(
                    controller: _captionController,
                    textAlign: TextAlign.center,
                    style: _captionStyle,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      isDense: true,
                      counterText: '',
                      border: InputBorder.none,
                      hintText: 'Tiêu đề',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  static const _captionStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.bw900,
    height: 24 / 18,
  );

  // ── Content area: text block + Polaroid inline (nếu có ảnh) ──
  Widget _buildContentArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isReadOnly)
          Text(
            _contentController.text,
            textAlign: _contentAlign,
            style: _contentStyle,
          )
        else
          TextField(
            controller: _contentController,
            focusNode: _contentFocus,
            autofocus: true, // bật keyboard ngay khi vào canvas
            maxLines: null,
            textAlign: _contentAlign,
            style: _contentStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Viết nhật ký của bạn...',
              hintStyle: TextStyle(color: AppColors.bw500),
            ),
          ),
        if (widget.initialImageUrl != null) ...[
          const SizedBox(height: 24),
          PolaroidImageBlock(imageUrl: widget.initialImageUrl!),
        ],
      ],
    );
  }

  static const _contentStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.bw900,
    height: 24 / 16,
  );
}

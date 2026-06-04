import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_content_block.dart';
import 'package:meep/features/diary/data/diary_entry.dart';
import 'package:meep/features/diary/presentation/diary_canvas_screen.dart';
import 'package:meep/features/diary/presentation/diary_search_screen.dart';
import 'package:meep/features/diary/presentation/widgets/diary_list_card.dart';
import 'package:meep/features/diary/presentation/widgets/diary_mood_card.dart';
import 'package:meep/shared/widgets/app_taskbar.dart';

part 'diary_list_screen_mood_picker.dart';

/// Diary List Screen — Grid 2 columns hoặc Empty state.
///
/// Figma: `656:1945` (Empty state), `656:1831` (Grid view),
/// `656:1953` (mood picker overlay).
/// Spec: `docs/specs/2026-05-23-diary.md`
///
/// Mood picker là overlay inline: tap FAB [+] → FAB xoay thành [x] + nền
/// đổi xám, scrim mờ + 5 mood arc bao quanh nửa trên FAB. Tap [x] hoặc
/// scrim → đóng.
class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

/// Format ngắn cho card display: "DD th MM".
String _formatShortDate(DateTime d) => '${d.day} th ${d.month}';

/// View mode cho danh sách nhật ký — Grid 2-col vs List dọc.
enum _ViewMode { grid, list }

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  bool _pickerOpen = false;
  _ViewMode _viewMode = _ViewMode.grid;

  /// Track uid đã trigger loadEntries để không gọi lại khi cùng uid emit
  /// nhiều lần (vd auth state stream replay).
  String? _loadedForUid;

  @override
  void initState() {
    super.initState();
    // Riverpod pattern chuẩn: ref.listenManual fire ngay với current value +
    // mọi emit sau. Trigger loadEntries 1 lần / uid; sign out → sign in lại
    // với uid khác sẽ tự re-trigger.
    ref.listenManual<AsyncValue<String?>>(
      currentUidProvider,
      (_, next) {
        final uid = next.valueOrNull;
        if (uid == null || _loadedForUid == uid) return;
        _loadedForUid = uid;
        ref.read(diaryControllerProvider.notifier).loadEntries(uid);
      },
      fireImmediately: true,
    );
  }

  void _togglePicker() => setState(() => _pickerOpen = !_pickerOpen);
  void _closePicker() => setState(() => _pickerOpen = false);

  /// Tap 1 mood trong picker — close picker, push Canvas create.
  /// Sau save: stream `watchEntries` tự đẩy entry mới về `state.entries` —
  /// KHÔNG cần manual insert như mock cũ.
  Future<void> _onMoodSelected(MoodTemplate mood) async {
    _closePicker();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.create,
          moodTemplate: mood,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen errorMessage qua provider.select để show SnackBar khi error
    // mới fire (kể cả khi đã có entries cũ — branch error trong _buildBody
    // chỉ render khi empty).
    ref.listen<String?>(
      diaryControllerProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next == null || next == prev) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next)),
        );
        ref.read(diaryControllerProvider.notifier).clearError();
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bw900, // #050F10
      body: Stack(
        children: [
          // ── Content (trong SafeArea, dưới scrim) ──
          SafeArea(
            child: Column(
              children: [
                _buildTopbar(),
                _buildFilterRow(),
                // Body co giãn: Grid / List / Empty / Loading / Error
                Expanded(child: _buildBody()),
                // Padding dưới chừa chỗ cho FAB + taskbar
                const SizedBox(height: 160),
              ],
            ),
          ),

          // ── Taskbar overlay (cố định đáy, ngoài Column flow) ──
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppTaskbar(
                  activeTab: TaskbarTab.diary,
                  onTabSelected: (tab) {
                    switch (tab) {
                      case TaskbarTab.streak:
                        context.go('/streak');
                      case TaskbarTab.diary:
                        context.go('/diary');
                      case TaskbarTab.home:
                        context.go('/home');
                      case TaskbarTab.chat:
                        context.go('/inbox');
                      case TaskbarTab.profile:
                        context.go('/profile');
                    }
                  },
                ),
              ),
            ),
          ),

          // ── Scrim — phủ FULL screen (ngoài SafeArea) ──
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_pickerOpen,
              child: GestureDetector(
                onTap: _closePicker,
                child: AnimatedOpacity(
                  opacity: _pickerOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),

          // ── Overlay: mood picker + FAB (trên scrim, trong SafeArea) ──
          SafeArea(
            child: Stack(
              children: [
                // Mood picker — title + 5 mood arc
                IgnorePointer(
                  ignoring: !_pickerOpen,
                  child: AnimatedOpacity(
                    opacity: _pickerOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: _MoodPickerLayer(onMoodSelected: _onMoodSelected),
                  ),
                ),

                // FAB — toggle [+] ↔ [x]
                Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildFab()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search icon → mở DiarySearchScreen
          Semantics(
            label: 'Tìm kiếm',
            button: true,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DiarySearchScreen(),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_diary_search.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
          ),

          // Title "Nhật ký"
          const Text(
            'Nhật ký',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bw100, // #F9FCFC
              height: 24 / 18,
            ),
          ),

          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color:
                  AppColors.bw600, // Avatar placeholder — match Figma BW dark
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter row: "Tất cả" (label) + view toggle icon (Grid/List) ──
  Widget _buildFilterRow() {
    final toggleIcon = _viewMode == _ViewMode.grid
        ? 'assets/icons/ic_grid_3x2.svg'
        : 'assets/icons/ic_grip_horizontal.svg';
    final toggleLabel =
        _viewMode == _ViewMode.grid ? 'Chuyển sang List' : 'Chuyển sang Grid';

    return Padding(
      padding: const EdgeInsets.fromLTRB(37, 8, 37, 16),
      child: Row(
        children: [
          const Text(
            'Tất cả',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.bw500, // #8D999B
              height: 22 / 16,
            ),
          ),
          const Spacer(),
          Semantics(
            label: toggleLabel,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _viewMode = _viewMode == _ViewMode.grid
                    ? _ViewMode.list
                    : _ViewMode.grid;
              }),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Center(
                  child: SvgPicture.asset(
                    toggleIcon,
                    width: 19.5,
                    height: 19.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: render theo controller state ──
  Widget _buildBody() {
    final state = ref.watch(diaryControllerProvider);

    if (state.isLoading && state.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.turquoise500),
      );
    }

    if (state.errorMessage != null && state.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            state.errorMessage ?? 'Không tải được nhật ký',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.bw500,
            ),
          ),
        ),
      );
    }

    if (state.entries.isEmpty) return _buildEmptyState();
    return _viewMode == _ViewMode.grid
        ? _buildGrid(state.entries)
        : _buildList(state.entries);
  }

  Widget _buildGrid(List<DiaryEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 39),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 150.5 / 182,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return DiaryMoodCard(
          title: e.moodCaption,
          date: _formatShortDate(e.createdAt),
          mood: e.moodTemplate,
          onTap: () => _openCanvasRead(e),
        );
      },
    );
  }

  Widget _buildList(List<DiaryEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final e = entries[index];
        return DiaryListCard(
          title: e.moodCaption,
          date: _formatShortDate(e.createdAt),
          mood: e.moodTemplate,
          onTap: () => _openCanvasRead(e),
        );
      },
    );
  }

  /// Read mode — T9b sẽ wire đầy đủ (fetch entry + render content blocks).
  /// PR4a tạm push canvas với fields hiện có; render text content + ảnh
  /// inline sẽ bổ sung ở T9b.
  void _openCanvasRead(DiaryEntry e) {
    // Lấy text content từ block đầu tiên dạng text (nếu có) — placeholder
    // tới khi T9b render đầy đủ block list.
    final firstText = e.content.firstWhere(
      (b) => b.maybeWhen(text: (_, __) => true, orElse: () => false),
      orElse: () => const DiaryContentBlock.text(value: ''),
    );
    final textValue = firstText.maybeWhen(
      text: (value, _) => value,
      orElse: () => '',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.read,
          entryId: e.entryId,
          moodTemplate: e.moodTemplate,
          initialCaption: e.moodCaption,
          initialContent: textValue,
          initialImageUrl: e.coverImageUrl.isNotEmpty ? e.coverImageUrl : null,
          entryDate: e.createdAt,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Bạn chưa có nhật ký nào',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.bw500, // Empty state muted text
          height: 24 / 18,
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Semantics(
      label: _pickerOpen ? 'Đóng' : 'Tạo nhật ký',
      button: true,
      child: GestureDetector(
        onTap: _togglePicker,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _pickerOpen
                ? AppColors.bw800 // #252627 khi mở
                : AppColors.turquoise500, // #00DEEE khi đóng
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedRotation(
            turns: _pickerOpen ? 0.125 : 0, // 45° → dấu [+] thành [x]
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.add,
              size: 32,
              color: _pickerOpen ? AppColors.bw100 : AppColors.bw800,
            ),
          ),
        ),
      ),
    );
  }
}

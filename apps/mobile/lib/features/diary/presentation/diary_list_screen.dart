import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meep/core/theme/app_colors.dart';
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
class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

// DEV mock data — chỉ dùng cho TextButton mở Canvas read demo. Xoá khi
// wire DiaryRepository thật.
const _devMockContent =
    'Hôm nay là một ngày thật tuyệt vời. Mình đã đi dạo bên bờ biển '
    'cùng các bạn thân, mặt trời lặn nhuộm cả bầu trời thành màu cam '
    'rực rỡ. Mình ngồi đó nghe sóng vỗ, ngắm những con thuyền nhỏ '
    'lướt trên mặt nước. Có những khoảnh khắc bình yên đến lạ thường, '
    'khi mọi lo toan tan biến và mình chỉ còn cảm nhận được hơi thở '
    'của biển cả.';
const _devMockImageUrl = 'https://picsum.photos/seed/diary/600/600';

// DEV mock entries cho Grid/List view — xoá khi wire DiaryRepository.
class _MockEntry {
  const _MockEntry({
    required this.title,
    required this.date,
    required this.mood,
    this.content = '',
  });

  final String title;
  final DateTime date;
  final MoodTemplate mood;

  /// Body text — non-empty cho seed entries để Canvas read mode demo có
  /// nội dung. Empty cho entry mới tạo từ Canvas (chưa nhập gì).
  final String content;
}

/// Format ngắn cho card display: "DD th MM".
String _formatShortDate(DateTime d) => '${d.day} th ${d.month}';

/// Seed mock entries — khi mở app lần đầu. State sau đó mutable trong
/// `_DiaryListScreenState._entries` để insert entry mới khi save Canvas.
final List<_MockEntry> _seedMockEntries = [
  _MockEntry(
    title: 'Happy!',
    date: DateTime(2026, 5, 22),
    mood: MoodTemplate.happy,
  ),
  _MockEntry(
    title: 'Tired',
    date: DateTime(2026, 5, 20),
    mood: MoodTemplate.tired,
  ),
  _MockEntry(
    title: 'Title nhật ký',
    date: DateTime(2026, 5, 19),
    mood: MoodTemplate.bored,
  ),
  _MockEntry(
    title: 'Đà lạt',
    date: DateTime(2026, 5, 18),
    mood: MoodTemplate.happy,
  ),
];

/// View mode cho danh sách nhật ký — Grid 2-col vs List dọc.
enum _ViewMode { grid, list }

class _DiaryListScreenState extends State<DiaryListScreen> {
  bool _pickerOpen = false;
  _ViewMode _viewMode = _ViewMode.grid;

  /// Mutable copy của seed mock — entry mới insert lên đầu khi user save
  /// Canvas (FE mock). Khi wire DiaryRepository: bỏ list này, đổi sang
  /// `StreamProvider` watch `/diary_entries` của user.
  late final List<_MockEntry> _entries = [..._seedMockEntries];

  void _togglePicker() => setState(() => _pickerOpen = !_pickerOpen);
  void _closePicker() => setState(() => _pickerOpen = false);

  /// Tap 1 mood trong picker — close picker, push Canvas create, đợi user
  /// save → insert entry mới lên đầu list.
  Future<void> _onMoodSelected(MoodTemplate mood) async {
    _closePicker();
    final result = await Navigator.of(context).push<DiaryDraftResult>(
      MaterialPageRoute<DiaryDraftResult>(
        builder: (_) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.create,
          moodTemplate: mood,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _entries.insert(
        0,
        _MockEntry(
          title: result.caption,
          date: result.createdAt,
          mood: result.mood,
          content: result.content,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                // Body co giãn: Grid / List / Empty
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

  // ── Body: render theo view mode hoặc empty state ──
  Widget _buildBody() {
    if (_entries.isEmpty) return _buildEmptyState();
    return _viewMode == _ViewMode.grid ? _buildGrid() : _buildList();
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 39),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 150.5 / 182,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final e = _entries[index];
        return DiaryMoodCard(
          title: e.title,
          date: _formatShortDate(e.date),
          mood: e.mood,
          onTap: () => _openCanvasRead(e),
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final e = _entries[index];
        return DiaryListCard(
          title: e.title,
          date: _formatShortDate(e.date),
          mood: e.mood,
          onTap: () => _openCanvasRead(e),
        );
      },
    );
  }

  void _openCanvasRead(_MockEntry e) {
    // Entry mới chưa có content → dùng text user vừa nhập (có thể rỗng).
    // Entry seed (content rỗng) → demo bằng mock content + image.
    final isSeed = e.content.isEmpty;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryCanvasScreen(
          mode: DiaryCanvasMode.read,
          moodTemplate: e.mood,
          initialCaption: e.title,
          initialContent: isSeed ? _devMockContent : e.content,
          initialImageUrl: isSeed ? _devMockImageUrl : null,
          entryDate: e.date,
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

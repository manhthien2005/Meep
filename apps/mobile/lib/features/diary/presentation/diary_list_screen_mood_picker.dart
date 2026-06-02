part of 'diary_list_screen.dart';

/// Mood picker layer — title "Hôm nay bạn thế nào?" + 5 mood arc.
///
/// Figma `656:1953`. Vòng cung 5 mood bao quanh nửa trên FAB.
/// Dùng LayoutBuilder để lấy chiều cao safe area → tính tâm arc theo FAB.
class _MoodPickerLayer extends StatelessWidget {
  const _MoodPickerLayer({required this.onMoodSelected});

  /// Callback khi user tap 1 mood. State (DiaryListScreen) đóng picker +
  /// push Canvas + chờ result.
  final ValueChanged<MoodTemplate> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        // FAB center từ đáy = bottom(90) + radius(30) = 120.
        // Tâm arc cao hơn FAB center 30px → vòng cung ôm sát nửa trên FAB.
        final centerY = constraints.maxHeight - 150;

        return Stack(
          children: [
            // Title "Hôm nay bạn thế nào?" — phía trên vòng cung
            Positioned(
              top: centerY - 100,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Hôm nay bạn thế nào?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bw100,
                    height: 22 / 16,
                  ),
                ),
              ),
            ),

            // 5 mood frames — arc layout quanh tâm
            for (final mood in _moodSpecs)
              Positioned(
                left: centerX + mood.offset.dx - mood.width / 2,
                top: centerY + mood.offset.dy - mood.height / 2,
                child: _MoodFrame(mood: mood, onTap: onMoodSelected),
              ),
          ],
        );
      },
    );
  }
}

/// Mood spec — code key, label, asset, size (từ Figma `656:1953`).
class _MoodSpec {
  const _MoodSpec({
    required this.key,
    required this.label,
    required this.asset,
    required this.width,
    required this.height,
    required this.offset,
  });

  final String key;
  final String label;
  final String asset;
  final double width;
  final double height;

  /// Offset từ tâm arc (Figma coordinates).
  final Offset offset;
}

/// 5 mood specs — vị trí arc từ Figma `656:1953`. Tâm arc ~ (190, 700).
const List<_MoodSpec> _moodSpecs = [
  _MoodSpec(
    key: 'happy',
    label: 'Vui vẻ',
    asset: 'assets/icons/icon_happy.png',
    width: 51,
    height: 51,
    offset: Offset(0, -46), // top center
  ),
  _MoodSpec(
    key: 'bored',
    label: 'Chán nản',
    asset: 'assets/icons/icon_bored.png',
    width: 45,
    height: 45,
    offset: Offset(62, -20), // right
  ),
  _MoodSpec(
    key: 'tired',
    label: 'Mệt mỏi',
    asset: 'assets/icons/icon_tired.png',
    width: 56,
    height: 50,
    offset: Offset(85, 35), // bottom right
  ),
  _MoodSpec(
    key: 'shy',
    label: 'Ngại ngùng',
    asset: 'assets/icons/icon_shy.png',
    width: 60,
    height: 47.5,
    offset: Offset(-70, -23), // left
  ),
  _MoodSpec(
    key: 'sad',
    label: 'Buồn bã',
    asset: 'assets/icons/icon_sad.png',
    width: 48,
    height: 45,
    offset: Offset(-92, 37), // bottom left
  ),
];

/// 1 mood frame — image thuần (không stroke để giữ shape gốc) + tap handler.
class _MoodFrame extends StatelessWidget {
  const _MoodFrame({required this.mood, required this.onTap});

  final _MoodSpec mood;

  /// Callback khi tap — State (DiaryListScreen) handle push Canvas + nhận
  /// DiaryDraftResult để insert entry mới.
  final ValueChanged<MoodTemplate> onTap;

  /// Map mood key → MoodTemplate enum.
  MoodTemplate get _template => switch (mood.key) {
        'happy' => MoodTemplate.happy,
        'bored' => MoodTemplate.bored,
        'tired' => MoodTemplate.tired,
        'shy' => MoodTemplate.shy,
        _ => MoodTemplate.sad,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(_template),
      child: Semantics(
        label: mood.label,
        button: true,
        child: Image.asset(
          mood.asset,
          width: mood.width,
          height: mood.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

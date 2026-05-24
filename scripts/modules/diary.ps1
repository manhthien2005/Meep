# scripts/modules/diary.ps1
# Module: Diary | Owner: HanDHG | M3

function Create-DiaryModule {
    $parentBody = @'
> **Tier:** T0+ | **Milestone:** M3 | **Assignee:** HanDHG
> **Spec:** `docs/specs/2026-05-23-diary.md`
> **Plan:** `docs/plans/2026-05-23-diary.md`
> **Todo:** `tasks/todo-diary.md`
> **Phụ thuộc vào:** Auth (UserProfile, currentUid)
> **Được phụ thuộc bởi:** Profile (DiaryRepository.getPublicEntries — Profile Diary tab)
> ⚠️ **T3 blocked** cho đến khi HanDHG export 11 assets

## Mục tiêu
Nhật ký cá nhân: chọn mood template, viết text + inline ảnh, toggle public/private, xem danh sách, tìm kiếm.

## Data model
**`/diary/{entryId}`**
```
entryId, authorUid, moodTemplate (happy/bored/tired/shy/sad),
coverImageUrl, moodCaption (≤50 chars),
content: List<DiaryContentBlock> (≤20 blocks),
privacy (private/public), createdAt, updatedAt
```
**`DiaryContentBlock`**: `type (text/image)`, `value?`, `style? (normal/heading/subheading/quote)`, `imageUrl?`

## Contract artifacts (ThienPDM đã merge qua LX8)
- `lib/features/diary/data/diary_entry.dart`, `diary_content_block.dart` — @freezed
- `lib/features/diary/data/diary_repository.dart` — abstract (**`getPublicEntries(authorUid)` phải có**)
- `lib/features/diary/application/diary_controller.dart` — stub + `DiaryState`
- `lib/features/diary/presentation/diary_canvas_screen.dart` — stub + `DiaryCanvasMode` enum (create/read/edit)
- Screen stubs (5 màn hình), routes `/diary`, `/diary/create`, `/diary/:entryId`

## Designer dependency (T3)
HanDHG phải export 11 assets trước T3: 5 SVG mood icons + 5 bg PNG + 1 Polaroid PNG
- `assets/moods/icon_happy.svg`, `icon_bored.svg`, `icon_tired.svg`, `icon_shy.svg`, `icon_sad.svg`
- `assets/moods/bg_happy.png` ... `bg_sad.png`
- `assets/frames/frame_polaroid.png`
'@

    $subs = @(
        @{
            title = "[Diary] T1 — FirebaseDiaryRepository"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-diary.md` — Task T1
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/diary-repository`
> **Bị block bởi:** LX8 contracts đã merge

## Files cần tạo
- `lib/features/diary/data/firebase_diary_repository.dart`
- `test/features/diary/data/firebase_diary_repository_test.dart`

## Acceptance criteria
- [ ] `createEntry` dùng Firestore auto-ID, trả `entryId`
- [ ] `watchEntries(uid)` ORDER BY `createdAt DESC` — chỉ entries của owner
- [ ] `getPublicEntries(authorUid)` filter `privacy == 'public'` — **trả `Future<List>`, không phải Stream** (Profile module dùng)
- [ ] `searchEntries(uid, query)` load all entries → filter in-memory case-insensitive (MVP, đủ cho <100 entries)
- [ ] `updateEntry` không cho đổi `authorUid` (check trong repository)
- [ ] `flutter test test/features/diary/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS (fake_cloud_firestore)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Diary] T2 — DiaryController"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-diary.md` — Task T2
> **Estimate:** S (~4h) | **Branch:** `feat/<DevName>/diary-controller`
> **Bị block bởi:** {sub0} — T1 phải done

## Files cần tạo
- `lib/features/diary/application/diary_controller.dart` — `DiaryState` + full impl
- `test/features/diary/application/diary_controller_test.dart`

## `DiaryState` schema
```dart
@freezed class DiaryState {
  List<DiaryEntry> entries
  DiaryEntry? currentEntry
  bool isLoading
  DiaryCanvasMode mode
  List<DiaryEntry> searchResults
}
```

## Acceptance criteria
- [ ] `saveEntry()` trong `DiaryCanvasMode.create` → `createEntry()`; trong `edit` → `updateEntry()`
- [ ] Upload sequence: (1) cover image → coverUrl, (2) inline images tuần tự, (3) TẤT CẢ URLs sẵn → Firestore write
- [ ] Upload fail bất kỳ bước → toast, **KHÔNG** tạo/update Firestore doc
- [ ] `saveEntry` validate: phải có ít nhất 1 ảnh cover + 1 ký tự text
- [ ] `updatePrivacy(entryId, privacy)` → update chỉ field `privacy` + `updatedAt`
- [ ] `flutter test test/features/diary/application/` — 0 failures

## Definition of Done
- [ ] Tests PASS (mocktail)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Diary] T3 — Mood assets + MoodZoneBlock + MoodClipper"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-diary.md` — Task T3
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/diary-mood-assets`
> **Bị block bởi:** {sub0} — T1 done; **HanDHG phải export 11 assets trước** (self-blocked)

## Files cần tạo
- `assets/moods/icon_happy.svg`, `icon_bored.svg`, `icon_tired.svg`, `icon_shy.svg`, `icon_sad.svg`
- `assets/moods/bg_happy.png` ... `bg_sad.png` (5 files)
- `assets/frames/frame_polaroid.png`
- `lib/features/diary/presentation/widgets/mood_zone_block.dart` — Stack: bg shape + ClipPath cover + caption
- `lib/features/diary/presentation/widgets/mood_clipper.dart` — `CustomClipper` per mood
- `pubspec.yaml` — **update:** thêm `flutter_svg` + asset declarations

## Acceptance criteria — MoodClipper per mood
- [ ] `happy`: `BorderRadius.circular(~38.5)` (circle)
- [ ] `bored`: `BorderRadius.circular(10)` (rounded rect)
- [ ] `tired`, `shy`, `sad`: `CustomClipper` extract path từ SVG data (HanDHG cung cấp)
- [ ] `MoodZoneBlock` render: bg shape layer + clipped cover photo + moodCaption với turquoise underline
- [ ] Canvas background: `Scaffold(backgroundColor: Color(0xFFF9FCFC))` — **KHÔNG** dùng `Theme.of(context)`
- [ ] `flutter analyze` clean

## Definition of Done
- [ ] Visual check: 5 mood frames render đúng trên device
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Diary] T4+5 — DiaryCreateScreen + DiaryCanvasScreen"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-diary.md` — Task T4, T5
> **Estimate:** L (2 ngày) | **Branch:** `feat/<DevName>/diary-canvas`
> **Bị block bởi:** {sub1} — T2 done; {sub2} — T3 (MoodZoneBlock) done
> **Figma:** DiaryCreate `656:1953`, DiaryCanvas (xem spec §Màn hình)

## Files cần tạo
- `lib/features/diary/presentation/diary_create_screen.dart` — overlay "Hôm nay bạn thế nào?"
- `lib/features/diary/presentation/diary_canvas_screen.dart` — full impl
- `lib/features/diary/presentation/widgets/text_block_widget.dart` — TextField (edit) / Text (read)
- `lib/features/diary/presentation/widgets/inline_image_block_widget.dart` — Polaroid frame + user image
- `lib/features/diary/presentation/widgets/text_style_picker.dart` — Normal/Heading/Sub-heading/Quote
- `lib/features/diary/presentation/privacy_sheet.dart`
- `lib/features/diary/presentation/discard_changes_dialog.dart`

## Acceptance criteria — DiaryCreateScreen
- [ ] 5 mood frames horizontal scroll, preview ảnh gần nhất từ gallery
- [ ] Tap mood → moodTemplate + cover ảnh → `DiaryCanvasScreen(mode: create)`
- [ ] Fallback gallery trống: placeholder image, vẫn cho chọn mood

## Acceptance criteria — DiaryCanvasScreen
- [ ] Layout: `MoodZoneBlock` (cố định header) → content blocks
- [ ] 4 text styles: Normal (body), Heading (H1 bold), Sub-heading (H2), Quote (italic + left border)
- [ ] `[←]` trong `create` mode → `DiscardChangesDialog`; trong `read/edit` → về list trực tiếp
- [ ] Max 20 content blocks → nút thêm disable
- [ ] Max 5 images (cover + 4 inline) → nút chèn ảnh disable
- [ ] `PrivacySheet`: [Riêng tư] / [Công khai] → tap [Xong] → topbar icon đổi lock/unlock

## Definition of Done
- [ ] Manual: tạo → mood → canvas gõ → lưu → list hiện card
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title = "[Diary] T6+7+8 — DiaryListScreen + DiarySearchScreen + Firestore rules"
            body  = @'
> **Plan:** `docs/plans/2026-05-23-diary.md` — Task T6, T7, T8
> **Estimate:** M (~8h) | **Branch:** `feat/<DevName>/diary-list-rules`
> **Bị block bởi:** {sub3} — T4+5 done; {sub0} — T1 done (rules cần schema)
> **Figma:** DiaryList `656:1831`, DiarySearch `712:4356`

## Files cần tạo
- `lib/features/diary/presentation/diary_list_screen.dart` — grid 2-col (Figma `656:1831`)
- `lib/features/diary/presentation/widgets/diary_mood_card.dart` — 120×120 clip theo mood shape, date label
- `lib/features/diary/presentation/diary_search_screen.dart` (Figma `712:4356`)
- `firebase/functions/test/rules/diary.rules.test.ts`

## Acceptance criteria — DiaryListScreen
- [ ] Grid 2-col, gap 32px, `DiaryMoodCard` 150.5px wide
- [ ] Empty state: "Bạn chưa có nhật ký nào" + FAB 60×60 Turquoise/500
- [ ] FAB → `DiaryCreateScreen` overlay

## Acceptance criteria — DiarySearchScreen
- [ ] `DiaryController.searchEntries(uid, query)` filter in-memory case-insensitive
- [ ] Kết quả: keyword highlight + `"DD tháng M năm YYYY"` format
- [ ] "N kết quả" label; 0 kết quả → empty state "0 kết quả"

## Acceptance criteria — Rules
- [ ] `/diary/{id}`: owner read ✓ (cả private + public); friend read public ✓; friend read private ✗; stranger ✗
- [ ] `/diary/{id}`: create chỉ owner ✓; `moodCaption.size() > 50` ✗; `content.size() > 20` ✗
- [ ] Storage `diary/{uid}/...`: owner write ✓, >10MB ✗, non-image ✗

## Cross-module imports
- `isFriend()` helper từ **friend** (dùng trong diary read rule)

## Definition of Done
- [ ] Manual: list scroll; search filter; privacy rule đúng
- [ ] Rules tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "📔 [Diary]" $parentBody $HanDHG 3 $subs
}

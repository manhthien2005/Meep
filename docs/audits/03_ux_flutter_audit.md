# 03_ux_flutter_audit

## meta

- repo: Meep
- root: D:/meep-audit-03-ux
- branch: docs/ThienPDM/03-ux-flutter-audit
- date: 2026-06-07
- mode: audit-only
- audit_focus: flutter_ux
- modified_files_allowed:
  - docs/audits/03_ux_flutter_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - docs/audits/A_PHASE_BASELINE_SUMMARY.md
  - docs/audits/01_architecture_audit.md
  - docs/audits/05_security_firebase_audit.md
  - CLAUDE.md (root) — §Domain Caption ≤ 30 chars + §Security Guardrails
  - apps/mobile/CLAUDE.md — §Loading/error/empty 4 states + §Design tokens + §Accessibility + §Figma → Flutter mapping
  - .claude/reference-architectures/auth.md — Pattern #5 (state pattern), Pattern #10 (Vietnamese boundary message)
  - docs/adr/0005-deeplink-architecture.md

## precheck

- git_status_before: `?? tmp/` (expected per inventory baseline)
- existing_user_changes: no (matches baseline `00_inventory_map.md §baseline_git_status`; `M apps/mobile/pubspec.lock` absent because this is a fresh worktree clone)
- target_report_preexisting_dirty: no (file did not exist before this run)

## commands

| cmd | status | notes |
|---|---:|---|
| `git rev-parse --show-toplevel` + `git status --short` + `git branch --show-current` | ok | precheck baseline |
| Glob `apps/mobile/lib/features/**/presentation/**/*.dart` | ok | 100+ presentation widget files mapped |
| Glob `apps/mobile/lib/shared/widgets/**/*.dart` | ok | 22 shared widgets per inventory map |
| Glob `apps/mobile/lib/core/**/*.dart` | ok | 13 core files (router/theme/error/validators/utils) |
| Grep `AsyncValue\|\.when\(\|CircularProgressIndicator` apps/mobile/lib | ok | 29 files use AsyncValue.when |
| Grep `\.when\(` apps/mobile/lib | ok | 15 explicit `.when` callers across feed/diary/chat/profile/settings/space/friend |
| Grep `SnackBar\|showDialog\|ScaffoldMessenger` apps/mobile/lib | ok | 25 files |
| Grep `TextField\|TextFormField\|Form(\|validator\|AutovalidateMode` apps/mobile/lib | ok | 19 files; **0 AutovalidateMode hits** |
| Grep `PopScope\|WillPopScope\|onWillPop` apps/mobile/lib | ok | **0 hits — no system-back guard anywhere** |
| Grep `Color\(0x` apps/mobile/lib/features | ok | 66 hits across 28 feature files outside core/theme |
| Grep `TextStyle\(fontSize` apps/mobile/lib/features | ok | 16 hits across 14 feature files outside core/theme |
| Grep `Semantics\|tooltip\|excludeSemantics` apps/mobile/lib | ok | 49 files mention; spot-check shows partial coverage |
| Grep `SafeArea\|resizeToAvoidBottomInset\|MediaQuery\.of\|textScaler\|textScaleFactor` apps/mobile/lib | ok | 36 files |
| Grep `RefreshIndicator\|onRefresh\|pull.*to.*refresh` apps/mobile/lib | ok | **only 1 comment hit — no `RefreshIndicator` widget anywhere** |
| Grep `HapticFeedback` apps/mobile/lib | ok | **1 hit total** (intro_page.dart:219 swipe only) |
| Grep `CachedNetworkImage\|placeholder\|errorWidget` apps/mobile/lib | ok | 26 files; placeholder/errorWidget used in feed/profile/diary/chat shared widgets |
| Grep `DateFormat\|intl\|toString()` apps/mobile/lib/features | ok | 18 hits; date `${dt.day} thg ${dt.month}` hand-format in `feed_section.dart:114` |
| Grep `mounted\|context\.mounted` apps/mobile/lib | ok | 33 files; auth pages explicit `mounted` check after await per Pattern #7 |
| Grep `permission\|denied\|offline\|retry` apps/mobile/lib | ok | 22 files; mostly server-side error message strings, not UI affordances |
| Grep `availableCameras\|CameraException` apps/mobile/lib | ok | only `availableCameras` in `app_camera_controller.dart:27`; no typed permission handling |
| Grep `fcmPermissionDenied` apps/mobile/lib | ok | **state field set in `notification_controller.dart:74`, ZERO UI consumers** |
| Grep `sendStatus\.errorMessage` apps/mobile/lib | ok | **ZERO consumers** — chat send fail invisible to user |
| Grep `setCaption\b` apps/mobile/lib | ok | 1 caller (capture_preview_screen → AppNotePill) |
| Read `apps/mobile/lib/features/feed/presentation/{feed_section,home_screen,camera_section,capture_preview_screen}.dart` | ok | feed empty + error + camera permission UX walked |
| Read `apps/mobile/lib/features/auth/presentation/login/login_password_page.dart` + signup pages | ok | sign-in/up form UX walked |
| Read `apps/mobile/lib/features/chat/presentation/{inbox_screen,chat_screen,chat_thread_view}.dart` | ok | chat empty + send error UX walked |
| Read `apps/mobile/lib/features/friend/presentation/friend_sheet.dart` | ok | friend accept/decline/cancel + decline X 20x20 confirmed |
| Read `apps/mobile/lib/features/diary/presentation/{diary_list_screen,diary_canvas_screen}.dart` | ok | diary empty + back-without-popscope confirmed |
| Read `apps/mobile/lib/features/settings/presentation/{delete_account_dialog,logout_confirm_dialog,settings_sheet}.dart` | ok | destructive confirms verified |
| Read `apps/mobile/lib/features/notification/application/notification_controller.dart` | ok | fcmPermissionDenied gap confirmed |
| Read `apps/mobile/lib/features/feed/application/{app_camera_controller,post_controller}.dart` | ok | camera error + upload error mapping read |
| Read `apps/mobile/lib/shared/widgets/{app_text_input,app_note_pill,app_primary_button}.dart` | ok | input a11y + caption maxLength counter confirmed |
| Read `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` (head) | ok | hardcoded `Color(0xFF73706E) + Color(0xFFDDDDDD)` with self-comment "Missing design tokens — ping leader" |
| `flutter analyze --no-pub` | blocked | not run — audit-only constraint (LAYER B "KHÔNG fix code"); static evidence sufficient |

## coverage

- auth flow: checked — read login_email/login_password/reset_password + signup_email/password/name/username pages + forgot_password_dialog; verified PrimaryButton disables when isLoading, error pill renders state.errorMessage, password show/hide toggle exists
- camera/share flow: checked — `app_camera_controller.dart` + `camera_section.dart` + `capture_preview_screen.dart` + `post_controller.dart` all read; permission denial path + caption length + upload error rendering walked
- feed flow: checked — `feed_section.dart` head + `_EmptyState` + `_FeedFooter` + `home_screen.dart` `_EmptyFeedPage` read; pagination footer + empty state + error state inventoried
- friend flow: checked — `friend_sheet.dart` head + `_buildRequestItem` + `_buildSearchResultBody` + `_confirmUnfriend` read; accept/decline + 20x20 X icon + sent-cancel + unfriend confirm verified
- notification UX: checked — `notification_controller.dart` full read; `fcmPermissionDenied` UI consumer search returned 0 hits
- widget (Flutter side) UX: partial — `widget_data_service.dart` referenced via SEC audit; pin-widget guide search returned 0 hits in Flutter side; native MeepWidget out of scope for 03_ux_flutter (Kotlin)
- profile flow: partial — `edit_profile_screen.dart` head + theme drift comments read; full edit form not deep-read (token drift already evidenced; per-field validation behavior tracked via `state.errorMessage` + SnackBar pattern verified)
- diary flow: checked — `diary_list_screen.dart` empty state + `diary_canvas_screen.dart:396-411 _handleBack` discard dialog read; PopScope absence confirmed via global grep
- space flow: partial — Glob lists 11 space widgets; multi-step create flow not deep-read but `friend_select_step.dart` exists; out-of-scope Tier 0+ deep dive
- reaction UX: partial — `emoji_picker_sheet.dart` + `reaction_list_sheet.dart` Glob'd only; HapticFeedback global grep returned 1 hit (intro only), so reaction-tap haptic gap inferred
- streak UX: partial — Tier 1 stretch; `streak_screen.dart` + 4 widgets Glob'd; calendar empty state via grep returned `Bạn chưa có nhật ký nào` pattern in diary; streak deep-read deferred (not Tier 0)
- chat UX: checked — `inbox_screen.dart` empty + error pure-text + `chat_thread_view.dart:230 _EmptyThread` + `chat_screen.dart:42 sendStatus` non-consumption verified
- settings flow: checked — `settings_sheet.dart` logout + delete handler + `LogoutConfirmDialog` + `DeleteAccountDialog` 2-step + reauth full read
- shared widgets API consistency: checked — `app_text_input.dart` + `app_note_pill.dart` + `app_primary_button.dart` + `app_confirm_dialog.dart` referenced by friend_sheet `showAppConfirmDialog`; AppNotePill counter suppression confirmed
- theme/design tokens: checked — `core/theme/` Glob'd (app_colors/proportions/radii/spacing/text_styles/theme/hex_color); 66 `Color(0x` + 16 `TextStyle(fontSize:` outside theme counted; explicit `Missing design tokens` comment in `edit_profile_screen.dart:25-27`
- router/deeplink: partial — `app_router.dart` covered by ARCH-DEEPLINK-001; UX-side ADR-0005 cold/warm start consistency not re-deep-read (ARCH already flagged)

## blockers_summary

Only P0/P1.

| id | sev | area | files | short |
|---|---|---|---|---|
| CAMERA-UX-001 | P0 | Camera permission UX — golden path break | `apps/mobile/lib/features/feed/application/app_camera_controller.dart`, `apps/mobile/lib/features/feed/presentation/camera_section.dart` | Camera permission denied → silent black box with no Vietnamese message, no "Mở Cài đặt" CTA, no retry — user cannot post |
| STATE-UX-EMPTY-001 | P1 | 4-state empty branch missing CTA (12 sites) | feed/inbox/chat/diary/profile/friend-profile/space-context/reaction-list + 2 shared profile widgets (photo_grid + diary_tab_content) + grid_view_screen | 12 empty states là plain Text/Center — KHÔNG có Vietnamese CTA tappable (chỉ streak `EmptyStateOverlay` có arrow chỉ taskbar); vi phạm `apps/mobile/CLAUDE.md §Empty state must have a Vietnamese CTA` |
| STATE-UX-ERROR-001 | P1 | Error state thiếu retry affordance (12 sites / 11 files) | feed/home/inbox/streak/blocked-accounts/friend-profile (gate + post-grid) + diary-list + profile + space-edit-sheet + space-management-sheet + grid-view-screen | 12 error branches chỉ render Text + KHÔNG có retry; `_ErrorView` space-edit chỉ "Đóng", `_GateMessage` friend-profile chỉ "Quay lại", `_ErrorBanner` streak red bar persist không dismiss; user stuck trên dead screen |
| NOTIF-UX-PERM-001 | P1 | FCM permission denial silent | `apps/mobile/lib/features/notification/application/notification_controller.dart`, `apps/mobile/lib/main.dart` | `state.fcmPermissionDenied` set ở `notification_controller.dart:74` nhưng KHÔNG có UI consumer (grep 0 hits) — user denies notification permission → app không hiển thị banner/CTA mở Settings |
| CHAT-UX-SEND-001 | P1 | Chat send fail silent (text + emoji-picker + quick-emoji) | `apps/mobile/lib/features/chat/presentation/chat_screen.dart`, `apps/mobile/lib/features/chat/presentation/group_chat_screen.dart`, `apps/mobile/lib/features/chat/application/chat_controller.dart`, `apps/mobile/lib/features/chat/presentation/widgets/chat_input_bar.dart` | `sendStatus.errorMessage` set (chat_controller.dart:55) nhưng UI chỉ watch `isSending` (0 hits cho `sendStatus.errorMessage` toàn lib); `ChatInputBar` clear input ngay sau `onSend` (line 55-59); emoji-picker tap (line 100) + quick-emoji tap (line 158) cùng pattern silent fail; message gone, không retry |
| NAV-UX-POPSCOPE-001 | P1 | Unsaved-changes warning bị bypass khi system back | `apps/mobile/lib/features/diary/presentation/diary_canvas_screen.dart`, `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart`, `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart`, toàn codebase | Grep `PopScope\|WillPopScope\|onWillPop` = 0 hits; diary có `_handleBack` chỉ qua AppBackButton tap (Android system back skip); capture_preview KHÔNG có back handler nào (cả tap lẫn gesture mất draft); edit_profile chỉ `Navigator.pop()` không isDirty check |
| UPLOAD-UX-001 | P1 | Upload fail thiếu retry button | `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart`, `apps/mobile/lib/features/feed/application/post_controller.dart` | Upload fail → `postState.errorMessage` render as red Text (capture_preview_screen.dart:225-234) KHÔNG có retry button; user phải back ra rồi vào lại sau khi sửa lỗi — draft (compressed bytes) bị mất |

## issues

### ISSUE CAMERA-UX-001

- sev: P0
- blocker: yes
- area: Camera permission UX — golden path
- files:
  - `apps/mobile/lib/features/feed/application/app_camera_controller.dart`
  - `apps/mobile/lib/features/feed/presentation/camera_section.dart`
- loc: `app_camera_controller.dart:25-45` (initialize); `camera_section.dart:511-520` (`_ViewfinderContent.build` error branch); `camera_section.dart:344-368` (`_DualViewfinderContent` error branch — same shape)
- symbols:
  - `AppCameraController.initialize`
  - `_ViewfinderContent.build`
- evidence: `state = state.copyWith(error: e.toString());` (app_camera_controller.dart:43) + viewfinder error branch renders only `Container(color: AppColors.bw800, alignment: Alignment.center, child: const Icon(Icons.no_photography, color: AppColors.bw500, size: 48))` (camera_section.dart:513-519) — KHÔNG render error text, KHÔNG retry button, KHÔNG "Mở Cài đặt" CTA
- user_impact: User mới install + deny camera permission → mở app → swipe lên camera tab (page 0 mặc định) → thấy ô đen với icon máy ảnh gạch → không có instruction nào để recover → KHÔNG biết phải vào Settings > Apps > Meep > Permissions; không thể post (Tier 0 core feature). Golden path "user can post" break per `apps/mobile/CLAUDE.md §Loading/error/empty` (4-state contract require error có actionable hint, không chỉ icon).
- risk: production launch blocker — first-time install Android 6+ runtime permission ask is the universal pattern, user reject xảy ra rất thường (sách-cách user mistrust new app). Khi xảy ra, Meep gateway feature chết im → user uninstall thay vì grant permission.
- fix:
  1. Trong `app_camera_controller.dart` distinguish `CameraException` codes — `CameraAccessDenied` / `CameraAccessRestricted` set typed enum field (vd `state.copyWith(permissionState: CameraPermissionState.denied)` thay vì free-string error). Map `'No camera found'` riêng (state.error = no-hardware) vs permission denied (state.permissionState = denied).
  2. Trong `_ViewfinderContent.build`, khi `state.permissionState == denied` render full Column: `Icon` + `Text('Meep cần quyền truy cập máy ảnh để chụp ảnh')` (Vietnamese per `auth.md` Pattern #10) + `AppPrimaryButton(label: 'Mở Cài đặt', onPressed: () => openAppSettings())` (cần thêm `permission_handler` package — leader gate per ADR-0004 strict gate).
  3. Khi `state.error == 'No camera found'` (emulator hoặc thiết bị hỏng) render Vietnamese fallback "Không tìm thấy máy ảnh trên thiết bị".
  4. Thêm `Future<void> retry()` method trên controller để retry button hoạt động sau khi user grant permission từ Settings.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty — 4 required states` ("Error view có retry button + actionable hint, KHÔNG just 'Lỗi xảy ra'"); `.claude/reference-architectures/auth.md` Pattern #10 (Vietnamese boundary message); `CLAUDE.md §MVP Scope Tier 0 — Camera + Share photo` (golden path)
- test: widget test `test/features/feed/presentation/camera_section_test.dart` override `appCameraControllerProvider` với state.permissionState = denied; assert tìm `Text('Mở Cài đặt')` finder + onPressed callable. Manual repro: Android Settings > Apps > Meep > Permissions > Camera deny → relaunch → expect screen visible với CTA. Run `flutter test test/features/feed/presentation/`.
- deps: PERM-001 (SEC) — adding `permission_handler` dep cần leader gate per ADR-0004 strict gate (`Thêm pub package vào pubspec.yaml`)

### ISSUE STATE-UX-EMPTY-001

- sev: P1
- blocker: no
- area: 4-required-states — empty branch missing Vietnamese CTA button (12 sites across 10 files)
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart`
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart`
  - `apps/mobile/lib/features/feed/presentation/grid_view_screen.dart`
  - `apps/mobile/lib/features/chat/presentation/inbox_screen.dart`
  - `apps/mobile/lib/features/chat/presentation/chat_thread_view.dart`
  - `apps/mobile/lib/features/diary/presentation/diary_list_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/widgets/photo_grid.dart`
  - `apps/mobile/lib/features/profile/presentation/widgets/diary_tab_content.dart`
  - `apps/mobile/lib/features/reaction/presentation/reaction_list_sheet.dart`
  - `apps/mobile/lib/features/space/presentation/space_context_bottom_sheet.dart`
- loc: feed_section.dart:997-1031 `_EmptyState`; home_screen.dart:596-630 `_EmptyFeedPage`; grid_view_screen.dart:80-86; inbox_screen.dart:167-182 `_InboxMessage` + line 47-52; chat_thread_view.dart:230-270 `_EmptyThread`; diary_list_screen.dart:375-388 `_buildEmptyState`; profile_screen.dart:224-231; friend_profile_screen.dart:297-303; widgets/photo_grid.dart:17-21; widgets/diary_tab_content.dart:33-38; reaction_list_sheet.dart:65-69; space_context_bottom_sheet.dart:105-109
- symbols: feed `_EmptyState`/`_EmptyFeedPage`/grid_view "Chưa có ảnh"; chat `_InboxMessage`/`_EmptyThread`; diary `_buildEmptyState`; profile post-grid + shared `photo_grid` + shared `diary_tab_content`; reaction `reaction_list_sheet`; space `space_context_bottom_sheet`
- evidence:
  - feed_section.dart:1009 — `'Chụp ảnh đầu tiên và gửi cho bạn bè!'` text-only
  - home_screen.dart:608 — `'Chưa có ảnh nào'` text-only
  - grid_view_screen.dart:82 — `'Chưa có ảnh'` text-only
  - inbox_screen.dart:50 — `'Chưa có tin nhắn nào — reply một ảnh để bắt đầu'` text-only
  - chat_thread_view.dart — `'Trả lời một Meep của $peerName để bắt đầu trò chuyện'` no CTA
  - diary_list_screen.dart:378 — `'Bạn chưa có nhật ký nào'` text-only (FAB adjacent là implicit affordance)
  - profile_screen.dart:226 — `'Chưa có ảnh nào'` text-only (own profile)
  - friend_profile_screen.dart:300 — `'Chưa có ảnh nào'` text-only (friend post grid)
  - photo_grid.dart:19 — `'Chưa có ảnh nào'` text-only (shared widget)
  - diary_tab_content.dart:35 — `'Chưa có nhật ký công khai'` text-only (profile diary tab)
  - reaction_list_sheet.dart:67 — `'Chưa có phản ứng nào'` text-only
  - space_context_bottom_sheet.dart:107 — `'Bạn chưa tham gia Space nào'` text-only
  - Counter-example: streak `EmptyStateOverlay` (line 37-92) RENDER ĐÚNG arrow chỉ taskbar send — implicit visual CTA OK; chỉ tham khảo, không flag.
- user_impact: 12 empty states không có Vietnamese CTA tappable. Feed/home onboarding loop chết im; inbox/chat thread mơ hồ; profile/friend-profile empty không hướng dẫn; reaction list không có back; space picker thiếu "Tạo Space mới". `photo_grid` + `diary_tab_content` là shared widgets nên fix 1 chỗ cover nhiều screens.
- risk: onboarding drop-off — Locket-parity social loop "chụp → gửi → bạn nhìn → reaction" cần CTA progression ở 12 entry points. `apps/mobile/CLAUDE.md §Loading/error/empty` explicit "Empty state must have a Vietnamese CTA" — rule violation rộng 12 sites cross Tier 0 + Tier 0+.
- fix:
  1. `_EmptyState` (feed_section.dart) — phân biệt 2 case bằng `ref.watch(friendControllerProvider(uid)).friends.isEmpty`. No friends: "Thêm bạn bè" → FriendSheet. Have friends no posts: "Chụp ảnh đầu tiên" → `_pageController.animateToPage(0, ...)`.
  2. `_EmptyFeedPage` (home_screen.dart) — same logic. Consolidate sang shared `lib/shared/widgets/feed_empty_state.dart` (cần leader gate).
  3. `grid_view_screen.dart` — empty space feed: "Đăng ảnh đầu tiên cho Space" → camera với pre-fill spaceId.
  4. `_InboxMessage` empty case — button "Mở feed" → `context.go('/home')`.
  5. `_EmptyThread` — `AppPrimaryButton(label: 'Xem ảnh của $peerName', onPressed: () => context.push('/friend-profile/$peerUid'))`.
  6. `_buildEmptyState` (diary) — hint "Bấm nút + bên dưới để tạo nhật ký đầu tiên" với `Icon(Icons.arrow_downward)` chỉ FAB.
  7. profile_screen + friend_profile + shared `photo_grid` — refactor `photo_grid` thêm `emptyAction` param optional; profile_screen pass "Chụp ảnh đầu tiên" → camera; friend_profile pass null.
  8. `diary_tab_content` empty — button "Xem nhật ký công khai khác" (Tier 1, có thể defer).
  9. `reaction_list_sheet` empty — text "Chưa có phản ứng nào — vuốt đóng" + close button visible.
  10. `space_context_bottom_sheet` empty — button "Tạo Space mới" → `space_create_sheet`.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty — 4 required states` ("Empty state must have a Vietnamese CTA"); `auth.md` Pattern #10
- test: widget test cross-module `test/features/{feed,chat,diary,profile,reaction,space}/presentation/` — override provider returning empty list; assert `find.widgetWithText(AppPrimaryButton, '<label>')` per empty state.
- deps: none

### ISSUE STATE-UX-ERROR-001

- sev: P1
- blocker: no
- area: 4-required-states — error branch missing retry button (12 error sites / 11 files)
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart`
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart`
  - `apps/mobile/lib/features/feed/presentation/grid_view_screen.dart`
  - `apps/mobile/lib/features/chat/presentation/inbox_screen.dart`
  - `apps/mobile/lib/features/streak/presentation/streak_screen.dart`
  - `apps/mobile/lib/features/settings/presentation/blocked_accounts_page.dart`
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart`
  - `apps/mobile/lib/features/diary/presentation/diary_list_screen.dart`
  - `apps/mobile/lib/features/space/presentation/space_edit_sheet.dart`
  - `apps/mobile/lib/features/space/presentation/space_management_sheet.dart`
- loc: feed_section.dart:44-55; home_screen.dart:387-395; grid_view_screen.dart:59-72; inbox_screen.dart:44-46; streak_screen.dart:206-224 `_ErrorBanner`; blocked_accounts_page.dart:84-103 `_ErrorState`; friend_profile_screen.dart:50-53 gate + 290-294 post-grid; profile_screen.dart:210-217; diary_list_screen.dart:280-285; space_edit_sheet.dart:141-144 `_ErrorView` chỉ Close; space_management_sheet.dart:67-68 `_ErrorBody`
- symbols: FeedSection.build / `_buildPageView` isError / grid_view error `Center+Text` / inbox `conversationsAsync.when` error / `_ErrorBanner` streak / `_ErrorState` blocked / `_GateMessage` friend_profile (gate + post-grid) / profile post-grid / diary `Center+Padding+Text` / `_ErrorView` space_edit / `_ErrorBody` space_management
- evidence:
  - feed_section.dart:48-53 — `Text('Không tải được feed. Kiểm tra kết nối.')` no button
  - home_screen.dart:388-393 — same string, same shape
  - grid_view_screen.dart:67-72 — `'Không tải được ảnh'` text only sau debugPrint
  - inbox_screen.dart:44-46 — `_InboxMessage(text: 'Không tải được tin nhắn. Thử lại sau nhé.')` no button
  - streak_screen.dart:213-222 — red banner pure text persist không dismiss
  - blocked_accounts_page.dart:95-99 — `'Không thể tải danh sách. Kiểm tra kết nối và thử lại.'` no retry
  - friend_profile_screen.dart:50-53 — `_GateMessage(message: 'Không tải được hồ sơ bạn bè.', onBack: pop)` chỉ "Quay lại"
  - friend_profile_screen.dart:290-294 — post-grid error `Center(child: Text('Không tải được ảnh.'))` no retry
  - profile_screen.dart:210-217 — own post-grid `Center(child: Padding(child: Text(...)))` no retry
  - diary_list_screen.dart:280-285 — `Center(child: Padding(child: Text(...)))` no retry
  - space_edit_sheet.dart:141-144 — `_ErrorView(message: 'Lỗi tải Space', onClose: pop)` chỉ "Đóng" button (line 444-448)
  - space_management_sheet.dart:67 + 291-303 — `_ErrorBody → Text('Không tải được Space. Thử lại sau.')` không retry
- user_impact: 12 error sites khi Firestore stream throw user nhìn thấy lỗi nhưng KHÔNG retry → app stuck dead screen → user phải force-quit + relaunch. Riverpod 2 pattern `ref.invalidate(provider)` là cách standard re-subscribe; "Thử lại" button phải call invalidate.
- risk: silent failure rộng — `apps/mobile/CLAUDE.md §Loading/error/empty` "Error view có retry button" bị break 12 sites cross-module. Combined DATA-ARCH-001 (raw FirebaseException) + USER-SEC-001 (rule tighten) → toàn bộ feed/profile/space error UX không recover được.
- fix:
  1. Tạo `lib/shared/widgets/app_error_view.dart` — `AppErrorView({required String message, required VoidCallback onRetry, String retryLabel = 'Thử lại'})`. Touch core/shared cần leader gate.
  2. Replace text-only error branch ở 9 screens bằng `AppErrorView` với `() => ref.invalidate(xxxProvider)` — feed_section:44 → feedControllerProvider; home_screen:388 → feedControllerProvider; grid_view_screen:67 → spaceFeedProvider; inbox_screen:44 → conversationsProvider; blocked_accounts_page:38 → blockedUsersProvider; profile_screen:210 → ownPostsProvider; friend_profile_screen:290 → friendPostsProvider; diary_list_screen:280 → diaryListProvider.
  3. Streak `_ErrorBanner` (line 206-224) keep red bar + thêm inline retry IconButton bên phải (dismissable).
  4. friend_profile_screen `_GateMessage` (line 76-81) thêm optional `onRetry` + `retryLabel` để phân biệt "Quay lại" (gate) vs "Thử lại" (error).
  5. `space_edit_sheet._ErrorView` (line 423-451) thêm optional `onRetry`; sheet error (line 141) pass `onRetry: () => ref.invalidate(spaceProvider(spaceId))`. Permission-denied (line 153-157) giữ chỉ "Đóng".
  6. `space_management_sheet._ErrorBody` (line 291-303) wrap thành `AppErrorView` với invalidate.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty — 4 required states` + `auth.md` Pattern #2
- test: widget test override `xxxProvider` returning `AsyncError(...)`; assert `find.widgetWithText(AppPrimaryButton, 'Thử lại')` + tap triggers `ref.invalidate`. Cross-module: `flutter test test/features/{feed,chat,streak,settings,profile,diary,space}/presentation/`.
- deps: STATE-UX-EMPTY-001 (same files in feed/chat/diary/profile/space, fix bundle together)

### ISSUE NOTIF-UX-PERM-001

- sev: P1
- blocker: no
- area: Notification UX — FCM permission denial silent
- files:
  - `apps/mobile/lib/features/notification/application/notification_controller.dart`
  - `apps/mobile/lib/main.dart` (FCM init entry point)
  - missing UI consumer file
- loc: `notification_controller.dart:67-78` (permission request + state set); grep `fcmPermissionDenied` consumer search returned 0 hits outside controller + state
- symbols:
  - `NotificationController.initFcm` setting `state.copyWith(fcmPermissionDenied: true)`
  - `NotificationState.fcmPermissionDenied` (no UI consumer)
- evidence:
  ```dart
  // notification_controller.dart:73-77
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    state = state.copyWith(fcmPermissionDenied: true);
    _fcmInitialized = false;
    return;
  }
  ```
  Plus `grep -rn "fcmPermissionDenied" apps/mobile/lib --include='*.dart' | grep -v notification_controller | grep -v notification_state` returns 0 hits — no widget watches the field.
- user_impact: User mới Android 13+ install Meep, tap "Don't allow" trên POST_NOTIFICATIONS dialog → `fcmPermissionDenied=true` set silently. Sau đó, user không bao giờ nhận push notification (friend request, reaction, message) nhưng KHÔNG biết tại sao — không có in-app banner "Bật notification để không bỏ lỡ", không có CTA mở Android Settings. Friend gửi 1 reaction, user mở app không thấy push, mở Notification list rỗng → tưởng app hỏng.
- risk: retention drop trên Android 13+ devices (post-Tiramisu permission becomes runtime ask) — Tier 0 feature "Push notification" effectively dead cho user denial cohort. Per `CLAUDE.md §MVP Scope Tier 0 — Push notification` core required, this is a major UX gap. Combined với PERM-001 (SEC P3 — POST_NOTIFICATIONS chưa declare manifest), Android 13+ runtime ask sẽ là first-time install rất phổ biến để denial.
- fix:
  1. Trong screen có taskbar (home_screen / inbox / profile / diary / streak) thêm in-app banner watch `ref.watch(notificationControllerProvider.select((s) => s.fcmPermissionDenied))` — khi true render dismissable banner trên top body: `'Bật thông báo để không bỏ lỡ ảnh từ bạn bè'` + button "Mở Cài đặt" → `permission_handler.openAppSettings()`. Cần leader gate vì cross-screen wiring + thêm dependency.
  2. Alternatively, lazy-trigger 2nd permission ask khi user thực sự cần (vd lần đầu accept friend request) thay vì ask cold-start — đặt re-prompt logic trong `NotificationController.maybeRequestPermissionAgain()`.
  3. Khi user grant permission từ Settings rồi quay lại app → `WidgetsBindingObserver.didChangeAppLifecycleState` (resumed) trigger re-check `messaging.getNotificationSettings()` → reset `fcmPermissionDenied=false` + initFcm() again.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty` (denial cũng là 1 state); `CLAUDE.md §MVP Scope Tier 0` (push notification required); `auth.md` Pattern #10 (Vietnamese boundary message)
- test: widget test `test/features/notification/presentation/permission_banner_test.dart` (create if missing) — override `notificationControllerProvider` state với `fcmPermissionDenied=true`; assert banner visible + button onTap callable. Manual repro: deny POST_NOTIFICATIONS → expect banner trên home_screen.
- deps: PERM-001 (SEC P3 — manifest declaration) — banner fix có giá trị độc lập, nhưng full coverage cần manifest fix trước (else Android 13+ runtime ask không trigger)

### ISSUE CHAT-UX-SEND-001

- sev: P1
- blocker: no
- area: Chat send fail silent
- files:
  - `apps/mobile/lib/features/chat/presentation/chat_screen.dart`
  - `apps/mobile/lib/features/chat/presentation/group_chat_screen.dart`
  - `apps/mobile/lib/features/chat/application/chat_controller.dart`
  - `apps/mobile/lib/features/chat/presentation/widgets/chat_input_bar.dart`
- loc: chat_controller.dart:49-55 (sets errorMessage); chat_screen.dart:42 + 98-101 (only reads isSending); chat_input_bar.dart:55-59 (`_submit` clears text immediately); chat_input_bar.dart:100 (emoji-picker tap calls `onSend` same pattern); chat_input_bar.dart:158 (quick-emoji tap calls `onSend` same pattern)
- symbols:
  - `ChatController.sendMessage` (sets `errorMessage`)
  - `ChatScreen.build` (reads `sendStatus.isSending` only)
  - `ChatInputBar._submit` (calls `_controller.clear()` before knowing if send succeeded)
- evidence:
  - chat_controller.dart:55 — `state = ChatSendStatus(isSending: false, errorMessage: AppError.fromUnknown(e).message);`
  - chat_screen.dart:42 — `final sendStatus = ref.watch(chatControllerProvider);`
  - chat_screen.dart:97-102 — `ChatInputBar(isSending: sendStatus.isSending, onSend: (text) => ref.read(chatControllerProvider.notifier).sendMessage(...))` — **`sendStatus.errorMessage` never read**
  - chat_input_bar.dart:55-59 — `void _submit() { if (!_canSend) return; widget.onSend(_controller.text.trim()); _controller.clear(); }` — clear() runs synchronously after onSend
  - `grep -rn 'sendStatus\.errorMessage' apps/mobile/lib --include='*.dart'` returns 0 hits
- user_impact: User type "Hôm nay đi đâu?" + tap send → input clears immediately → send fails (network blip / permission-denied per CHAT-SEC-001 rule fix tighten / unavailable) → user sees: nothing. Message gone, no indication, no retry. User retypes thinking thumb misfired → 2nd send also fails. Locket-parity expectation is failed message shows red "!" badge tappable to retry.
- risk: silent data loss (message text never sent, never persisted) — `apps/mobile/CLAUDE.md §Loading/error/empty` rule + `auth.md` Pattern #4 (`_afterFailure` UI feedback) violated. User trust drop especially over flaky carriers. Pair với CHAT-SEC-001 fix (rule tighten /conversations create) — after that fix, sending DM to non-friend will throw permission-denied → critical we surface this error.
- fix:
  1. Trong `chat_screen.dart:97-102` watch `sendStatus.errorMessage` qua `ref.listen` post-frame → `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sendStatus.errorMessage!), action: SnackBarAction(label: 'Thử lại', onPressed: () => ref.read(chatControllerProvider.notifier).sendMessage(conversationId: ..., text: lastFailedText))))`. Save `lastFailedText` trong `_ChatScreenState` local field.
  2. Modify `ChatInputBar._submit` (chat_input_bar.dart:55) — KHÔNG clear input ngay; await onSend completion qua callback `Future<bool> Function(String)` returning success. Clear only on success.
  3. Same fix cho `group_chat_screen.dart:40` (cùng pattern).
  4. Optionally introduce `MessageStatus.sending|sent|failed` enum trên Message model; failed messages render với red "!" inline trong ChatThreadView (Messenger pattern); tap "!" → retry via `chatController.resend(messageId)`.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty` (error needs actionable hint); `auth.md` Pattern #4 (`_afterFailure` UI feedback); `CLAUDE.md §MVP Scope Tier 1 — Chat 1-1` (within scope)
- test: widget test `test/features/chat/presentation/chat_screen_test.dart` override `chatControllerProvider` returning state với errorMessage non-null; assert SnackBar finder visible + "Thử lại" action triggers resend. Run `flutter test test/features/chat/presentation/`.
- deps: CHAT-SEC-001 (SEC P1 — after rule tighten, send to non-friend will fail → this UX path activates)

### ISSUE NAV-UX-POPSCOPE-001

- sev: P1
- blocker: no
- area: Navigation — unsaved-changes warn bypassed by system back
- files:
  - `apps/mobile/lib/features/diary/presentation/diary_canvas_screen.dart`
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart`
  - entire codebase (zero PopScope / WillPopScope hits)
- loc: `diary_canvas_screen.dart:396-411` (`_handleBack` via tap only, wired at line 551); `capture_preview_screen.dart` (no back guard); `edit_profile_screen.dart` (no back guard)
- symbols:
  - `_DiaryCanvasScreenState._handleBack` — only fires when AppBackButton tapped
  - `_CapturePreviewScreenState` — NO back handler at all (no `_handleBack`, no AppBackButton; tap back AND gesture back both lose draft silently)
  - `_EditProfileScreenState` — no back interception
- evidence:
  - `rg "PopScope|WillPopScope|onWillPop" apps/mobile/lib` returns **0 hits codebase-wide**
  - `rg "PopScope|WillPopScope|_handleBack|AppBackButton" apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart` returns **0 hits** — NO back handler whatsoever
  - `rg "isDirty|PopScope" apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` returns 0; only `Navigator.of(context).pop()` at line 130
- user_impact: User mở diary create → gõ 200 từ → swipe edge-back accidentally → diary canvas pop without `DiscardChangesDialog.show` → 200 từ gone. User compose post: snap photo + chọn audience "select 5 friends" + type caption → swipe edge-back → all 3 inputs gone (post controller doesn't persist). Android gesture nav (default since Android 10) makes edge-swipe very easy to trigger.
- risk: user data loss khi accidental gesture — Locket-parity DOES surface caption-recovery on accidental back. `apps/mobile/CLAUDE.md §MVP Scope Tier 0 — Camera + Share photo` golden path includes "compose" stage; losing draft from gesture is a known onboarding friction. Diary `apps/mobile/CLAUDE.md §MVP Scope Tier 0+ — Diary basic` requires basic auto-save semantics; missing PopScope is a regression from that.
- fix:
  1. Wrap `diary_canvas_screen.dart` body trong `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) async { if (didPop) return; await _handleBack(); })` (Flutter 3.22+ API, Android-only MVP per ADR-0002 — không có iOS swipe-back conflict).
  2. Same wrapper cho `capture_preview_screen.dart` — show `DiscardChangesDialog` khi `postState.pendingImagePath != null` AND caption/audience modified.
  3. Same cho `edit_profile_screen.dart` khi `state.isDirty` (cần thêm field `isDirty` vào ProfileState, set true on first onChanged).
  4. Add unit test cho từng case — `flutter_test` PopScope semantics testable via `await tester.tap(find.byType(BackButton))` vs `tester.tap(SystemNavigator.pop)`.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (table format covers similar discipline); inline self-comment `diary_canvas_screen.dart:396 "Back handler — create mode + có nội dung → DiscardChangesDialog"` (intent documented but enforcement incomplete); ADR-0002 (Android-only) → PopScope works cleanly without iOS edge-swipe edge cases
- test: widget test `test/features/diary/presentation/diary_canvas_screen_test.dart` — pump screen, fill TextField, simulate system back via `tester.binding.dispatchPlatformMessage('flutter/platform', ...)` or `await tester.dispatchPlatformBackEvent()`; assert DiscardChangesDialog visible. Run `flutter test test/features/diary/presentation/ test/features/feed/presentation/ test/features/profile/presentation/`.
- deps: none

### ISSUE UPLOAD-UX-001

- sev: P1
- blocker: no
- area: Camera/Post — upload fail UX missing retry
- files:
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart`
  - `apps/mobile/lib/features/feed/application/post_controller.dart`
- loc: `capture_preview_screen.dart:225-234` (error render); `post_controller.dart:161-168, 238-245` (errorMessage set); `post_controller.dart:251-270` (`_errorMessage` mapping)
- symbols:
  - `_CapturePreviewScreenState.build` (renders errorMessage as red text)
  - `PostController.submit` (sets errorMessage but doesn't preserve compressed bytes)
- evidence:
  - capture_preview_screen.dart:225-234 — `if (postState.errorMessage != null) Padding(child: Text(postState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center))` — text only, no button
  - post_controller.dart:163-168 — `state = state.copyWith(isUploading: false, errorMessage: _errorMessage('upload', e))` — keeps pendingImagePath but no `retry()` method exposed
  - post_controller.dart:251-270 — `_errorMessage` returns Vietnamese strings like "Mất kết nối — thử lại" / "Quá tải — chờ một lát rồi thử lại" — wording implies retry but UI has no retry button
- user_impact: User chụp ảnh đẹp → caption → audience → tap Send → upload fail (network drop) → red text "Mất kết nối — thử lại" → user only path forward is back out + re-snap photo + re-caption + re-audience-pick → wasted effort. The compressed bytes ARE still in state (pendingImagePath unchanged) — could retry without re-uploading.
- risk: user perceived data loss + friction; `CLAUDE.md §MVP Scope Tier 0 — Share photo` golden path break trên flaky network. `auth.md` Pattern #10 require Vietnamese error message tại boundary; message HAS Vietnamese but UI affordance to act on it is missing.
- fix:
  1. Trong `capture_preview_screen.dart:225-234` wrap error Text + thêm `AppPrimaryButton(label: 'Thử lại', isLoading: postState.isUploading, onPressed: () => ref.read(postControllerProvider.notifier).submit())` adjacent — submit() đã idempotent (state.copyWith reset errorMessage).
  2. Alternatively introduce dedicated `_ErrorBanner({String message, VoidCallback onRetry})` inline widget — cleaner than ad-hoc Padding.
  3. Khi `_errorMessage` returns "Phiên đăng nhập hết hạn — đăng nhập lại" (unauthenticated code), retry button should disable + show "Đăng nhập lại" CTA navigate `/intro` thay vì retry.
- authority: `apps/mobile/CLAUDE.md §Loading/error/empty` + `CLAUDE.md §MVP Scope Tier 0 — Share photo` (golden path)
- test: widget test `test/features/feed/presentation/capture_preview_screen_test.dart` override `postControllerProvider` state với errorMessage non-null; assert finder "Thử lại" button visible + tap → submit() called again. Run `flutter test test/features/feed/presentation/`.
- deps: LAYER-002 (ARCH P0) + DATA-ARCH-001 (ARCH P1) — after fix, `_errorMessage` switch moves to repository boundary; UI just renders `AppError.message` + retry

### ISSUE THEME-001

- sev: P2
- blocker: no
- area: Design tokens — hardcoded `const _cXxx = Color(0xFF...)` outside theme (acknowledged drift, 7 files / 23 declarations)
- files:
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` (2 consts)
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart` (5 consts)
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart` (4 consts)
  - `apps/mobile/lib/features/profile/presentation/avatar_picker_sheet.dart` (3 consts, comment `// AppColors.error800` admits token exists)
  - `apps/mobile/lib/features/profile/presentation/widgets/profile_tab_bar.dart` (1 const, TODO marker)
  - `apps/mobile/lib/shared/widgets/share_profile_sheet.dart` (4 consts, **shared/widgets touch**)
  - `apps/mobile/lib/shared/widgets/share_photo_sheet.dart` (2 consts, **shared/widgets touch**)
- loc: edit_profile_screen.dart:26-27; friend_profile_screen.dart:17-21; profile_screen.dart:22-25; avatar_picker_sheet.dart:13-14 + 115; profile_tab_bar.dart:5; share_profile_sheet.dart:7-10; share_photo_sheet.dart:13-14
- symbols: `_cBackBtn`, `_cBg`, `_cButtonFill`, `_cButtonText`, `_cAvatarRing`, `_cInactiveIcon`, `_cSectionLabel`, `_cSheetBg`, `_cRemove`, `_cSubtext`, `_cLogoBox`, `_cLogomark` — 4 hex duplicated giữa profile_screen + friend_profile (`#050F10`, `#363636`, `#DDDDDD`, `#D9D9D9`); `#949494` duplicated giữa friend_profile + profile_tab_bar
- evidence: `rg "const _c[A-Z]\w+\s*=\s*Color\("` returns 23 hits across 7 files; `grep "Missing design tokens"` returns 3 explicit headers (edit_profile/friend_profile/profile_screen); `avatar_picker_sheet.dart:14` inline `// AppColors.error800` (dev biết token tồn tại nhưng vẫn duplicate); `profile_tab_bar.dart:5` `// TODO: add AppColors.tabIconInactive`. Critical: **share_profile_sheet + share_photo_sheet ở shared/widgets/** → cross-module shared code shipping với 6 hardcoded consts.
- user_impact: 23 const _cXxx across 7 files với explicit acknowledgement. Shared `share_*_sheet` được dùng cross-module nên drift propagate. Comments "ping leader" + inline TODO là tech debt team đã acknowledge nhưng chưa resolve.
- risk: dark mode (Tier 1) blocked cho 23 colors. Visual drift cao khi 1 file update mà file kia không. shared/widgets là leader-gated area per `apps/mobile/CLAUDE.md §Solo-dev module scope`.
- fix: leader add ~10 tokens vào `AppColors`: `profileBg` (#050F10 = bw900?), `actionButtonFill` (#363636), `actionButtonText` (#DDDDDD), `avatarRingIdle` (#D9D9D9), `inactiveIcon` (#949494), `backButtonFill` (#73706E), `sectionLabel` (#DDDDDD), `sheetBgPrimary` (#2B2B2B), `sheetBgSecondary` (#252627), `shareSheetButtonFill` (#394041), `shareLogomark` (#004B54), `shareSubtext` (#BABABA). Replace 23 const declarations cross 7 files; route avatar_picker `_cRemove` về `AppColors.error800` (đã tồn tại). Delete 3 "Missing design tokens" comment headers + 2 inline TODO comments.
- authority: `apps/mobile/CLAUDE.md §Design tokens — NO hardcoding` + `§Solo-dev module scope` (shared/widgets leader-gated)
- test: `rg "Missing design tokens" apps/mobile/lib` returns 0 post-fix; `rg "const _c[A-Z]\w+\s*=\s*Color\(" apps/mobile/lib` returns 0; visual diff Figma vs build per screen.
- deps: none

### ISSUE THEME-002

- sev: P2
- blocker: no
- area: Design tokens — hardcoded `Color(0x...)` outside core/theme/ (broad: features/ + **shared/widgets/**)
- files: 28 feature files + 7 shared/widgets files (top offenders + shared):
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (3 hits)
  - `apps/mobile/lib/features/streak/presentation/widgets/streak_stats_pill.dart` (3)
  - `apps/mobile/lib/features/streak/presentation/widgets/streak_calendar.dart` (3)
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart` (4)
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart` (5)
  - `apps/mobile/lib/features/profile/presentation/edit_profile_screen.dart` (4)
  - `apps/mobile/lib/features/auth/presentation/widgets/intro_beam.dart` (3)
  - `apps/mobile/lib/features/profile/presentation/avatar_picker_sheet.dart` (3)
  - `apps/mobile/lib/features/space/presentation/widgets/icon_builder_step.dart` (3)
  - `apps/mobile/lib/features/space/presentation/widgets/friend_select_step.dart` (5)
  - `apps/mobile/lib/features/space/presentation/space_edit_sheet.dart` (4)
  - `apps/mobile/lib/features/space/presentation/widgets/space_config_step.dart` (6)
  - `apps/mobile/lib/features/streak/presentation/streak_screen.dart` (3, not in original top list)
  - **`apps/mobile/lib/shared/widgets/share_photo_sheet.dart` (7, shared/widgets)**
  - **`apps/mobile/lib/shared/widgets/share_profile_sheet.dart` (5, shared/widgets)**
  - **`apps/mobile/lib/shared/widgets/share_modal.dart` (3, shared/widgets)**
  - **`apps/mobile/lib/shared/widgets/app_glass_surface.dart` (2, shared/widgets)**
  - **`apps/mobile/lib/shared/widgets/app_text_input.dart` (2 `Color(0x80FFFFFF)` password toggle)**
  - **`apps/mobile/lib/shared/widgets/app_note_pill.dart` (1, shared/widgets)**
  - **`apps/mobile/lib/shared/widgets/photo_detail_screen.dart` (1, shared/widgets)**
  - + 16 more feature files with 1-2 hits each
- loc: file-level — see grep `Color\(0x` in apps/mobile/lib/features
- symbols: per-call-site inline `Color(0xAARRGGBB)` literals
- evidence: features/ subtree 66 hits / 28 files; shared/widgets/ subtree ~22 hits / 9 files (BUG: original audit chỉ scan features/, miss shared/widgets/). Total ~88 hits cross-module.
- user_impact: visual drift risk — if Figma updates barrier opacity from 45% to 50%, manual edit of 28+ sites. Dark mode (Tier 1) blocked. New dev copies a sheet from one module to another and pulls hardcoded literal forward.
- risk: maintainability — `apps/mobile/CLAUDE.md §Design tokens` explicit rule; 66 violations is unhealthy baseline. Tier 1 dark mode silently impossible without sweep.
- fix: leader-driven token sweep — extract recurring literals (`0x73000000` modal barrier, `0x66394041` capture caption pill, `0x80FFFFFF` 50% white hint, etc.) into `AppColors` (e.g. `AppColors.scrim45`, `AppColors.glass40`, `AppColors.bw100Translucent50`). Replace 1 module at a time per ADR-0004 strict gate (touching `core/theme/`). Track via `rg "Color\(0x" apps/mobile/lib/features` count regression checker in CI (advisory).
- authority: `apps/mobile/CLAUDE.md §Design tokens — NO hardcoding` (explicit rule)
- test: regression — `rg "Color\(0x" apps/mobile/lib/features | wc -l` should decrease per sweep PR. Manual visual diff Figma vs build per sheet.
- deps: THEME-001 (similar issue, smaller scope)

### ISSUE THEME-003

- sev: P2
- blocker: no
- area: Design tokens — hardcoded `TextStyle(fontSize:` outside core/theme/
- files: 14 feature files (top hits):
  - `apps/mobile/lib/features/space/presentation/widgets/icon_builder_step.dart` (2)
  - `apps/mobile/lib/features/space/presentation/space_edit_sheet.dart` (2)
  - `apps/mobile/lib/features/home/presentation/home_page.dart` (1)
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart` (1)
  - `apps/mobile/lib/features/feed/presentation/caption_preset_modal.dart` (1)
  - `apps/mobile/lib/features/feed/presentation/feed_filter_dropdown.dart` (1)
  - `apps/mobile/lib/features/feed/presentation/capture_preview_screen.dart` (1)
  - `apps/mobile/lib/features/reaction/presentation/emoji_picker_sheet.dart` (1)
  - `apps/mobile/lib/features/reaction/presentation/reaction_list_sheet.dart` (1)
  - `apps/mobile/lib/features/chat/presentation/widgets/chat_input_bar.dart` (1)
  - `apps/mobile/lib/features/space/presentation/widgets/space_list_tile.dart` (1)
  - `apps/mobile/lib/features/space/presentation/widgets/space_context_badge.dart` (1)
  - `apps/mobile/lib/features/space/presentation/widgets/space_config_step.dart` (1)
  - `apps/mobile/lib/features/settings/presentation/widgets/space_quick_row.dart` (1)
- loc: file-level
- symbols: inline `TextStyle(fontSize: X, fontWeight: ..., fontFamily: 'Nunito')`
- evidence: `grep "TextStyle\(fontSize" apps/mobile/lib/features` returns 16 total occurrences across 14 files. Sample: `feed_section.dart:135-139` uses `TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Nunito')` — duplicated style instead of `AppTextStyles.xlBold` or similar token. Spot-confirmed `caption_preset_modal.dart` + `chat_input_bar.dart` also use inline fontSize.
- user_impact: font ladder drift — when leader updates a token (e.g., `mdBold` from 16px to 17px), 14 files won't reflect change. Accessibility text-scale won't apply uniformly if textTheme not used.
- risk: visual inconsistency; lower severity than THEME-002 because hits are fewer + impact narrower.
- fix: extract each `TextStyle(fontSize:)` into the closest `AppTextStyles.<token>` (xlBold/mdBold/baseBold/smSemiBold per existing palette). Where Figma defines a fontSize not in `AppTextStyles`, leader adds token first. Replace inline TextStyle with `AppTextStyles.<token>.copyWith(color: ...)`.
- authority: `apps/mobile/CLAUDE.md §Design tokens — NO hardcoding` ("Hardcoded font `TextStyle(fontSize: 16)` → use Theme.of(context).textTheme.bodyMedium")
- test: regression `rg "TextStyle\(fontSize" apps/mobile/lib/features | wc -l` should decrease per sweep.
- deps: THEME-002 (sweep together)

### ISSUE UX-REFRESH-001

- sev: P2
- blocker: no
- area: Pull-to-refresh — absent across all list screens
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart` (SliverList)
  - `apps/mobile/lib/features/feed/presentation/home_screen.dart` (PageView)
  - `apps/mobile/lib/features/chat/presentation/inbox_screen.dart` (ListView)
  - `apps/mobile/lib/features/diary/presentation/diary_list_screen.dart` (entries ListView)
  - `apps/mobile/lib/features/profile/presentation/profile_screen.dart`
  - `apps/mobile/lib/features/profile/presentation/friend_profile_screen.dart`
- loc: file-level — none of these wrap content trong `RefreshIndicator`
- symbols: no `RefreshIndicator` widget anywhere in lib
- evidence: `grep -rn 'RefreshIndicator\|onRefresh\|pull.*to.*refresh' apps/mobile/lib --include='*.dart'` returns 1 hit — that hit is a **comment** trong `diary_controller.dart:80` ("nhiều lần (vd pull-to-refresh)") không phải widget. **Zero `RefreshIndicator` widgets**.
- user_impact: User Android familiar với pull-to-refresh affordance trên list screens. Khi Firestore stream giật (snapshot listener mất sync), user theo bản năng vuốt xuống → không có refresh handler → tưởng app frozen. Hiện tại không có affordance manual refresh — phải close + reopen app hoặc force-quit.
- risk: minor — Firestore listeners đáng tin cậy 99%+ cho real-time, nhưng edge cases (long background, network reconnect, App Check transient fail) do happen. Locket-parity: Locket có pull-to-refresh trên feed.
- fix:
  1. Wrap feed `SliverList` in `CustomScrollView` với `RefreshIndicator` (`SliverFillRemaining` + `RefreshIndicator` outside, hoặc `CupertinoSliverRefreshControl` cho Material+Cupertino mix). `onRefresh: () async { ref.invalidate(feedControllerProvider); await Future.delayed(Duration(milliseconds: 500)); }` (delay tránh visual jitter khi cache hit instant).
  2. Wrap inbox `ListView.builder` (inbox_screen.dart:129) trong `RefreshIndicator(onRefresh: () async { ref.invalidate(conversationsProvider); })`.
  3. Diary entries ListView (diary_list_screen.dart) tương tự.
  4. Profile post grid + friend_profile post grid tương tự.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` (table covers similar discipline); Material guideline RefreshIndicator
- test: widget test `test/features/feed/presentation/feed_section_test.dart` — `tester.fling(...)` from top edge, assert `refreshing` indicator visible + `feedControllerProvider` invalidated. Run `flutter test test/features/feed/presentation/ test/features/chat/presentation/ test/features/diary/presentation/`.
- deps: STATE-UX-ERROR-001 (refresh + retry button can share the "invalidate provider" handler)

### ISSUE A11Y-FRIEND-001

- sev: P2
- blocker: no
- area: Accessibility — touch target < 48x48 logical px on friend decline + small icons
- files:
  - `apps/mobile/lib/features/friend/presentation/friend_sheet.dart`
- loc: 698-710 (decline X icon); 619-628 (unfriend X icon, same anti-pattern)
- symbols:
  - friend request decline `IconButton` inside `SizedBox(width: 20, height: 20)` (line 698-710)
  - **friend list unfriend `IconButton` inside `SizedBox(width: 20, height: 20)` (line 619-628, has tooltip 'Gỡ kết bạn' nhưng hit target vẫn 20×20)**
- evidence:
  ```dart
  // friend_sheet.dart:698-710
  SizedBox(
    width: 20,
    height: 20,
    child: IconButton(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(Icons.close, color: AppColors.bw100),
      onPressed: () => ref
          .read(friendControllerProvider(currentUid).notifier)
          .declineFriendRequest(request.requestId),
    ),
  ),
  ```
  Parent `SizedBox` enforces 20×20 → default IconButton 48×48 splash collapsed → effective hit area 20×20.
- user_impact: User finger taps screen at decline icon, miss by ~14dp easily → either declines wrong row (next request item underneath) hoặc misses tap entirely. Decline is destructive (rejects friend request) — accidental tap on accept button (above 40dp) is worse.
- risk: a11y violation per `apps/mobile/CLAUDE.md §Accessibility — minimum required` ("Touch target ≥ 48x48 logical pixels"); not in scope filter (Android-only doesn't exempt this). Pair với destructive action without confirm (UX-DECLINE-CONFIRM-001 below).
- fix: remove outer `SizedBox(width: 20, height: 20)` ở BOTH sites (decline + unfriend) → IconButton default 48×48 splash + center 20px icon.
- authority: `apps/mobile/CLAUDE.md §Accessibility — minimum required` ("Touch target ≥ 48x48 logical pixels")
- test: widget test `test/features/friend/presentation/friend_sheet_test.dart` — pump FriendSheet with pending request; assert `tester.getSize(find.byIcon(Icons.close))` returns Size where height ≥ 48 dp AND width ≥ 48 dp. Run `flutter test test/features/friend/presentation/`.
- deps: UX-DECLINE-CONFIRM-001 (same row, related fix)

### ISSUE A11Y-INPUT-001

- sev: P2
- blocker: no
- area: Accessibility — IconButton thiếu Semantics label / tooltip
- files:
  - `apps/mobile/lib/shared/widgets/app_text_input.dart`
  - other locations with IconButton bare icon
- loc: `app_text_input.dart:170-178` (password show/hide IconButton)
- symbols:
  - `_AppTextInputState._suffix` password visibility toggle
- evidence:
  ```dart
  // app_text_input.dart:170-178
  if (_isPassword) {
    return IconButton(
      icon: Icon(
        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0x80FFFFFF),
        size: 20,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
  }
  ```
  No `tooltip` parameter, no `Semantics(label:)` wrapper. Same widget rendered in 6+ auth pages.
- user_impact: TalkBack reads "Button" only (or worse — empty Semantics tree). User using screen reader can't tell whether toggle reveals or hides password. Same gap on many other GestureDetector-only icon buttons across feature/chat/profile.
- risk: a11y violation per `apps/mobile/CLAUDE.md §Accessibility` ("Every `IconButton`, `GestureDetector`, custom tap area: `Semantics(label: '...')` or `tooltip`"); password toggle is one of the most-touched interactions in the auth flow.
- fix:
  1. `app_text_input.dart:170-178` — add `tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu'` to the IconButton. TalkBack picks tooltip as Semantics label.
  2. Sweep other IconButton + GestureDetector bare-icon sites: feed back button (in `app_back_button.dart` — already has Semantics OK), reaction_list_sheet emoji tappable, settings_quick_actions icon rows, etc.
- authority: `apps/mobile/CLAUDE.md §Accessibility` ("Every `IconButton`, ..., custom tap area: `Semantics(label: '...')` or `tooltip`")
- test: widget test `test/shared/widgets/app_text_input_test.dart` (file exists per inventory) — assert `find.bySemanticsLabel('Hiện mật khẩu')` resolves when `_obscure=true`. Run `flutter test test/shared/widgets/`.
- deps: none

### ISSUE UX-CAPTION-LEN-001

- sev: P2
- blocker: no
- area: Caption length cap UX — limit invisible to user
- files:
  - `apps/mobile/lib/shared/widgets/app_note_pill.dart`
- loc: 107-126 (TextField + maxLength + buildCounter)
- symbols:
  - `_AppNotePillState._buildTextField`
- evidence:
  ```dart
  // app_note_pill.dart:117-124
  maxLength: AppNotePill.maxLength,  // = 30
  buildCounter: (
    _, {
    required currentLength,
    required isFocused,
    maxLength,
  }) =>
      null,  // suppress Material counter
  ```
  Cap enforced (Flutter blocks character 31+) but Material counter widget suppressed → user has NO visual indication. CLAUDE.md domain entry: "App enforces ≤ 30 chars (single-line overlay pill)" — enforcement present, visibility absent.
- user_impact: User types caption "Hôm nay đi cafe với bạn ABC" (27 chars) → reach 30 silently → can't type more → confused thinking keyboard broken. Bigger frustration when user types fast on Vietnamese telex/IME — composed character may insert 2-3 chars at once, hitting cap mid-syllable.
- risk: UX confusion mid-Tier 0 golden path (post submission). Wording in CLAUDE.md "App enforces ≤ 30 chars" is the contract; meeting it silently without affordance ignores user comprehension.
- fix:
  1. Replace `buildCounter: ... → null` với `buildCounter: (_, {required currentLength, required isFocused, maxLength}) => isFocused ? Text('$currentLength/$maxLength', style: AppTextStyles.xsSemiBold.copyWith(color: AppColors.bw500)) : null`. Counter ẩn khi không focus → không xáo trộn read-only render trên feed.
  2. Alternatively, render counter as a small pill bên cạnh AppNotePill overlay khi focus state — Figma reference needed.
- authority: `CLAUDE.md §Domain — Caption` ("App enforces ≤ 30 chars (single-line overlay pill)") — enforcement visible to user
- test: widget test `test/shared/widgets/app_note_pill_test.dart` — pump editable AppNotePill, type 25 chars, assert `find.text('25/30')` exists when TextField focused. Run `flutter test test/shared/widgets/`.
- deps: none

### ISSUE UX-HAPTIC-001

- sev: P2
- blocker: no
- area: Haptic feedback — absent on core interactions
- files: codebase-wide (1 hit total)
- loc: `apps/mobile/lib/features/auth/presentation/intro_page.dart:219` (only existing HapticFeedback call — swipe)
- symbols: `HapticFeedback.lightImpact`
- evidence: `grep -rn "HapticFeedback" apps/mobile/lib --include='*.dart'` returns **1 hit total** in intro_page.dart only. Missing from:
  - Camera capture button (`camera_section.dart` capture tap)
  - Post submit success (`capture_preview_screen.dart` send confirmation)
  - Reaction emoji tap (`emoji_picker_sheet.dart`)
  - Friend accept/unfriend confirm (`friend_sheet.dart`)
  - Pull-to-refresh trigger (when added per UX-REFRESH-001)
  - Logout / delete account confirm
- user_impact: tactile feedback expected on Locket/Snapchat-style apps for "moment captured" — Meep's positioning as "intimate share" misses this affordance. Camera capture especially: shutter button without HapticFeedback feels less responsive than native camera app.
- risk: polish — not a functional break but degrades "intimate, tactile" brand. Low severity but high coverage gap.
- fix: sprinkle `HapticFeedback.lightImpact()` / `mediumImpact()` / `selectionClick()` per Android pattern:
  - `camera_section.dart` `_onCapture()` — `HapticFeedback.mediumImpact()` at start of capture.
  - `capture_preview_screen.dart` `_send()` — `HapticFeedback.lightImpact()` on tap (before submit awaits).
  - `emoji_picker_sheet.dart` emoji tap — `HapticFeedback.selectionClick()`.
  - `friend_sheet.dart` accept/decline buttons — `HapticFeedback.lightImpact()`.
  - Reaction add (when emoji selected from picker) — `HapticFeedback.lightImpact()`.
- authority: Android Material guideline (HapticFeedback for primary touch confirmation); Locket-parity Tier 0
- test: widget test sample — `tester.tap(find.byKey(Key('capture_button')))` then verify `HapticFeedback.invokes` increments (use `mockHapticFeedback` via `SystemChannels.platform.setMockMethodCallHandler`).
- deps: none

### ISSUE UX-DECLINE-CONFIRM-001

- sev: P2
- blocker: no
- area: Destructive action — instant accept/decline/cancel without confirm
- files:
  - `apps/mobile/lib/features/friend/presentation/friend_sheet.dart`
- loc: 680-695 (accept instant); 698-710 (decline X instant); 742-749 (cancel sent instant); 506-526 (search result "Đã gửi" cancel instant)
- symbols:
  - friend request accept GestureDetector — instant call
  - decline X IconButton — instant call
  - cancelSentRequestsTo — instant call
- evidence:
  - friend_sheet.dart:681-683 — `onTap: () => ref.read(friendControllerProvider(currentUid).notifier).acceptFriendRequest(request.requestId)` — no confirmation
  - friend_sheet.dart:705-707 — `onPressed: () => ref.read(friendControllerProvider(currentUid).notifier).declineFriendRequest(request.requestId)` — no confirmation
  - friend_sheet.dart:743-745 — `cancelSentRequestsTo` instant
  - friend_sheet.dart:508-510 — same instant pattern in search result row
  Compare with `_confirmUnfriend` (friend_sheet.dart:639-652) — unfriend HAS confirm dialog. Inconsistent.
- user_impact: User reviewing friend requests in FriendSheet, accidental tap X → request declined silently → no undo → friend wonders why no acceptance arrived (Meep cap 20 friends, declined invites get stuck). Same for accidental "Đã gửi" cancel.
- risk: lower than block-user/unfriend but still data-loss-ish (declined request can't be re-accepted by recipient — they have to ask sender to re-send). User confusion + need to coordinate offline.
- fix:
  - Decline: wrap onPressed in `showAppConfirmDialog(context, title: 'Từ chối lời mời từ ${displayName}?', body: 'Bạn vẫn có thể gửi lời mời lại sau.', cancelLabel: 'Huỷ', confirmLabel: 'Từ chối')` then decline.
  - Cancel sent request: `showAppConfirmDialog(context, title: 'Hủy lời mời đã gửi?', cancelLabel: 'Giữ lời mời', confirmLabel: 'Hủy lời mời')`.
  - Accept: keep instant (positive, easy to undo via Unfriend if mistake).
- authority: `apps/mobile/CLAUDE.md §Destructive actions` (checklist item per audit prompt v2 — "Friend request received: accept/decline destructive style?")
- test: widget test `test/features/friend/presentation/friend_sheet_test.dart` — pump with pending request; tap decline icon; assert `showAppConfirmDialog` finder visible. Run `flutter test test/features/friend/`.
- deps: A11Y-FRIEND-001 (same row, bundle fix)

### ISSUE FORM-001

- sev: P2
- blocker: no
- area: Form validation — no inline validation (AutovalidateMode absent)
- files: codebase-wide
- loc: signup_password_page.dart:55 (uses `_hasBlurred` manual flag); login_email_page.dart, signup_email_page.dart, signup_name_page.dart, signup_username_page.dart, reset_password_page.dart (similar manual `_canContinue` getters)
- symbols: any Form / TextFormField with validator + AutovalidateMode
- evidence: `grep -rn "AutovalidateMode" apps/mobile/lib --include='*.dart'` returns **0 hits**. Auth pages use bare `TextField` + manual `_canContinue` boolean computed via `AuthValidators.isPasswordValid(_pwCtrl.text)` (signup_password_page.dart:45) + button.onPressed = `_canContinue ? _onContinue : null`. Error message shown only AFTER user taps Continue OR _hasBlurred fires (signup_password_page.dart:47-48).
- user_impact: User types email "abc@" + blurs → no inline error → taps Continue → THEN sees error. Locket / Snapchat / Instagram all use AutovalidateMode.onUserInteraction so error shows progressively. Meep's current flow: type → tap continue → wait → see error → fix → tap continue → wait. Extra round-trip vs inline.
- risk: lower priority — current pattern works, just slower onboarding feedback loop. Not a break.
- fix:
  1. Convert TextField → TextFormField wrapped in Form widget in each auth page (signup/login).
  2. Set `autovalidateMode: AutovalidateMode.onUserInteraction` on Form.
  3. Move `AuthValidators.isEmail*/isPassword*` into `validator: (v) => AuthValidators.isEmailValid(v) ? null : 'Email không hợp lệ'`.
  4. Replace manual `_canContinue` getters with `formKey.currentState?.validate() ?? false`.
- authority: `apps/mobile/CLAUDE.md §Common gotchas` + `auth.md` Pattern #7 (clear-on-keystroke pattern already there — inline-validate is the natural extension)
- test: widget test `test/features/auth/presentation/signup_email_page_test.dart` — type "abc@" + blur; assert finder "Email không hợp lệ" visible WITHOUT tapping Continue. Run `flutter test test/features/auth/presentation/`.
- deps: none

### ISSUE UX-CAMERA-ERR-NOREASON

- sev: P2
- blocker: no
- area: Camera error message — raw English `e.toString()` in state
- files:
  - `apps/mobile/lib/features/feed/application/app_camera_controller.dart`
- loc: 42-44 (catch all + raw toString)
- symbols:
  - `AppCameraController.initialize` catch block
- evidence:
  ```dart
  // app_camera_controller.dart:42-44
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
  ```
  Plus `_initializeCamera` (line 67-87) also rethrows raw CameraException → catch in initialize traps + stores `e.toString()`. Output to state.error: English plugin text like `"CameraException(CameraAccessDenied, The user did not grant permission to use the camera.)"`.
- user_impact: At present, the error is rendered only as an icon (CAMERA-UX-001), so the user doesn't see this English string. But if CAMERA-UX-001 fix renders `state.error` as Text, it would leak English to Vietnamese users. Need to map CameraException → Vietnamese AppError boundary message.
- risk: dependency of CAMERA-UX-001 fix; needs to be fixed at same time or English text will leak when error UI is improved.
- fix: in `app_camera_controller.dart:42-44` map `CameraException` codes:
  ```dart
  } on CameraException catch (e) {
    final permState = switch (e.code) {
      'CameraAccessDenied' || 'CameraAccessRestricted' || 'cameraPermission' =>
        CameraPermissionState.denied,
      _ => CameraPermissionState.unknown,
    };
    final msg = switch (e.code) {
      'CameraAccessDenied' => 'Meep cần quyền truy cập máy ảnh',
      'CameraAccessRestricted' => 'Quyền máy ảnh bị giới hạn — kiểm tra Cài đặt',
      _ => 'Không thể khởi động máy ảnh',
    };
    state = state.copyWith(permissionState: permState, error: msg);
  } catch (e) {
    state = state.copyWith(error: 'Không thể khởi động máy ảnh');
  }
  ```
  Add `CameraPermissionState` enum + Freezed regen.
- authority: `auth.md` Pattern #10 (Vietnamese error message tại boundary); `auth.md` Pattern #2 (typed error mapping at data boundary — applies to platform plugin too)
- test: unit test `test/features/feed/application/app_camera_controller_test.dart` (create) override camera plugin với mock throwing `CameraException('CameraAccessDenied', ...)`; assert state.error == 'Meep cần quyền truy cập máy ảnh' + permissionState == denied. Run `flutter test test/features/feed/application/`.
- deps: CAMERA-UX-001 (consumer)

### ISSUE UX-INBOX-EMPTY-ACTION

- sev: P3
- blocker: no
- area: Inbox empty + error messaging combined into one widget
- files:
  - `apps/mobile/lib/features/chat/presentation/inbox_screen.dart`
- loc: 44-52 (both error and empty use `_InboxMessage` shared widget)
- symbols:
  - `_InboxMessage` (lines 167-182)
- evidence: `_InboxMessage` is a plain Center+Text — same widget used for "Không tải được tin nhắn" (error) AND "Chưa có tin nhắn nào" (empty). Combining states into 1 widget makes adding state-specific affordances (retry button for error, "Mở feed" CTA for empty) require expanding the widget API.
- user_impact: refactor friction — addressing STATE-UX-EMPTY-001 + STATE-UX-ERROR-001 cleanly requires splitting `_InboxMessage` into `_InboxEmpty` + reuse shared `AppErrorView`.
- risk: minor — only when the higher-priority fixes land.
- fix: when implementing STATE-UX-EMPTY-001 / STATE-UX-ERROR-001, split `_InboxMessage` into 2 widgets or extend with `actionLabel + onAction` params.
- authority: `apps/mobile/CLAUDE.md §File organization` ("Files ≤ 300 lines. Split if larger." — current 183 lines so OK; cite as a principle of state-specific extraction)
- test: covered by STATE-UX-EMPTY-001 + STATE-UX-ERROR-001 tests.
- deps: STATE-UX-EMPTY-001, STATE-UX-ERROR-001

### ISSUE UX-DATE-001

- sev: P3
- blocker: no
- area: Date formatting — hand-rolled VN format omitting year
- files:
  - `apps/mobile/lib/features/feed/presentation/feed_section.dart`
- loc: 114 (`_formatDate`)
- symbols:
  - `PostHeaderRow._formatDate`
- evidence:
  ```dart
  // feed_section.dart:114
  static String _formatDate(DateTime dt) => '${dt.day} thg ${dt.month}';
  ```
  Hand-rolled "d thg M" — no year. Used by every post header (line 119).
- user_impact: Posts older than 1 year render same as today's (both "5 thg 6"). Minor UX issue — Locket-parity intentionally drops year for current-year posts but shows year for older ones. Meep currently has 0 differentiation.
- risk: minor — feed is usually recent, but with growing user history, "5 thg 6 2025" vs "5 thg 6 2026" disambiguation matters.
- fix: replace with `intl.DateFormat`:
  ```dart
  static final _sameYearFmt = DateFormat('d MMM', 'vi');
  static final _diffYearFmt = DateFormat('d MMM yyyy', 'vi');
  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final fmt = dt.year == now.year ? _sameYearFmt : _diffYearFmt;
    return fmt.format(dt);
  }
  ```
  `intl` already a transitive dependency via `flutter_localizations`; no new package needed. Same pattern used in `notification_banner.dart:99` (`DateFormat('dd/MM').format(dt)`) so precedent exists.
- authority: `notification_banner.dart:99` precedent; `apps/mobile/CLAUDE.md §Common gotchas` (avoid `toString()` user-facing date)
- test: widget test `test/features/feed/presentation/feed_section_test.dart` — pump PostHeaderRow with createdAt = DateTime(2025, 6, 5); assert text contains "2025"; with createdAt = DateTime.now(); assert text excludes year. Run `flutter test test/features/feed/presentation/`.
- deps: none

### ISSUE UX-WIDGET-PIN-001

- sev: P3
- blocker: no
- area: Home-screen widget — no in-app pin guide
- files:
  - `apps/mobile/lib/features/widget/application/widget_data_service.dart`
  - missing: in-app onboarding screen for widget pin
- loc: codebase-wide search
- symbols: missing — no UI flow guides user to pin Android home-screen widget
- evidence: Glob `apps/mobile/lib/features/widget/presentation/**` returns no presentation widgets in widget feature folder (Flutter side has only `application/widget_data_service.dart` plus data layer). No "Add Meep widget to home screen" CTA anywhere in app. `home_widget` package supports programmatic pin request on Android 8.0+ via `home_widget` API but no caller in lib.
- user_impact: Headline differentiator (per `CLAUDE.md §Project Context "Headline differentiator: home-screen widget"`) silently un-onboardable. User installs app, uses it, never knows to long-press home screen + Widgets > Meep. Locket onboarding flow has dedicated "Pin your widget" step post-signup.
- risk: differentiator under-utilization. Tier 0 widget feature ships but adoption low without in-app guide.
- fix:
  1. Add post-signup onboarding step (e.g., between signup-name and home) → "Add Meep to home screen" → screenshot/animation + button "Thêm widget" → `HomeWidget.requestPinWidget(...)` (Android 8+ only).
  2. Alternatively, add Settings section "Widget" với hint "Long-press home screen → Widgets → Meep" + button trigger pin request.
  3. Track first-time-pinned state in `notification_preferences` (or new `widget_preferences`) to not re-prompt.
- authority: `CLAUDE.md §Project Context — Headline differentiator: home-screen widget`; ADR-0002 (Android-first) → safe to use Android-specific API; `home_widget` package docs
- test: integration test on emulator API 26+ — trigger `HomeWidget.requestPinWidget()` then verify intent fires. Manual test on physical device → ensure widget gets added to home screen.
- deps: none

## fix_order

### batch_1_p0

1. **CAMERA-UX-001** — camera permission denial UX: render Vietnamese error + "Mở Cài đặt" CTA + retry. Pair với UX-CAMERA-ERR-NOREASON (P2) trong cùng PR vì cùng controller change.

### batch_2_p1

2. **STATE-UX-EMPTY-001** — add Vietnamese CTA button to **12 empty sites across 10 files** (feed + inbox + chat-thread + diary + profile + friend-profile + 2 shared profile widgets + grid_view + reaction-list + space-context). Includes shared/widgets touch — leader gate.
3. **STATE-UX-ERROR-001** — extract `AppErrorView` shared widget; add retry button to **12 error sites across 11 files** (feed × 3 + chat + streak + blocked-accounts + profile × 2 + diary + space × 2 + friend-profile gate). Pair với UX-REFRESH-001 (cùng shared "invalidate" handler).
4. **NOTIF-UX-PERM-001** — surface `fcmPermissionDenied` state qua in-app banner across taskbar screens. Pair với PERM-001 (SEC) manifest declaration.
5. **CHAT-UX-SEND-001** — listen `sendStatus.errorMessage`, surface SnackBar với "Thử lại" action. Keep text in input until success.
6. **NAV-UX-POPSCOPE-001** — wrap diary canvas + capture preview + edit profile trong `PopScope` to gate system back.
7. **UPLOAD-UX-001** — add retry button next to upload error text in capture preview.

### batch_3_p2

8. **THEME-001** — leader add ~10 tokens (profileBg/actionButtonFill/actionButtonText/avatarRingIdle/inactiveIcon/backButtonFill/sectionLabel/sheetBg×2/shareLogomark/shareSubtext); replace **23 const _cXxx declarations across 7 files** (4 profile screens + avatar_picker + profile_tab_bar + 2 shared/widgets share_*_sheet). shared/widgets touch — leader gate.
9. **THEME-002** — sweep 66 `Color(0x...)` literals across 28 feature files into AppColors tokens (multi-PR per module).
10. **THEME-003** — sweep 16 `TextStyle(fontSize:)` into AppTextStyles tokens.
11. **UX-REFRESH-001** — RefreshIndicator wrapper on feed/inbox/diary/profile lists.
12. **A11Y-FRIEND-001** — remove SizedBox(20,20) wrapper on decline IconButton; restore 48×48 touch target.
13. **A11Y-INPUT-001** — add tooltip + Semantics to AppTextInput password toggle + sweep other IconButtons.
14. **UX-CAPTION-LEN-001** — replace `buildCounter: → null` with visible counter widget when focused.
15. **UX-HAPTIC-001** — sprinkle HapticFeedback on camera capture / post send / reaction / friend accept.
16. **UX-DECLINE-CONFIRM-001** — add confirm dialog to decline / cancel-sent friend actions.
17. **FORM-001** — migrate auth forms to TextFormField + AutovalidateMode.onUserInteraction.
18. **UX-CAMERA-ERR-NOREASON** — map CameraException → Vietnamese AppError (bundled with CAMERA-UX-001 in batch_1).

### batch_4_p3

19. **UX-INBOX-EMPTY-ACTION** — split `_InboxMessage` into empty / error variants when STATE-UX fixes land.
20. **UX-DATE-001** — replace `_formatDate` hand-roll with `DateFormat('d MMM', 'vi')` + year conditional.
21. **UX-WIDGET-PIN-001** — add in-app pin-widget guide post-signup or in Settings.

## test_plan_after_fix

- `CAMERA-UX-001`: `flutter test test/features/feed/presentation/camera_section_test.dart` — override `appCameraControllerProvider` with `permissionState: denied`; assert `find.text('Mở Cài đặt')` + button onPressed wired. Manual: deny camera permission in Android Settings → relaunch → expect Vietnamese fallback screen với CTA.
- `STATE-UX-EMPTY-001`: cross-module `flutter test test/features/{feed,chat,diary,profile,reaction,space}/presentation/` — override provider returning empty list per screen; assert `find.widgetWithText(AppPrimaryButton, '<label>')` visible per 12 empty sites.
- `STATE-UX-ERROR-001`: cross-module `flutter test test/features/{feed,chat,streak,settings,profile,diary,space}/presentation/` — override provider returning `AsyncError(...)`; assert `find.widgetWithText(AppPrimaryButton, 'Thử lại')` + tap triggers `ref.invalidate` per 12 error sites.
- `NOTIF-UX-PERM-001`: `flutter test test/features/notification/presentation/permission_banner_test.dart` — `fcmPermissionDenied=true` → assert banner visible across home/inbox/profile/diary/streak screens.
- `CHAT-UX-SEND-001`: `flutter test test/features/chat/presentation/chat_screen_test.dart` — sendStatus với errorMessage non-null → assert SnackBar visible + tap "Thử lại" → resend invoked.
- `NAV-UX-POPSCOPE-001`: `flutter test test/features/diary/presentation/diary_canvas_screen_test.dart test/features/feed/presentation/capture_preview_screen_test.dart` — pump screen + fill input → simulate Android system back → assert DiscardChangesDialog finder.
- `UPLOAD-UX-001`: `flutter test test/features/feed/presentation/capture_preview_screen_test.dart` — postState với errorMessage non-null → assert "Thử lại" button visible + onPressed triggers submit().
- `THEME-001`: `rg "Missing design tokens" apps/mobile/lib` returns 0 hits; `rg "const _c[A-Z]\w+\s*=\s*Color\(" apps/mobile/lib` returns 0 hits (was 23 across 7 files); visual diff Figma vs build per 7 screens.
- `THEME-002`: `rg "Color\(0x" apps/mobile/lib/features | wc -l` decreases from 66 per sweep PR.
- `THEME-003`: `rg "TextStyle\(fontSize" apps/mobile/lib/features | wc -l` decreases from 16 per sweep PR.
- `UX-REFRESH-001`: widget test `tester.fling(...)` from top of feed → assert RefreshIndicator visible + `feedControllerProvider` invalidated.
- `A11Y-FRIEND-001`: widget test pump FriendSheet with pending request → assert `tester.getSize(find.byIcon(Icons.close))` height ≥ 48 + width ≥ 48.
- `A11Y-INPUT-001`: widget test `test/shared/widgets/app_text_input_test.dart` — assert `find.bySemanticsLabel('Hiện mật khẩu')` resolves.
- `UX-CAPTION-LEN-001`: widget test `test/shared/widgets/app_note_pill_test.dart` — type 25 chars + focus → assert `find.text('25/30')` exists.
- `UX-HAPTIC-001`: widget test `tester.tap(find.byKey(Key('capture_button')))` → mock platform channel handler verifies `HapticFeedback.invoke` called.
- `UX-DECLINE-CONFIRM-001`: widget test `test/features/friend/presentation/friend_sheet_test.dart` — tap decline → `showAppConfirmDialog` finder visible.
- `FORM-001`: widget test `test/features/auth/presentation/signup_email_page_test.dart` — type "abc@" + blur → assert "Email không hợp lệ" visible before tapping Continue.
- `UX-CAMERA-ERR-NOREASON`: unit test `test/features/feed/application/app_camera_controller_test.dart` — mock `availableCameras()` throwing `CameraException('CameraAccessDenied', ...)` → assert state.error == 'Meep cần quyền truy cập máy ảnh' + permissionState == denied.
- `UX-INBOX-EMPTY-ACTION`: covered by STATE-UX tests.
- `UX-DATE-001`: widget test `test/features/feed/presentation/feed_section_test.dart` — createdAt year != current → assert text contains year.
- `UX-WIDGET-PIN-001`: integration test on emulator API 26+ — `HomeWidget.requestPinWidget()` invoked → verify pin dialog intent.

## no_issue_notes

Compact notes for areas verified clean OR covered by ARCH / SEC audits.

### Areas covered by Phase A — DO NOT re-flag
- Feed widget calls `FirebaseAuth.instance.currentUser?.uid` directly in build (`feed_section.dart:80`, `home_screen.dart:589`) — **covered by ARCH-LAYER-001 (P0)**. UX side acknowledges this gates widget-test feasibility for STATE-UX-EMPTY-001 / STATE-UX-ERROR-001 fixes (per A_PHASE_BASELINE_SUMMARY Theme 1).
- Feed controller direct FirebaseAuth + Firestore `_db.collection('posts').doc().id` — **covered by ARCH-LAYER-002 (P0)**. UX UPLOAD-UX-001 fix depends on LAYER-002 fix landing first.
- `feed_state.dart DocumentSnapshot? lastDoc` exposed to UI — **covered by ARCH-LAYER-003 (P1)**.
- 5 repositories throwing raw FirebaseException without AppError mapping — **covered by ARCH-DATA-ARCH-001 (P1)**. UX STATE-UX-ERROR-001 fix benefits from this (Vietnamese AppError.message renderable directly).
- `/invite/:uid` route → HomePage placeholder + meep:// vs https://meep.app scheme drift — **covered by ARCH-DEEPLINK-001 (P1)**.
- `home_page.dart` skeleton "Home — TODO" rendered for /invite/:uid — **covered by ARCH-HOME-ARCH-001 (P2)**.
- AndroidManifest missing POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED — **covered by SEC-PERM-001 (P3)**. NOTIF-UX-PERM-001 depends on this for full coverage but standalone UX banner has value independently.
- App Check not activated → API quota abuse — **covered by SEC-APPCHECK-001 (P0)**. UX impact: when CI deploy enforces App Check and client missing, all Firestore reads will fail → STATE-UX-ERROR-001 retry button becomes critical surface.
- `/users/{uid}` read by any authed → email PII leak — **covered by SEC-USER-SEC-001 (P0)**. UX side: friend profile screen + friend search results currently can show full profile to non-friends; after SEC rollout this tightens → UX must not assume full profile readable (already conditional via `friend_sheet.dart isFriend` branch — OK).
- Camera plugin manifest entry merged at build time (no explicit CAMERA permission in AndroidManifest) — **covered by SEC no_issue (Android permissions section)**. UX CAMERA-UX-001 fix may need leader to add explicit declaration for clarity.
- Widget native side (Kotlin: MeepWidget.kt, WidgetSyncWorker.kt, WidgetDataStore.kt) UX scope — **out of 03_ux_flutter scope (Kotlin native)**; Flutter-side widget data service covered.

### Areas checked clean (no issue found, no cross-audit dependency)
- `app_primary_button.dart`: disable-when-loading pattern present (line 22 `_enabled = onPressed != null && !isLoading`) — duplicate-submit protection OK. Loading spinner inline OK.
- `app_confirm_dialog.dart`: shared widget exists; used by `_confirmUnfriend` (friend_sheet.dart:639-652) + `DeleteAccountDialog.show` (delete_account_dialog.dart:29-35) + `LogoutConfirmDialog.show` (logout_confirm_dialog.dart:5-12) — destructive confirm pattern reusable + consistent.
- `delete_account_dialog.dart`: 2-step confirmation (intent → reauth dialog) implemented per Figma 572:4605; barrierDismissible=false on step 2; Google + password provider branches handled; OperationCancelledError silent dismiss per Pattern #4 — OK.
- `logout_confirm_dialog.dart`: simple confirm dialog with Vietnamese "Đăng xuất" / "Huỷ" — OK (deletion has more weight, logout less so).
- Auth pages clear-on-keystroke discipline (Pattern #7): login_password_page.dart:153-161, signup_email_page.dart:106-118 — `onChanged → clearError + setState(() {})` pattern present in all auth pages spot-checked.
- AppTextInput password toggle exists (line 169-178). Status enum (normal/active/error/success) + AnimatedContainer border transition — visual state pattern OK.
- `app_back_button.dart` + Semantics — back button has Semantics label in some sheets (Figma-verified per shared/widgets/ inventory). Note: not deep-read but no smell from spot check.
- Sign-in success animation (`_LoginSuccessButton` in login_password_page.dart:289-325) — has Semantics-friendly text "Bạn đã sẵn sàng" + delay before router redirect (1500ms backup timer line 67-69). OK.
- Reset password flow: ForgotPasswordDialog → sendResetEmail → _EmailSentPill confirmation + _ResendText 60s cooldown (line 96-107). UX correct for "check email" guidance.
- Email enumeration protection workaround (mentioned in auth.md Caveats) — out of UX audit scope, listed for awareness.
- Capture preview save-to-gallery: success state visual (Icons.check + AppColors.turquoise500 per `_Header` line 282-284). SnackBar "Không thể lưu ảnh" on Gal exception (line 94-97). Has 4-state-like coverage.
- ChatThreadView auto-scroll on keyboard open via `didChangeMetrics` (line 64-66) — `apps/mobile/CLAUDE.md §Async / streams` says no `Future.delayed` to "wait for state" — auto-scroll via `addPostFrameCallback` after metric change is the correct pattern.
- ChatInputBar: shows quickEmojis when blurred, switches to send button when focused — Locket-parity Figma 564:6935 matched.
- DeleteAccount cascade: dialog pops sheet before CF runs (settings_sheet.dart:170 + unawaited line 171); router auth listener handles redirect after CF completes — defer + redirect pattern correct.
- `mark_as_read_listener.dart`: side-effect listener (no render) — debounced markAsRead per inventory map.
- `notification_banner.dart`: separate foreground banner via FlutterLocalNotifications — handled by notification_controller (line 130-184). 4-sec auto-dismiss timer.
- Capture preview AnimatedSwitcher caption swipe + AppDotsIndicator (capture_preview_screen.dart:156-209) — multi-step / preset indicator pattern OK.
- DiaryCanvasScreen `_handleBack` discard dialog (line 396-411) — discipline correct for AppBackButton tap path; gap is just system-back gesture (NAV-UX-POPSCOPE-001).
- `app_note_pill.dart` readOnly mode caps text with `maxLines: 1 + ellipsis` (line 91-97) — graceful fallback even if Firestore caption > 30 chars (e.g., legacy posts).
- Friend search `_buildSearchResultBody` (friend_sheet.dart:378-435) — distinct states: empty query / loading / no result / found / friendsInitialized=false shimmer. 4-state-equivalent coverage — OK.
- `_confirmUnfriend` (friend_sheet.dart:639-652) — destructive style with "Lưu" / "Xoá" — confirm dialog present. OK.
- Settings sheet logout flow has confirmation (logout_confirm_dialog.dart) and dialog pops sheet first (line 153) before logout fires.
- Notification banner foreground tap → openBannerAsTap → router listen → consume — flow per PR #287 fix, no UX gap.
- `core/router/app_router.dart authRedirect` 5-state machine — pure function tested per Pattern #6; UX redirect loop check covered by ARCH-ROUTER-001 (P3 — debug bypass) + auth.md Pattern #6.
- Profile screen edit-profile error surfacing via SnackBar (edit_profile_screen.dart:117-118) — OK pattern (post-frame trigger to avoid setState in build).
- `_StyledButton` and `_ConfirmDialogButton` in delete_account_dialog.dart:230-269 — `Semantics(button: true, label: label, excludeSemantics: true)` correctly used. Spot precedent for A11Y fix sweep.
- `space/presentation/widgets/friend_select_step.dart` exists with full multi-step UX (4 hardcoded Color hits noted in THEME-002 batch) — not flagged separately as space module deep-read partial.
- HomeScreen `_HomeTopBar` "N bạn bè" pill is tappable → FriendSheet (line 432-441). This IS the implicit "Thêm bạn" affordance — already accessible from camera tab but not surfaced from feed empty state (STATE-UX-EMPTY-001).
- Tier 2 scope items (group_chat_screen.dart exists for Space group chat, listed "Won't have" per CLAUDE.md Tier 2 — also flagged by ARCH no_issue) — out of UX scope, not flagged. Per scope_filter "out-of-scope — KHÔNG report là gap".
- iOS-specific UX paths absent (no `Cupertino*` imports in feature widgets except CupertinoSliverRefreshControl candidate for UX-REFRESH-001) — correct per ADR-0002 Android-first.
- Rollcall module folder absent — covered by ARCH-ARCH-003 (P3 — leader decision to scaffold or descope).
- Pass-2 reverify uncovered evidence undercount cho 7 issues (STATE-UX-EMPTY-001 5→12 sites, STATE-UX-ERROR-001 6→12 sites, THEME-001 3→7 files, THEME-002 add shared/widgets scope, A11Y-FRIEND-001 add unfriend X, CHAT-UX-SEND-001 add emoji paths, NAV-UX-POPSCOPE-001 clarify capture_preview no back handler) — issue count vẫn 21 (no new IDs), scope expanded.
- 5 partial coverage areas re-classified per pass-2 evidence:
  - profile flow: was partial → now has THEME-001 (7 files) + STATE-UX-ERROR-001 (2 sites: post-grid own + friend) + STATE-UX-EMPTY-001 (4 sites: own post-grid + friend post-grid + shared photo_grid + diary_tab_content) coverage. profile_tab_bar + avatar_picker_sheet specific patterns covered.
  - space flow: was partial (Glob only) → now has STATE-UX-ERROR-001 (2 sites: space_edit_sheet `_ErrorView` chỉ Close, space_management_sheet `_ErrorBody` no retry) + STATE-UX-EMPTY-001 (space_context_bottom_sheet empty) coverage. 11 widgets vẫn không deep-read full multi-step create flow (Tier 0+ defer).
  - reaction UX: was partial → now has STATE-UX-EMPTY-001 (reaction_list_sheet) + UX-HAPTIC-001 (emoji_picker_sheet). Picker widget không deep-read full (Tier 0 stretch).
  - streak UX: was partial → covered by STATE-UX-ERROR-001 (_ErrorBanner) + THEME-002 (streak_screen.dart not in original top list, 3 hits). Tier 1 stretch chính vẫn defer.
  - widget Flutter side: was partial (no presentation/ dir) → UX-WIDGET-PIN-001 (P3) flagged; native Kotlin out of scope. No change.

## postcheck

- git_status_after:
  - `?? tmp/` (pre-existing untracked dir)
  - `?? docs/audits/03_ux_flutter_audit.md` (new file, intended)
- changed_files_after:
  - `docs/audits/03_ux_flutter_audit.md`
- unexpected_modified_files: none

## final_verdict

verdict: not_ready

**Rationale:** 1 P0 (CAMERA-UX-001) breaks Tier 0 "Camera + Share photo" golden path when user denies camera permission — no Vietnamese fallback, no settings CTA, no retry. 6 P1 issues cluster around 4-required-states discipline. **Pass-2 reverify revealed evidence undercount**: STATE-UX-EMPTY-001 expanded 5→12 sites across 10 files, STATE-UX-ERROR-001 expanded 6→12 sites across 11 files — 4-required-states rule violation is broader than pass-1 reported. THEME-001 expanded 3→7 files (added shared/widgets/share_*_sheet + avatar_picker + profile_tab_bar). A11Y-FRIEND-001 also covers unfriend X button (line 619-628). CHAT-UX-SEND-001 also affects emoji-picker + quick-emoji paths in chat_input_bar. After batch_1_p0 + batch_2_p1 (7 issues, expanded scope), the app meets `apps/mobile/CLAUDE.md §Loading/error/empty 4-state contract` and golden path UX.

**Pre-condition for fixes to land cleanly:** ARCH-LAYER-001/-002 (Phase A P0) must be resolved first — feed widget tests cannot run while widgets directly call `FirebaseAuth.instance`, so STATE-UX-EMPTY-001 / STATE-UX-ERROR-001 / UPLOAD-UX-001 widget tests become writable only after LAYER-001/-002 fix.

**Recommended sprint:** Fix batch_1_p0 (1 issue) + batch_2_p1 (6 issues) = 7 must-fix UX in 1 sprint (5-7 ngày dev), bundle UX-CAMERA-ERR-NOREASON (P2) với CAMERA-UX-001 same PR.

Final distribution: **P0=1, P1=6, P2=11, P3=3 — total 21 issues** (count unchanged after pass-2 reverify; 7 issues had evidence scope expanded — STATE-UX-EMPTY-001 (12 sites), STATE-UX-ERROR-001 (12 sites), THEME-001 (7 files), THEME-002 (+ shared/widgets), A11Y-FRIEND-001 (2 sites), CHAT-UX-SEND-001 (3 paths), NAV-UX-POPSCOPE-001 (3 files) — but no new issue IDs added).

## self_verification_log

<!-- 4 passes recorded after first draft per audit prompt v2 §Self-Verification Loop -->

pass_1_checklist: N=22 checklist sub-sections, M=21 issues (count unchanged after pass-2 reverify; 7 issues had evidence scope expanded but no new IDs added), K=27+ no_issue_notes mappings, gap=0 — each checklist sub-section maps to ≥1 issue OR no_issue_note. Pass-2 reverify confirmed coverage of profile/space/reaction sub-sections through expanded STATE-UX + THEME-001 evidence (previously "partial" areas).
- 4-required-states → STATE-UX-EMPTY-001 (12 sites) + STATE-UX-ERROR-001 (12 sites) + UX-INBOX-EMPTY-ACTION + no_issue auth pages clean
- Auth → no_issue (clear-on-keystroke OK, password toggle present, success animation OK); FORM-001 inline validation
- Camera/post → CAMERA-UX-001 (P0) + UX-CAMERA-ERR-NOREASON (P2) + UPLOAD-UX-001 + UX-CAPTION-LEN-001
- Feed → STATE-UX-EMPTY-001 (feed_section/home_screen/grid_view_screen) + STATE-UX-ERROR-001 (3 sites cùng feature) + no_issue pagination footer + UX-DATE-001
- Friend → A11Y-FRIEND-001 (2 sites: decline + unfriend X) + UX-DECLINE-CONFIRM-001 + no_issue unfriend confirm OK
- Notification UX → NOTIF-UX-PERM-001 (P1) + no_issue banner OK + tap-route per PR #287
- Widget (Flutter side) → UX-WIDGET-PIN-001 (P3) + no_issue (Kotlin out of scope)
- Profile → THEME-001 (7 files / 23 consts) + STATE-UX-ERROR-001 (post-grid own + friend) + STATE-UX-EMPTY-001 (4 sites: own + friend + shared photo_grid + diary_tab_content) + no_issue edit error via SnackBar pattern
- Diary → STATE-UX-EMPTY-001 (diary_list) + STATE-UX-ERROR-001 (diary_list error branch) + NAV-UX-POPSCOPE-001 + no_issue DiscardChangesDialog tap-path OK
- Space → STATE-UX-EMPTY-001 (space_context_bottom_sheet) + STATE-UX-ERROR-001 (space_edit `_ErrorView` + space_management `_ErrorBody`) + THEME-002 covers hardcoded colors there
- Reaction → STATE-UX-EMPTY-001 (reaction_list_sheet) + UX-HAPTIC-001 (haptic) + no_issue picker exists
- Streak → THEME-002 (streak_screen.dart 3 hits) + STATE-UX-ERROR-001 (_ErrorBanner) — Tier 1 stretch, no_issue beyond these
- Chat → CHAT-UX-SEND-001 (text + emoji-picker + quick-emoji paths) + STATE-UX-EMPTY-001 (inbox + chat-thread) + STATE-UX-ERROR-001 (inbox) + UX-INBOX-EMPTY-ACTION
- Settings → STATE-UX-ERROR-001 (blocked_accounts_page `_ErrorState`) + no_issue (delete + logout confirm OK, multi-step delete OK)
- Form/input → FORM-001 + UX-CAPTION-LEN-001
- Navigation → NAV-UX-POPSCOPE-001 (3 files: diary + capture-preview no-handler-at-all + edit-profile) + no_issue auth-redirect OK
- Theme/design tokens → THEME-001 (7 files) + THEME-002 (features + shared/widgets) + THEME-003
- A11Y → A11Y-FRIEND-001 (2 sites) + A11Y-INPUT-001
- Destructive actions → UX-DECLINE-CONFIRM-001 + no_issue delete + unfriend confirm OK
- Layout/overflow → no_issue (no specific overflow flagged this round)
- Image handling → no_issue (CachedNetworkImage + placeholder + errorWidget pattern present)
- Date/time → UX-DATE-001 (feed) + no_issue notification_banner uses DateFormat
- Async-after-dispose → no_issue (mounted/context.mounted check + ref.onDispose audit confirmed)
- Lint clean → blocked (flutter analyze not run per audit-only rule)

pass_2_schema: total=21, missing_field_fixed=0; pass-2 reverify (executed 2026-06-08) discovered evidence undercount in 7 issues — scope expanded but issue IDs unchanged. Every issue verified to have all 7 required fields per LAYER C. Severity calibration unchanged from pass 1. evidence_failed_grep=0; re-grep all evidence quotes confirms current claims:
- CAMERA-UX-001 @ `app_camera_controller.dart:43` + `camera_section.dart:511-520 _ViewfinderContent` + `:344-373 _DualViewfinderContent` → confirmed
- STATE-UX-EMPTY-001 @ 12 sites: feed_section.dart:1009, home_screen.dart:608, grid_view_screen.dart:82, inbox_screen.dart:50, chat_thread_view.dart `_EmptyThread`, diary_list_screen.dart:378, profile_screen.dart:226, friend_profile_screen.dart:300, widgets/photo_grid.dart:19, widgets/diary_tab_content.dart:35, reaction_list_sheet.dart:67, space_context_bottom_sheet.dart:107 → confirmed via Grep + Read
- STATE-UX-ERROR-001 @ 12 sites: feed_section.dart:44-55, home_screen.dart:387-395, grid_view_screen.dart:59-72, inbox_screen.dart:44-46, streak_screen.dart:206-224 `_ErrorBanner`, blocked_accounts_page.dart:84-103 `_ErrorState`, friend_profile_screen.dart:50-53 (gate) + 290-294 (post-grid), profile_screen.dart:210-217, diary_list_screen.dart:280-285, space_edit_sheet.dart:141-144 `_ErrorView` (chỉ Close), space_management_sheet.dart:67 + 291-303 `_ErrorBody` → confirmed
- NOTIF-UX-PERM-001 @ `notification_controller.dart:73-77` set + Grep returns 3 hits (state + controller set/reset) + 0 UI consumers → confirmed
- CHAT-UX-SEND-001 @ `chat_controller.dart:55` errorMessage set + `chat_screen.dart:42 + 97-103` only reads isSending + `chat_input_bar.dart:55-59 _submit` clear() + `:100 onSend emoji-picker` + `:158 quick-emoji onSend` cùng pattern + grep `sendStatus.errorMessage` 0 consumers → confirmed
- NAV-UX-POPSCOPE-001 @ rg `PopScope|WillPopScope|onWillPop` 0 hits codebase + diary_canvas_screen.dart:396-411 _handleBack tap-only + capture_preview_screen.dart 0 back handler at all + edit_profile_screen.dart:130 Navigator.pop() no guard → confirmed
- UPLOAD-UX-001 @ `capture_preview_screen.dart:225-234` red text only + `post_controller.dart:163-167` errorMessage set keeps pendingImagePath + `:251-270 _errorMessage` returns VN msg → confirmed
- THEME-001 @ 7 files / 23 consts: edit_profile (2) + friend_profile (5) + profile_screen (4) + avatar_picker_sheet (3) + profile_tab_bar (1) + share_profile_sheet (4, shared/widgets) + share_photo_sheet (2, shared/widgets) → confirmed via `rg "const _c[A-Z]\w+\s*=\s*Color\("` (23 hits)
- THEME-002 @ features/ subtree 66 hits / 28 files + shared/widgets/ subtree ~22 hits / 9 files = ~88 hits cross-module → confirmed via Grep both paths
- THEME-003 @ 16 hits across 14 files → confirmed via Grep features/
- UX-REFRESH-001 @ rg `RefreshIndicator|onRefresh` returns 0 widget hits → confirmed
- A11Y-FRIEND-001 @ `friend_sheet.dart:698-710` SizedBox(20,20) decline + `:619-628` SizedBox(20,20) unfriend (cùng anti-pattern, has tooltip nhưng hit target 20×20) → confirmed
- A11Y-INPUT-001 @ `app_text_input.dart:170-178` no tooltip → confirmed
- UX-CAPTION-LEN-001 @ `app_note_pill.dart:117-124` buildCounter → null → confirmed
- UX-HAPTIC-001 @ grep returns 1 hit (intro_page.dart:219 only) → confirmed
- UX-DECLINE-CONFIRM-001 @ `friend_sheet.dart:680-707, 742-749` instant onTap → confirmed
- FORM-001 @ grep AutovalidateMode 0 hits + `signup_password_page.dart:45-48` manual flag → confirmed
- UX-CAMERA-ERR-NOREASON @ `app_camera_controller.dart:42-44` raw e.toString (no `on CameraException catch`) → confirmed
- UX-INBOX-EMPTY-ACTION @ `inbox_screen.dart:167-182 _InboxMessage` shared widget → confirmed
- UX-DATE-001 @ `feed_section.dart:114 _formatDate` hand-roll → confirmed
- UX-WIDGET-PIN-001 @ Glob `apps/mobile/lib/features/widget/presentation/**` returns no files → confirmed

pass_3_dedupe: before=21, after=21, consolidations=0 — pass-2 reverify confirmed no two issues share files[0]+symbols+root_cause+fix combo (even after evidence scope expansion):
- STATE-UX-EMPTY-001 vs STATE-UX-ERROR-001 share files (feed/inbox/diary/profile/space/grid_view) nhưng distinct symbols (empty vs error branch in `.when`) + distinct fix (add CTA button vs add retry button). Kept separate; cross-deps noted.
- THEME-001 vs THEME-002 sau pass-2 expansion vẫn distinct: THEME-001 chỉ scope `const _cXxx = Color()` declaration pattern (acknowledged drift với comment "Missing design tokens" / TODO); THEME-002 scope inline `Color(0x...)` literals (no const declaration). Files overlap (profile screens trong cả 2) nhưng symbols + root cause khác. Kept separate.
- A11Y-FRIEND-001 vs UX-DECLINE-CONFIRM-001 share friend_sheet.dart decline X location nhưng different fix (touch target size vs confirm dialog) + different root cause (a11y vs destructive UX). Bundle hint in fix_order.
- CAMERA-UX-001 vs UX-CAMERA-ERR-NOREASON share `app_camera_controller.dart` nhưng distinct symbols (UI render branch vs controller error mapping) + distinct severity (P0 vs P2). Bundle hint trong fix_order (same PR).
- CHAT-UX-SEND-001 pass-2 added emoji-picker + quick-emoji paths nhưng cùng file (chat_input_bar.dart) + same root cause (onSend signature returns void) + same fix → kept single issue, didn't split.

pass_4_coverage: checked=13, partial=3, blocked=0, total=16, verdict=mostly_checked — pass-2 reverify promoted 2 previously "partial" areas to "checked" through evidence expansion:
- checked (13): auth flow + feed flow + chat UX + friend flow + diary flow + settings flow + shared widgets API + theme/design tokens + camera/share flow + notification UX + router/deeplink (partial in original, now confirmed via no_issue ARCH cite); **PROMOTED: profile flow (was partial — now THEME-001 7 files + STATE-UX 6 sites cover own/friend/shared profile widgets) + space flow (was partial — now STATE-UX 3 sites cover space-edit/management/context sheets + THEME-002 confirmed)**
- partial (3): widget Flutter side (no presentation/ dir exists — UX-WIDGET-PIN-001 P3 flagged; native Kotlin out of scope); streak UX (Tier 1 stretch, has STATE-UX-ERROR-001 + THEME-002 + UX-HAPTIC-001 coverage but full streak feature flow not deep-read); reaction UX (has STATE-UX-EMPTY-001 + UX-HAPTIC-001 but emoji_picker_sheet full UX not deep-read)
- blocked (0): no hard blockers; flutter analyze still not run per audit constraint
- verdict=mostly_checked: 13/16 areas fully checked (was 11/16); 3 partials documented with rationale matching Tier scope priorities
- no_issue spot-checks (pass-2): verified app_back_button Semantics presence (TODO if found gap), mark_as_read_listener debounce + dispose pattern, RefreshIndicator 0 widgets — see TASK A report.

Coverage truthfulness criterion met: every "checked" area has Glob + Read + Grep evidence in commands table; "partial" entries have explicit rationale (Tier scope or out-of-depth-vs-priority).

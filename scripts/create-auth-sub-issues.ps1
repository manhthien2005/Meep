# scripts/create-auth-sub-issues.ps1
# Tạo 8 sub-issues cho Epic #1 [T0] Auth
# Chạy từ root: .\scripts\create-auth-sub-issues.ps1

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:GH_TOKEN = [System.Environment]::GetEnvironmentVariable("GH_TOKEN", "User")

$repo = "manhthien2005/Meep"
$milestone = 1  # M1 — Foundation + Auth

Write-Host "Tao 8 sub-issues cho Epic #1 Auth..." -ForegroundColor Cyan

# ─────────────────────────────────────────────
# Issue 1: Firebase init + AppRouter
# ─────────────────────────────────────────────
$body1 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 1
> 👤 Assignee: ThienPDM

## Mục tiêu
Wire Firebase vào Flutter app + tạo AppRouter (go_router) với redirect guard tự động chuyển `/intro` ↔ `/home` dựa theo auth state.

## Files cần tạo / sửa
- **Sửa** `apps/mobile/lib/main.dart` — thêm `Firebase.initializeApp`, dùng `MaterialApp.router`
- **Tạo** `apps/mobile/lib/core/router/app_router.dart` — `@riverpod GoRouter appRouter` với redirect
- **Tạo** `apps/mobile/lib/core/router/app_router.g.dart` — generated (build_runner)
- **Tạo** `apps/mobile/lib/features/home/presentation/home_page.dart` — placeholder Scaffold

## Acceptance criteria
- [ ] App khởi động không crash sau khi Firebase.initializeApp
- [ ] User chưa login → redirect về `/intro`
- [ ] User đã login → redirect về `/home`
- [ ] `flutter analyze` clean

## TDD steps (theo plan)
1. Tạo `home_page.dart` placeholder
2. Tạo `app_router.dart` với `@riverpod` + redirect dựa `currentUidProvider`
3. Cập nhật `main.dart` — `Firebase.initializeApp` + override `authRepositoryProvider` + `userRepositoryProvider`
4. `flutter pub run build_runner build --delete-conflicting-outputs`
5. `flutter analyze` → clean

## Definition of Done
- [ ] App compile và chạy trên Android emulator
- [ ] `flutter analyze` — no issues
- [ ] PR merged vào `develop`

## Phụ thuộc
- `firebase_options.dart` đã có (flutterfire configure đã chạy)
- `authRepositoryProvider` ở `auth_controller.dart` (scaffold sẵn)
'@

$out1 = gh issue create `
  --repo $repo `
  --title "[Auth] T1: Firebase init + AppRouter" `
  --body $body1 `
  --assignee "manhthien2005" `


Write-Host "Created: $out1" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 2: UserProfile + FirebaseAuthRepository
# ─────────────────────────────────────────────
$body2 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 2, 3
> 👤 Assignee: KhoaLND

## Mục tiêu
Tạo `UserProfile` model (freezed) và implement `FirebaseAuthRepository` — lớp data layer chuyển `FirebaseAuthException` thành `AppError` tiếng Việt.

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/data/user_profile.dart` — freezed model + `displayName` getter + `TimestampConverter`
- **Tạo** `apps/mobile/lib/features/auth/data/user_profile.freezed.dart` (generated)
- **Tạo** `apps/mobile/lib/features/auth/data/user_profile.g.dart` (generated)
- **Sửa** `apps/mobile/lib/features/auth/data/auth_repository.dart` — thêm `signUpWithEmail`, `sendPasswordResetEmail`
- **Tạo** `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` — impl `AuthRepository`
- **Tạo** `apps/mobile/test/features/auth/data/user_profile_test.dart`
- **Tạo** `apps/mobile/test/features/auth/data/firebase_auth_repository_test.dart`

## Acceptance criteria
- [ ] `UserProfile.displayName` trả `'$firstName $lastName'`
- [ ] `UserProfile` fromJson/toJson round-trip pass
- [ ] `signInWithEmail` wrong password → throw `UnauthenticatedError` với message tiếng Việt
- [ ] `signOut` → `currentUid == null`
- [ ] `flutter test test/features/auth/data/` — ALL PASS

## TDD steps (theo plan)
1. Viết `user_profile_test.dart` → FAIL
2. Implement `user_profile.dart` → run build_runner → PASS
3. Cập nhật `auth_repository.dart` (thêm abstract methods)
4. Viết `firebase_auth_repository_test.dart` → FAIL
5. Implement `firebase_auth_repository.dart` → PASS
6. Commit

## Error mapping (bắt buộc implement)
| Firebase code | Message tiếng Việt |
|---|---|
| `user-not-found` | Không tìm thấy tài khoản với email này. |
| `wrong-password` / `invalid-credential` | Mật khẩu không đúng. Vui lòng thử lại. |
| `email-already-in-use` | Email này đã được sử dụng. |
| `weak-password` | Mật khẩu phải dài tối thiểu 8 ký tự. |

## Definition of Done
- [ ] Tests PASS (`flutter test test/features/auth/data/`)
- [ ] PR merged vào `develop` (reviewer: ThienPDM)

## Phụ thuộc
- Issue #1 (T1) phải done trước
- Packages: `firebase_auth_mocks`, `freezed`, `json_serializable` (đã có pubspec)
'@

$out2 = gh issue create `
  --repo $repo `
  --title "[Auth] T2+3: UserProfile model + FirebaseAuthRepository" `
  --body $body2 `
  --assignee "CatS1mp" `


Write-Host "Created: $out2" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 3: UserRepository + Firestore rules
# ─────────────────────────────────────────────
$body3 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 4, 5
> 👤 Assignee: ThienPDM (rules = security-sensitive)

## Mục tiêu
Implement `FirebaseUserRepository` — tạo profile user bằng Firestore batch write (atomic) + Firestore security rules cho `/users/{uid}` và `/usernames/{username}`.

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/data/user_repository.dart` — abstract interface
- **Tạo** `apps/mobile/lib/features/auth/data/firebase_user_repository.dart` — impl
- **Sửa** `apps/mobile/lib/features/auth/application/auth_controller.dart` — thêm `userRepositoryProvider`
- **Sửa** `apps/mobile/lib/main.dart` — override `userRepositoryProvider`
- **Sửa** `firebase/firestore.rules` — thêm rules users + usernames
- **Tạo** `apps/mobile/test/features/auth/data/firebase_user_repository_test.dart`

## Acceptance criteria
- [ ] `createProfile` → batch write `/users/{uid}` + `/usernames/{username}` trong 1 transaction
- [ ] `isUsernameAvailable('taken')` → false khi doc tồn tại
- [ ] `getProfile('nonexistent')` → null
- [ ] Firestore rule: stranger đọc `/users/{uid}` của người khác → denied
- [ ] `flutter test test/features/auth/data/firebase_user_repository_test.dart` — PASS

## Firestore rules phải implement
```javascript
match /users/{uid} {
  allow read: if isAuthed() && request.auth.uid == uid;
  allow create: if isAuthed() && request.auth.uid == uid
                && request.resource.data.keys().hasAll(['uid','email','firstName','lastName','username','createdAt'])
                && request.resource.data.username.size() >= 3
                && request.resource.data.username.size() <= 20;
  allow update: if isOwner(uid)
                && !request.resource.data.diff(resource.data).affectedKeys()
                      .hasAny(['uid','createdAt','email']);
  allow delete: if false;
}
match /usernames/{username} {
  allow read: if isAuthed();
  allow create: if isAuthed() && request.resource.data.uid == request.auth.uid;
  allow delete: if isAuthed() && resource.data.uid == request.auth.uid;
  allow update: if false;
}
```

## Definition of Done
- [ ] Tests PASS
- [ ] `firebase deploy --only firestore:rules --project meep-staging` — deployed OK
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T2+3 phải done trước (cần `UserProfile` model)
- Packages: `fake_cloud_firestore` (đã có)
'@

$out3 = gh issue create `
  --repo $repo `
  --title "[Auth] T4+5: UserRepository + Firestore rules" `
  --body $body3 `
  --assignee "manhthien2005" `


Write-Host "Created: $out3" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 4: SignUpController
# ─────────────────────────────────────────────
$body4 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 6
> 👤 Assignee: KhoaLND

## Mục tiêu
Implement `SignUpController` — Riverpod controller quản lý state 4-step signup flow, username availability check (debounce 500ms), và `createAccount()` gọi Firebase Auth + Firestore batch write.

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/application/sign_up_state.dart` — `SignUpStep` enum + `SignUpState` (freezed)
- **Tạo** `apps/mobile/lib/features/auth/application/sign_up_state.freezed.dart` (generated)
- **Tạo** `apps/mobile/lib/features/auth/application/sign_up_controller.dart` — `@riverpod class SignUpController`
- **Tạo** `apps/mobile/lib/features/auth/application/sign_up_controller.g.dart` (generated)
- **Tạo** `apps/mobile/test/features/auth/application/sign_up_controller_test.dart`

## SignUpState schema
```dart
enum SignUpStep { email, password, name, username }

@freezed
class SignUpState {
  SignUpStep step           // current step
  String email, password, firstName, lastName, username
  bool isCheckingUsername   // debounce spinner
  bool isUsernameAvailable  // Tuyệt vời! / taken
  bool isLoading            // createAccount() đang chạy
  String? errorMessage      // inline error tiếng Việt
}
```

## Acceptance criteria
- [ ] Initial state: `step = email`, tất cả empty
- [ ] `nextStep()` từ email → password → name → username
- [ ] `checkUsername` debounce 500ms, query `/usernames/{x}`
- [ ] `createAccount()`: gọi `signUpWithEmail` + `createProfile` theo đúng thứ tự
- [ ] `createAccount()` lỗi → `errorMessage` set, `isLoading = false`
- [ ] `flutter test test/features/auth/application/sign_up_controller_test.dart` — PASS

## Google Sign-In path
- `createAccountWithGoogle(uid, email)`: skip `signUpWithEmail`, chỉ gọi `createProfile`

## Definition of Done
- [ ] Tests PASS (dùng `mocktail` mock repo)
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T4+5 phải done (`UserRepository` cần có)
- Issue T2+3 phải done (`FirebaseAuthRepository`)
'@

$out4 = gh issue create `
  --repo $repo `
  --title "[Auth] T6: SignUpController (4-step state machine)" `
  --body $body4 `
  --assignee "CatS1mp" `


Write-Host "Created: $out4" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 5: LoginController + Google Sign-In
# ─────────────────────────────────────────────
$body5 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 7
> 👤 Assignee: KhoaLND

## Mục tiêu
Implement `LoginController` — xử lý email/password login, Google Sign-In (check `/users/{uid}` thay vì `isNewUser`), forgot password. Implement `signInWithGoogle()` trong `FirebaseAuthRepository`.

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/application/login_controller.dart` — `LoginState` (freezed) + `@riverpod class LoginController`
- **Tạo** `apps/mobile/lib/features/auth/application/login_controller.freezed.dart` (generated)
- **Tạo** `apps/mobile/lib/features/auth/application/login_controller.g.dart` (generated)
- **Sửa** `apps/mobile/lib/features/auth/data/auth_repository.dart` — thêm `currentGoogleUser`
- **Sửa** `apps/mobile/lib/features/auth/data/firebase_auth_repository.dart` — implement `signInWithGoogle()`
- **Tạo** `apps/mobile/test/features/auth/application/login_controller_test.dart`

## LoginState schema
```dart
@freezed class LoginState {
  bool isLoading, isSuccess, needsProfile
  String? googleUid, googleEmail  // set khi needsProfile=true
  String? errorMessage
}
```

## Google Sign-In logic (QUAN TRỌNG)
Không dùng `additionalUserInfo.isNewUser` — không reliable.
Thay vào đó: sau `signInWithGoogle()` → query `/users/{uid}`:
- Tồn tại → `isSuccess = true` → navigate `/home`
- Không tồn tại → `needsProfile = true` → UI navigate sang `/signup/name`

## Acceptance criteria
- [ ] `signIn` success → `isSuccess = true`
- [ ] `signIn` wrong password → `errorMessage != null`, `isSuccess = false`
- [ ] `signInWithGoogle` new user → `needsProfile = true`, `googleUid` set
- [ ] `signInWithGoogle` returning user → `isSuccess = true`
- [ ] `sendPasswordReset` gọi `sendPasswordResetEmail` đúng
- [ ] `flutter test test/features/auth/application/login_controller_test.dart` — PASS

## Definition of Done
- [ ] Tests PASS (4 test cases minimum)
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T6 (`SignUpController`) nên done trước (cùng application layer)
- `google_sign_in` package đã có pubspec
'@

$out5 = gh issue create `
  --repo $repo `
  --title "[Auth] T7: LoginController + Google Sign-In" `
  --body $body5 `
  --assignee "CatS1mp" `


Write-Host "Created: $out5" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 6: IntroPage + SignUpEmailPage + SignUpPasswordPage
# ─────────────────────────────────────────────
$body6 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 8, 9
> 👤 Assignee: HanDHG
> 🎨 Figma: Trang giới thiệu + Đăng ký_Nhập email + Đăng ký_Nhập MK

## Mục tiêu
Build 3 màn hình UI đầu của auth flow theo đúng Figma: IntroPage (dark theme), SignUpEmailPage (email field + Google button), SignUpPasswordPage (password + hint pill).

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/presentation/intro_page.dart`
- **Tạo** `apps/mobile/lib/features/auth/presentation/shared/auth_text_field.dart` — reusable dark text field
- **Tạo** `apps/mobile/lib/features/auth/presentation/shared/auth_widgets.dart` — `_BackButton`, `_OrDivider`, `_GoogleButton`, `_ContinueButton`, `_HintPill`
- **Tạo** `apps/mobile/lib/features/auth/presentation/signup/signup_email_page.dart`
- **Tạo** `apps/mobile/lib/features/auth/presentation/signup/signup_password_page.dart`
- **Sửa** `apps/mobile/lib/core/router/app_router.dart` — thêm routes: `/signup/email`, `/signup/password`, `/signup/name`, `/signup/username`
- **Tạo** `apps/mobile/test/features/auth/presentation/intro_page_test.dart`

## UI spec theo Figma
### IntroPage (`/intro`)
- Background: `Colors.black`
- Text: "LogoMeep" (bold, white, 28px)
- Tagline: "Bắt trọn từng khoảnh khắc,\nlưu giữ ký ức cùng những người thân yêu" (white70)
- CTA 1 (FilledButton): "Tạo tài khoản mới" + camera icon → `context.push('/signup/email')`
- CTA 2 (TextButton): "Đăng nhập" → `context.push('/login/email')`

### SignUpEmailPage (`/signup/email`)
- Back button (circle, top-left)
- Title: "Email của bạn là gì?" (bold, white, 22px)
- TextField: placeholder "Địa chỉ email", keyboardType email
- Divider: "Hoặc" (white54)
- Google button: "Tiếp tục với Google" (outlined, white border)
- CTA: "Tiếp tục →" — disabled nếu email format invalid

### SignUpPasswordPage (`/signup/password`)
- Back button
- Title: "Chọn một mật khẩu" (bold, white, 22px)
- TextField: placeholder "Mật khẩu", obscureText: true
- Hint pill: "Mật khẩu của bạn phải dài tối thiểu 8 ký tự"
- CTA: "Tiếp tục →" — disabled nếu password.length < 8

## Acceptance criteria
- [ ] IntroPage hiển thị "Tạo tài khoản mới" và "Đăng nhập"
- [ ] Tap "Tạo tài khoản mới" → navigate `/signup/email`
- [ ] CTA "Tiếp tục" disabled khi email format sai
- [ ] CTA "Tiếp tục" enabled khi email hợp lệ (x@x.x)
- [ ] Password < 8 ký tự → CTA disabled
- [ ] Widget test IntroPage PASS

## Lưu ý kỹ thuật
- Dùng `ConsumerStatefulWidget` cho SignUpEmailPage (cần ref để gọi `loginControllerProvider.notifier.signInWithGoogle()`)
- Google Sign-In button gọi `LoginController`, không phải `SignUpController`
- Shared widgets (`_BackButton`, etc.) là private — đặt trong `auth_widgets.dart` để các signup/login screens import

## Definition of Done
- [ ] 3 màn hình render đúng theo Figma (dark theme, layout)
- [ ] Widget test IntroPage PASS
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T6 (`SignUpController`) phải done — để `signUpControllerProvider` available
- Issue T7 (`LoginController`) phải done — để Google Sign-In button hoạt động
- Issue T1 (`AppRouter`) phải done — để routes available
'@

$out6 = gh issue create `
  --repo $repo `
  --title "[Auth] T8+9: IntroPage + SignUpEmailPage + SignUpPasswordPage" `
  --body $body6 `
  --assignee "katheramp" `


Write-Host "Created: $out6" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 7: SignUpNamePage + SignUpUsernamePage
# ─────────────────────────────────────────────
$body7 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 10
> 👤 Assignee: HanDHG
> 🎨 Figma: Đăng ký_Nhập họ tên + Đăng ký_Nhập username + Đăng ký_Nhập username-1

## Mục tiêu
Build 2 màn hình cuối của signup flow: nhập họ tên và chọn username với real-time availability check (debounce 500ms) + indicator "Tuyệt vời! ✓". Tap "Tiếp tục" ở username screen → gọi `createAccount()`.

## Files cần tạo
- **Tạo** `apps/mobile/lib/features/auth/presentation/signup/signup_name_page.dart`
- **Tạo** `apps/mobile/lib/features/auth/presentation/signup/signup_username_page.dart`
- **Tạo** `apps/mobile/test/features/auth/presentation/signup_username_page_test.dart`

## UI spec theo Figma
### SignUpNamePage (`/signup/name`)
- Back button
- Title: "Tên bạn là gì?" (bold, white, 22px)
- TextField 1: placeholder "Họ"
- TextField 2: placeholder "Tên"
- CTA: "Tiếp tục →" — disabled nếu Họ hoặc Tên empty

### SignUpUsernamePage (`/signup/username`)
- Back button
- Title: "Chọn tên người dùng của bạn" (bold, white, 22px)
- TextField: placeholder "Tên người dùng"
- **Status indicator** (3 states):
  - Empty / format sai: pill "Việc này sẽ giúp bạn kết nối bạn bè nhanh chóng."
  - Checking: `CircularProgressIndicator` (white54)
  - Available ✓: Row với icon + text "Tuyệt vời!" (greenAccent)
  - Taken ✗: pill "Tên này đã được dùng" (redAccent)
- CTA: "Tiếp tục →" — **disabled** trừ khi `isUsernameAvailable == true`
- Tap CTA → `createAccount()` → nếu success → `context.go('/home')`

## Username validation (client-side trước khi query)
- Regex: `^[a-z0-9_]{3,20}\$`
- Debounce: 500ms sau keystroke
- Gọi `signUpControllerProvider.notifier.checkUsername(value)`

## Acceptance criteria
- [ ] Họ / Tên empty → CTA disabled
- [ ] Username empty → hint pill hiện
- [ ] Username đang check → spinner hiện
- [ ] Username available → "Tuyệt vời! ✓" hiện, CTA enabled
- [ ] Username taken → pill đỏ hiện, CTA disabled
- [ ] Tap CTA khi available → `createAccount()` được gọi
- [ ] Widget test "hint pill khi empty" PASS

## Definition of Done
- [ ] 2 màn hình render đúng Figma
- [ ] Widget test PASS
- [ ] `flutter analyze` clean
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T8+9 phải done (`auth_widgets.dart` shared components)
- Issue T6 (`SignUpController`) phải done (`checkUsername`, `createAccount`)
'@

$out7 = gh issue create `
  --repo $repo `
  --title "[Auth] T10: SignUpNamePage + SignUpUsernamePage" `
  --body $body7 `
  --assignee "katheramp" `


Write-Host "Created: $out7" -ForegroundColor Green

# ─────────────────────────────────────────────
# Issue 8: LoginEmailPage + LoginPasswordPage
# ─────────────────────────────────────────────
$body8 = @'
> 🔗 Sub-issue của Epic: #1 [T0] Auth — M1
> 📋 Plan: `docs/plans/2026-05-04-auth.md` § Task 11
> 👤 Assignee: NganTNK
> 🎨 Figma: Đăng nhập_Nhập email + Đăng nhập_Nhập MK + Đăng nhập_Thành công

## Mục tiêu
Build 2 màn hình login: nhập email (dùng chung layout với signup email) và nhập mật khẩu với "Bạn đã quên mật khẩu?" link + success button state "Bạn đã sẵn sàng ✓".

## Files cần tạo / sửa
- **Tạo** `apps/mobile/lib/features/auth/presentation/login/login_email_page.dart`
- **Tạo** `apps/mobile/lib/features/auth/presentation/login/login_password_page.dart`
- **Sửa** `apps/mobile/lib/core/router/app_router.dart` — thêm routes `/login/email`, `/login/password` (pass email qua `extra`)

## UI spec theo Figma
### LoginEmailPage (`/login/email`)
- Layout **giống hệt** SignUpEmailPage:
  - Back button
  - Title: "Email của bạn là gì?"
  - TextField: "Địa chỉ email"
  - Divider "Hoặc" + Google button "Tiếp tục với Google"
  - CTA: "Tiếp tục →" — disabled khi email format sai
- Tap CTA → `context.push('/login/password', extra: emailValue)`

### LoginPasswordPage (`/login/password`)
- Back button
- Title: "Điền mật khẩu của bạn" (bold, white, 22px)
- TextField: placeholder "Mật khẩu", obscureText: true
- Link: "Bạn đã quên mật khẩu?" (pill style, white12 bg) — tap → `sendPasswordReset(email)` → SnackBar
- Error display: nếu `state.errorMessage != null` → `_HintPill` màu redAccent
- **CTA button 3 states:**
  - Default: "Tiếp tục →" (disabled nếu password empty)
  - Loading: spinner + "Tiếp tục"
  - Success: "Bạn đã sẵn sàng ✓" (giữ ~800ms) → `context.go('/home')`

## Acceptance criteria
- [ ] LoginEmailPage layout giống SignUpEmailPage (dùng lại shared widgets)
- [ ] CTA disabled khi email format sai
- [ ] Google Sign-In button navigates đúng (same logic như SignUpEmailPage)
- [ ] LoginPasswordPage hiển thị error message từ `loginControllerProvider`
- [ ] "Bạn đã quên mật khẩu?" tap → SnackBar confirm email gửi
- [ ] Login thành công → button đổi "Bạn đã sẵn sàng ✓" → navigate `/home` sau 800ms
- [ ] `flutter analyze` clean

## Lưu ý kỹ thuật
- `LoginPasswordPage` nhận `email` qua constructor (từ router `state.extra`)
- Dùng lại `_BackButton`, `_OrDivider`, `_GoogleButton`, `_ContinueButton`, `_HintPill` từ `auth_widgets.dart`
- `_LoginButton` là widget mới (3 states) — đặt trong `login_password_page.dart` (private)

## Definition of Done
- [ ] 2 màn hình render đúng Figma
- [ ] `flutter analyze` clean
- [ ] Manual test: login sai → error; login đúng → "Bạn đã sẵn sàng ✓" → /home
- [ ] PR merged (reviewer: ThienPDM)

## Phụ thuộc
- Issue T8+9 phải done (`auth_widgets.dart` shared components)
- Issue T7 (`LoginController`) phải done
'@

$out8 = gh issue create `
  --repo $repo `
  --title "[Auth] T11: LoginEmailPage + LoginPasswordPage" `
  --body $body8 `
  --assignee "JanaKimmm" `


Write-Host "Created: $out8" -ForegroundColor Green

Write-Host ""
Write-Host "Done! 8 sub-issues created cho Epic #1 Auth." -ForegroundColor Cyan
Write-Host "Link tren vao Epic #1: https://github.com/$repo/issues/1" -ForegroundColor Yellow

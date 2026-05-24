# scripts/modules/auth.ps1
# Module: Auth | Assignees: ThienPDM/KhoaLND/HanDHG/NganTNK | M1
# Sub-issues co assignee rieng theo role

function Create-AuthModule {
    $parentBody = @'
> **Tier:** T0 | **Milestone:** M1 | **Parent Owner:** ThienPDM
> **Spec:** `docs/specs/2026-05-04-auth.md`
> **Plan:** `docs/plans/2026-05-04-auth.md`
> **Todo:** `tasks/todo-auth.md`
> **Phụ thuộc vào:** Contracts LX0 + LX1 (ThienPDM merge trước)
> **Được phụ thuộc bởi:** Tất cả modules còn lại

## Mục tiêu
Đăng ký (4 bước), đăng nhập (email/password + Google Sign-In), auto-login, forgot password. Foundation của toàn bộ app.

## User stories
- Đăng ký tài khoản mới qua email hoặc Google
- Đăng nhập → navigate `/home` tự động
- Auto-login: mở app khi đã login → không cần login lại
- Quên mật khẩu → nhận email reset

## Data model
**`/users/{uid}`**: UserProfile (uid, email, firstName, lastName, username, avatarUrl, bio, dateOfBirth, phoneNumber, gender, postCount, friendCount, spaceCount, createdAt)
**`/usernames/{username}`**: `{ uid }` — enforce unique username

## Signup flow (4 steps)
```
/signup/email → /signup/password → /signup/name → /signup/username → /home
```

## Google Sign-In flow
Không dùng `additionalUserInfo.isNewUser` (không reliable). Thay vào đó: query `/users/{uid}` sau sign-in:
- Tồn tại → `isSuccess = true` → `/home`
- Không tồn tại → `needsProfile = true` → `/signup/name`

## Assignees per task
| Task | Assignee |
|---|---|
| T1: Firebase init + AppRouter | ThienPDM |
| T2+3: UserProfile + FirebaseAuthRepository | KhoaLND |
| T4+5: UserRepository + Firestore rules | ThienPDM |
| T6: SignUpController | KhoaLND |
| T7: LoginController + Google Sign-In | KhoaLND |
| T8+9: IntroPage + SignUp screens | HanDHG |
| T10: SignUpName + SignUpUsername | HanDHG |
| T11: LoginEmail + LoginPassword | NganTNK |
'@

    $subs = @(
        @{
            title    = "[Auth] T1 — Firebase init + AppRouter"
            assignee = "manhthien2005"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 1
> **Assignee:** ThienPDM | **Estimate:** S (~4h) | **Branch:** `feat/ThienPDM/auth-firebase-router`
> **Bị block bởi:** LX1 contracts đã merge (firebase_options.dart + authRepositoryProvider stub)

## Files cần tạo / sửa
- `apps/mobile/lib/main.dart` — thêm `Firebase.initializeApp()`, dùng `MaterialApp.router`
- `apps/mobile/lib/core/router/app_router.dart` — `@riverpod GoRouter appRouter` với redirect guard dựa `currentUidProvider`
- `apps/mobile/lib/features/home/presentation/home_page.dart` — placeholder Scaffold

## Acceptance criteria
- [ ] App khởi động không crash sau `Firebase.initializeApp()`
- [ ] User chưa login → redirect `/intro`
- [ ] User đã login → redirect `/home`
- [ ] `flutter analyze` clean

## Definition of Done
- [ ] App compile và chạy trên Android emulator
- [ ] PR merged vào `develop` (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T2+3 — UserProfile model + FirebaseAuthRepository"
            assignee = "CatS1mp"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 2, 3
> **Assignee:** KhoaLND | **Estimate:** M (~8h) | **Branch:** `feat/KhoaLND/auth-repository`
> **Bị block bởi:** {sub0} — T1 phải done

## Files cần tạo
- `lib/features/auth/data/user_profile.dart` — @freezed, `displayName` getter (`'$firstName $lastName'`), `TimestampConverter`
- `lib/features/auth/data/user_profile.freezed.dart`, `user_profile.g.dart` (generated)
- `lib/features/auth/data/firebase_auth_repository.dart` — impl `AuthRepository`
- `test/features/auth/data/user_profile_test.dart`
- `test/features/auth/data/firebase_auth_repository_test.dart`

## Error mapping (bắt buộc implement)
| Firebase code | Message tiếng Việt |
|---|---|
| `user-not-found` | Không tìm thấy tài khoản với email này. |
| `wrong-password` / `invalid-credential` | Mật khẩu không đúng. Vui lòng thử lại. |
| `email-already-in-use` | Email này đã được sử dụng. |
| `weak-password` | Mật khẩu phải dài tối thiểu 8 ký tự. |

## Acceptance criteria
- [ ] `UserProfile.displayName` trả `'$firstName $lastName'`
- [ ] `UserProfile` fromJson/toJson round-trip pass
- [ ] `signInWithEmail` wrong password → throw `UnauthenticatedError` với message tiếng Việt
- [ ] `signOut` → `currentUid == null`
- [ ] `flutter test test/features/auth/data/` — 0 failures

## Definition of Done
- [ ] Tests PASS (firebase_auth_mocks)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T4+5 — UserRepository + Firestore rules"
            assignee = "manhthien2005"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 4, 5
> **Assignee:** ThienPDM | **Estimate:** M (~8h) | **Branch:** `feat/ThienPDM/auth-user-repository`
> **Bị block bởi:** {sub1} — T2+3 phải done (cần UserProfile model)

## Files cần tạo / sửa
- `lib/features/auth/data/firebase_user_repository.dart` — impl `UserRepository`
- `lib/main.dart` — override `userRepositoryProvider`
- `firebase/firestore.rules` — thêm rules `/users/{uid}` + `/usernames/{username}`
- `test/features/auth/data/firebase_user_repository_test.dart`

## Firestore rules bắt buộc
```javascript
match /users/{uid} {
  allow read: if isAuthed() && request.auth.uid == uid;
  allow create: if isAuthed() && request.auth.uid == uid
    && request.resource.data.keys().hasAll(['uid','email','firstName','lastName','username','createdAt'])
    && request.resource.data.username.size() >= 3
    && request.resource.data.username.size() <= 20;
  allow update: if isOwner(uid)
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uid','createdAt','email']);
  allow delete: if false;
}
match /usernames/{username} {
  allow read: if isAuthed();
  allow create: if isAuthed() && request.resource.data.uid == request.auth.uid;
  allow delete: if isAuthed() && resource.data.uid == request.auth.uid;
  allow update: if false;
}
```

## Acceptance criteria
- [ ] `createProfile` → batch write `/users/{uid}` + `/usernames/{username}` trong 1 transaction
- [ ] `isUsernameAvailable('taken')` → false khi doc tồn tại
- [ ] `getProfile('nonexistent')` → null
- [ ] Firestore rule: stranger đọc `/users/{uid}` của người khác → denied
- [ ] `flutter test test/features/auth/data/firebase_user_repository_test.dart` — PASS

## Definition of Done
- [ ] Tests PASS (fake_cloud_firestore)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T6 — SignUpController (4-step state machine)"
            assignee = "CatS1mp"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 6
> **Assignee:** KhoaLND | **Estimate:** M (~8h) | **Branch:** `feat/KhoaLND/auth-signup-controller`
> **Bị block bởi:** {sub2} — T4+5 phải done (UserRepository cần có)

## Files cần tạo
- `lib/features/auth/application/sign_up_state.dart` — `SignUpStep` enum (email/password/name/username) + `SignUpState` @freezed
- `lib/features/auth/application/sign_up_controller.dart` — `@riverpod class SignUpController`
- `test/features/auth/application/sign_up_controller_test.dart`

## SignUpState schema
```dart
enum SignUpStep { email, password, name, username }
@freezed class SignUpState {
  SignUpStep step
  String email, password, firstName, lastName, username
  bool isCheckingUsername   // debounce spinner
  bool isUsernameAvailable  // "Tuyệt vời!" / taken
  bool isLoading            // createAccount() đang chạy
  String? errorMessage
}
```

## Acceptance criteria
- [ ] Initial state: `step = email`, tất cả empty
- [ ] `nextStep()`: email → password → name → username
- [ ] `checkUsername` debounce 500ms, query `/usernames/{x}`
- [ ] `createAccount()`: gọi `signUpWithEmail` + `createProfile` đúng thứ tự
- [ ] `createAccount()` lỗi → `errorMessage` set, `isLoading = false`
- [ ] `createAccountWithGoogle(uid, email)`: skip signUp, chỉ gọi `createProfile`
- [ ] `flutter test test/features/auth/application/sign_up_controller_test.dart` — PASS

## Definition of Done
- [ ] Tests PASS (mocktail)
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T7 — LoginController + Google Sign-In"
            assignee = "CatS1mp"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 7
> **Assignee:** KhoaLND | **Estimate:** M (~8h) | **Branch:** `feat/KhoaLND/auth-login-controller`
> **Bị block bởi:** {sub3} — T6 nên done trước (cùng application layer)

## Files cần tạo
- `lib/features/auth/application/login_controller.dart` — `LoginState` @freezed + `@riverpod class LoginController`
- `lib/features/auth/data/firebase_auth_repository.dart` — **update:** implement `signInWithGoogle()`
- `test/features/auth/application/login_controller_test.dart`

## LoginState schema
```dart
@freezed class LoginState {
  bool isLoading, isSuccess, needsProfile
  String? googleUid, googleEmail  // set khi needsProfile=true
  String? errorMessage
}
```

## Google Sign-In logic (QUAN TRỌNG — không dùng isNewUser)
```dart
// Sau signInWithGoogle(), query /users/{uid}:
// - Tồn tại → isSuccess = true → /home
// - Không tồn tại → needsProfile = true → /signup/name
```

## Acceptance criteria
- [ ] `signIn` success → `isSuccess = true`
- [ ] `signIn` wrong password → `errorMessage != null`, `isSuccess = false`
- [ ] `signInWithGoogle` new user → `needsProfile = true`, `googleUid` set
- [ ] `signInWithGoogle` returning user → `isSuccess = true`
- [ ] `sendPasswordReset` gọi `sendPasswordResetEmail` đúng
- [ ] `flutter test test/features/auth/application/login_controller_test.dart` — PASS (4 test cases)

## Definition of Done
- [ ] Tests PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T8+9 — IntroPage + SignUpEmailPage + SignUpPasswordPage"
            assignee = "katheramp"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 8, 9
> **Assignee:** HanDHG | **Estimate:** L (2 ngày) | **Branch:** `feat/HanDHG/auth-intro-signup-screens`
> **Bị block bởi:** {sub3} — T6 done; {sub4} — T7 done (providers cần có)
> **Figma:** Trang giới thiệu + Đăng ký_Nhập email + Đăng ký_Nhập MK

## Files cần tạo
- `lib/features/auth/presentation/intro_page.dart`
- `lib/features/auth/presentation/shared/auth_text_field.dart` — reusable dark text field
- `lib/features/auth/presentation/shared/auth_widgets.dart` — `_BackButton`, `_OrDivider`, `_GoogleButton`, `_ContinueButton`, `_HintPill`
- `lib/features/auth/presentation/signup/signup_email_page.dart`
- `lib/features/auth/presentation/signup/signup_password_page.dart`
- `lib/core/router/app_router.dart` — **update:** thêm routes `/signup/email`, `/signup/password`
- `test/features/auth/presentation/intro_page_test.dart`

## UI spec
### IntroPage (`/intro`) — dark theme
- Background: `Colors.black`, logo, tagline
- CTA 1: "Tạo tài khoản mới" → `/signup/email`
- CTA 2: "Đăng nhập" → `/login/email`

### SignUpEmailPage (`/signup/email`)
- Back button, Title: "Email của bạn là gì?", TextField email
- Google button: "Tiếp tục với Google"
- CTA disabled khi email format sai

### SignUpPasswordPage (`/signup/password`)
- Back button, Title: "Chọn một mật khẩu"
- TextField obscureText, hint pill "Tối thiểu 8 ký tự"
- CTA disabled khi `password.length < 8`

## Acceptance criteria
- [ ] IntroPage: 2 CTA navigate đúng
- [ ] SignUpEmail: CTA disabled khi email sai format
- [ ] Google button gọi `LoginController.signInWithGoogle()` (không phải SignUpController)
- [ ] Password: CTA disabled khi < 8 ký tự
- [ ] Widget test IntroPage PASS

## Definition of Done
- [ ] 3 màn hình render đúng dark theme theo Figma
- [ ] Widget test PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T10 — SignUpNamePage + SignUpUsernamePage"
            assignee = "katheramp"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 10
> **Assignee:** HanDHG | **Estimate:** M (~8h) | **Branch:** `feat/HanDHG/auth-signup-name-username`
> **Bị block bởi:** {sub5} — T8+9 done (auth_widgets.dart shared components)
> **Figma:** Đăng ký_Nhập họ tên + Đăng ký_Nhập username + Đăng ký_Nhập username-1

## Files cần tạo
- `lib/features/auth/presentation/signup/signup_name_page.dart`
- `lib/features/auth/presentation/signup/signup_username_page.dart`
- `test/features/auth/presentation/signup_username_page_test.dart`

## UI spec
### SignUpNamePage (`/signup/name`)
- 2 TextFields: Họ + Tên
- CTA disabled khi Họ hoặc Tên empty

### SignUpUsernamePage (`/signup/username`)
- TextField username + **3 status states:**
  - Empty/format sai: pill "Việc này giúp kết nối bạn bè nhanh chóng."
  - Checking: `CircularProgressIndicator`
  - Available ✓: icon + text "Tuyệt vời!" (greenAccent)
  - Taken ✗: pill đỏ "Tên này đã được dùng"
- CTA enabled **chỉ** khi `isUsernameAvailable == true`
- Tap CTA → `createAccount()` → nếu success → `context.go('/home')`

## Username validation (client-side trước khi query)
- Regex: `^[a-z0-9_]{3,20}$`
- Debounce 500ms sau keystroke → `SignUpController.checkUsername(value)`

## Acceptance criteria
- [ ] Họ / Tên empty → CTA disabled
- [ ] Username: 3 states render đúng
- [ ] CTA enabled chỉ khi `isUsernameAvailable == true`
- [ ] Tap CTA → `createAccount()` được gọi
- [ ] Widget test "hint pill khi empty" PASS

## Definition of Done
- [ ] 2 màn hình render đúng Figma
- [ ] Widget test PASS
- [ ] PR merged (reviewer: ThienPDM)
'@
        },
        @{
            title    = "[Auth] T11 — LoginEmailPage + LoginPasswordPage"
            assignee = "JanaKimmm"
            body     = @'
> **Plan:** `docs/plans/2026-05-04-auth.md` — Task 11
> **Assignee:** NganTNK | **Estimate:** M (~8h) | **Branch:** `feat/NganTNK/auth-login-screens`
> **Bị block bởi:** {sub5} — T8+9 done (auth_widgets.dart shared components)
> **Figma:** Đăng nhập_Nhập email + Đăng nhập_Nhập MK + Đăng nhập_Thành công

## Files cần tạo
- `lib/features/auth/presentation/login/login_email_page.dart`
- `lib/features/auth/presentation/login/login_password_page.dart`
- `lib/core/router/app_router.dart` — **update:** thêm routes `/login/email`, `/login/password`

## UI spec
### LoginEmailPage (`/login/email`) — layout giống SignUpEmailPage
- Dùng lại `_BackButton`, `_OrDivider`, `_GoogleButton`, `_ContinueButton` từ `auth_widgets.dart`
- Tap CTA → `context.push('/login/password', extra: emailValue)`

### LoginPasswordPage (`/login/password`)
- Back button, Title: "Điền mật khẩu của bạn"
- Link "Bạn đã quên mật khẩu?" → `sendPasswordReset(email)` → SnackBar
- Error display: `_HintPill` màu redAccent khi `state.errorMessage != null`
- **CTA button 3 states:**
  - Default: "Tiếp tục →" (disabled nếu empty)
  - Loading: spinner
  - Success: "Bạn đã sẵn sàng ✓" (giữ ~800ms) → `context.go('/home')`

## Acceptance criteria
- [ ] LoginEmail: layout dùng lại shared widgets
- [ ] LoginPassword: hiển thị `errorMessage` từ `LoginController`
- [ ] "Quên mật khẩu?" tap → SnackBar confirm
- [ ] Login success → "Bạn đã sẵn sàng ✓" → navigate `/home` sau 800ms
- [ ] `flutter analyze` clean

## Definition of Done
- [ ] 2 màn hình render đúng Figma
- [ ] Manual test: login sai → error; login đúng → success state → /home
- [ ] PR merged (reviewer: ThienPDM)
'@
        }
    )

    New-Module "🔑 [Auth]" $parentBody $ThienPDM 1 $subs
}

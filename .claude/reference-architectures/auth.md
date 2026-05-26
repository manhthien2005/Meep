# Reference Architecture — AUTH module

> **Vai trò:** AUTH (`apps/mobile/lib/features/auth/`) là **module chuẩn** cho Meep. Mỗi pattern dưới đây có file thật để dev mới đọc + copy.
> **Mục tiêu:** Khi anh giao module mới (`friend`, `feed`, `post`, ...), dev owner copy structure + chỉnh tên — không phát minh lại pattern.
> **Last reviewed:** 2026-05-26 (sau PR #170 Round D).

---

## 11 patterns

### 1. Folder layout — feature-first, strict 3 layers

```
features/<module>/
├── data/
│   ├── <model>.dart              # @freezed + json_serializable
│   ├── <model>.freezed.dart      # generated, commit cùng
│   ├── <model>.g.dart            # generated, commit cùng
│   ├── <name>_repository.dart    # abstract — contract leader chốt
│   └── firebase_<name>_repository.dart   # impl, throws AppError tại boundary
├── application/
│   ├── <name>_state.dart         # @freezed state
│   ├── <name>_controller.dart    # @riverpod NotifierProvider
│   └── <name>_controller.g.dart  # generated
└── presentation/
    ├── <page>_page.dart          # ConsumerStatefulWidget, ref.watch state
    └── widgets/                  # extract khi ≥ 2 lần reuse trong feature
```

**Reference files:**
- [`features/auth/data/user_profile.dart`](../../apps/mobile/lib/features/auth/data/user_profile.dart) — freezed model
- [`features/auth/data/auth_repository.dart`](../../apps/mobile/lib/features/auth/data/auth_repository.dart) — abstract contract
- [`features/auth/data/firebase_auth_repository.dart`](../../apps/mobile/lib/features/auth/data/firebase_auth_repository.dart) — Firebase impl
- [`features/auth/presentation/widgets/forgot_password_dialog.dart`](../../apps/mobile/lib/features/auth/presentation/widgets/forgot_password_dialog.dart) — extracted widget

### 2. Repository pattern — abstract + Firebase impl + error mapping

**Abstract** ([`auth_repository.dart`](../../apps/mobile/lib/features/auth/data/auth_repository.dart)):
- Method names mô tả intent: `signInWithEmail`, không phải `firebaseSignIn`
- Doc-string mô tả contract: throws gì, khi nào
- Trả `void` / typed model — KHÔNG Firebase types

**Implementation** ([`firebase_auth_repository.dart`](../../apps/mobile/lib/features/auth/data/firebase_auth_repository.dart)):
- `try { firebase op } on FirebaseException catch (e) { throw _mapXxxError(e); }` tại MỌI boundary
- Private `_mapSignUpError` / `_mapSignInError` / `_mapGenericError` switch trên `e.code` → `AppError` subclass với message **tiếng Việt**
- Helpers xếp cuối class

```dart
// snippet from firebase_auth_repository.dart
AppError _mapSignInError(FirebaseAuthException e) => switch (e.code) {
      'wrong-password' || 'invalid-credential' =>
        const UnauthenticatedError(message: 'Mật khẩu không đúng'),
      'user-not-found' => const UnauthenticatedError(
          message: 'Không tìm thấy tài khoản với email này',
        ),
      'network-request-failed' =>
        const NetworkError(message: 'Không có kết nối mạng'),
      _ => UnexpectedError(message: e.message ?? e.code, cause: e),
    };
```

### 3. Error model — `AppError` sealed + `fromUnknown` + `OperationCancelledError`

Reference: [`core/error/app_error.dart`](../../apps/mobile/lib/core/error/app_error.dart)

```dart
sealed class AppError implements Exception { code, message, cause; }
  ├─ UnauthenticatedError    // sai creds, hết token
  ├─ ForbiddenError          // không quyền
  ├─ NotFoundError           // resource không tồn tại
  ├─ ValidationError         // input invalid
  ├─ NetworkError            // mạng lỗi
  ├─ UnexpectedError         // wrap cause unknown
  └─ OperationCancelledError // user cancel — controller silent dismiss

AppError.fromUnknown(e, {fallback}) → collapse try-catch boilerplate
```

**Khi nào extend:**
- Thêm subclass nếu module có error kind khác hẳn (vd `PostError`, `FriendshipError`)
- Hoặc dùng `code` field để phân biệt trong subclass có sẵn

### 4. Controller pattern — `_afterFailure(e)` helper

Reference: [`features/auth/application/login_controller.dart`](../../apps/mobile/lib/features/auth/application/login_controller.dart)

```dart
@riverpod
class XxxController extends _$XxxController {
  @override
  XxxState build() => const XxxState(...);

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<void> doSomething() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(repoProvider).operation();
      state = state.copyWith(isLoading: false, /* success fields */);
    } catch (e) {
      state = _afterFailure(e);
    }
  }

  /// Reset isLoading + map error (null cho OperationCancelledError = silent).
  XxxState _afterFailure(Object e, {String fallback = 'Đã có lỗi xảy ra'}) {
    final err = AppError.fromUnknown(e, fallback: fallback);
    return state.copyWith(
      isLoading: false,
      errorMessage: err is OperationCancelledError ? null : err.message,
    );
  }
}
```

### 5. DI — `overrideWithValue` trong `main.dart`

Reference: [`features/auth/application/auth_providers.dart`](../../apps/mobile/lib/features/auth/application/auth_providers.dart), [`main.dart`](../../apps/mobile/lib/main.dart)

```dart
// 1. Provider stub trong feature
final xxxRepositoryProvider = Provider<XxxRepository>((ref) {
  throw UnimplementedError(
    'override in main.dart after Firebase.initializeApp',
  );
});

// 2. Override trong main.dart sau Firebase init
runApp(
  ProviderScope(
    overrides: [
      xxxRepositoryProvider.overrideWithValue(
        FirebaseXxxRepository(firestore: FirebaseFirestore.instance),
      ),
    ],
    child: const MeepApp(),
  ),
);
```

**Test override pattern** ([`firebase_auth_repository_test.dart`](../../apps/mobile/test/features/auth/data/firebase_auth_repository_test.dart)):
```dart
ProviderContainer makeContainer({MockFirebaseAuth? auth}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FirebaseAuthRepository(auth: auth ?? MockFirebaseAuth()),
      ),
    ],
  );
}
```

### 6. Router guard — pure function + `_RouterNotifier` listen-to-keepAlive

Reference: [`core/router/app_router.dart`](../../apps/mobile/lib/core/router/app_router.dart), test: [`test/core/router/app_router_test.dart`](../../apps/mobile/test/core/router/app_router_test.dart)

**Tách pure function** để test không cần GoRouter:
```dart
String? authRedirect({
  required bool isLoading,
  required String? uid,
  required bool? profileExists,
  required bool needsProfile,
  required String location,
}) {
  // 5-state machine với early returns
}
```

**`_RouterNotifier` no-op listen để keepAlive controllers cần xuyên route transition** (tránh autoDispose mất state):
```dart
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(currentUidProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
    ref.listen(
      loginControllerProvider.select((s) => s.needsProfile),
      (_, __) => notifyListeners(),
    );
    // No-op listen — chỉ để keepAlive
    ref.listen(signUpControllerProvider, (_, __) {});
  }
}
```

### 7. UI page pattern — dispose-safe + clear-on-keystroke

Reference: [`features/auth/presentation/login/login_password_page.dart`](../../apps/mobile/lib/features/auth/presentation/login/login_password_page.dart)

```dart
class XxxPage extends ConsumerStatefulWidget { ... }

class _XxxPageState extends ConsumerState<XxxPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    // ❌ KHÔNG `ref.read()` trong dispose — race với router teardown
    //    "Cannot use ref after the widget was disposed"
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xxxControllerProvider);
    return AppTextInput(
      onChanged: (_) {
        // Clear stale error ngay khi user gõ
        if (ref.read(xxxControllerProvider).errorMessage != null) {
          ref.read(xxxControllerProvider.notifier).clearError();
        }
        setState(() {});
      },
      errorText: state.errorMessage,
      status: state.errorMessage != null
          ? AppTextInputStatus.error
          : AppTextInputStatus.normal,
    );
  }
}
```

### 8. State model pattern — Freezed với `errorMessage` nullable

Reference: [`features/auth/application/login_state.dart`](../../apps/mobile/lib/features/auth/application/login_state.dart), [`sign_up_state.dart`](../../apps/mobile/lib/features/auth/application/sign_up_state.dart)

```dart
@freezed
class XxxState with _$XxxState {
  const factory XxxState({
    required SomeEnum step,         // multi-step flow
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,           // null = no error, sentinel pattern
  }) = _XxxState;
}
```

### 9. Session lifecycle — `revalidateSession` + orphan listener + keepAlive

Reference: [`features/auth/application/orphan_auth_check.dart`](../../apps/mobile/lib/features/auth/application/orphan_auth_check.dart), [`firebase_auth_repository.dart:157`](../../apps/mobile/lib/features/auth/data/firebase_auth_repository.dart)

**3 layer:**

1. **Startup `revalidateSession()`** — gọi trước `runApp`, dùng `user.reload()` detect account deleted/disabled trên server. Network/timeout → giữ session offline-friendly.

2. **Orphan auth listener** — pure function `checkOrphanAuth()` trong `MeepApp.build`, signOut nếu `uid != null && profile == null && !isActiveFlow`. Check `profileState.isLoading` thay vì `hasValue` (Riverpod 2.5 previousValue quirk).

3. **KeepAlive xuyên route** — `_RouterNotifier` no-op listen `signUpControllerProvider`.

### 10. Test stratification — 5 layers

Reference: `apps/mobile/test/features/auth/`, `firebase/functions/src/firestore.rules.test.ts`

| Layer | Tool | Pattern | Example |
|---|---|---|---|
| Data (Firestore) | `fake_cloud_firestore` | Repo CRUD + edge cases | [`firebase_user_repository_test.dart`](../../apps/mobile/test/features/auth/data/firebase_user_repository_test.dart) |
| Data (Auth) | `firebase_auth_mocks` + `mock_exceptions` | Repo error mapping | [`firebase_auth_repository_test.dart`](../../apps/mobile/test/features/auth/data/firebase_auth_repository_test.dart) |
| Application (Controller) | `ProviderContainer` + mock repos | State transitions success/error | [`login_controller_test.dart`](../../apps/mobile/test/features/auth/application/login_controller_test.dart) |
| Pure logic | Direct fn call | Validators, router guard, orphan check | [`auth_validators_test.dart`](../../apps/mobile/test/core/validators/auth_validators_test.dart), [`orphan_auth_check_test.dart`](../../apps/mobile/test/features/auth/application/orphan_auth_check_test.dart) |
| UI Widget | `flutter_test` | Render + interaction | [`app_text_input_test.dart`](../../apps/mobile/test/shared/widgets/app_text_input_test.dart) |
| Rules | `@firebase/rules-unit-testing` + emulator | owner/friend/stranger/unauth matrix | [`firestore.rules.test.ts`](../../firebase/functions/src/firestore.rules.test.ts) |

**Coverage targets:** business logic ≥ 80%, data ≥ 70%, UI ≥ 50%

### 11. Firestore rules — helpers + per-collection + default deny

Reference: [`firebase/firestore.rules`](../../firebase/firestore.rules), test: [`firestore.rules.test.ts`](../../firebase/functions/src/firestore.rules.test.ts)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helpers ở đầu
    function isAuthed() { return request.auth != null; }
    function isOwner(uid) { return isAuthed() && request.auth.uid == uid; }
    function isFriend(uid) { ... pairId helper ... }

    // Per-collection rule với explicit allow read/create/update/delete
    match /users/{uid} {
      allow read: if isAuthed();
      allow create: if isOwner(uid)
        && request.resource.data.keys().hasAll(['uid', 'email', ...])
        && request.resource.data.username.matches('^[a-z0-9_]+$');
      allow update: if isOwner(uid)
        && !request.resource.data.diff(resource.data).affectedKeys()
            .hasAny(['uid', 'createdAt', 'email', ...]);  // immutable fields
      allow delete: if false;
    }

    // Default deny ở cuối — non-negotiable
    match /{document=**} { allow read, write: if false; }
  }
}
```

**Rules tests mandatory matrix:** owner / friend / stranger / unauthenticated cho mỗi collection có user data.

---

## Workflow patterns đã proven trong AUTH

### Multi-round refactor structure

```
Discovery → đọc spec + existing code + map files
  ↓
Round 1: Core layer (model + repository + error)
Round 2: UI layer (pages + widgets)
Round 3: Tests
Round 4: Verify (format + analyze + test)
Round N: Bug fix từ device testing
  ↓
Final report + commit
```

Mỗi round: edit → verify analyze + test → only proceed nếu green.

### Pre-PR checklist

```bash
flutter analyze --no-pub                                              # 0 issues
dart format --set-exit-if-changed --output none lib test               # clean
flutter test                                                           # all pass
(cd firebase/functions && npm test && npm run lint)                    # all pass
firebase emulators:exec --only firestore "cd functions && npm run test:rules"  # all pass
```

### Conflict resolution (PR vs develop diverged)

- `git fetch origin develop`
- `git merge --no-ff origin/develop -X ours` — refactor branch wins text conflicts
- Spot-check critical files for duplicate/legacy logic merged in (vd `LoginController.confirmPasswordReset` duplicate khi Round C extract)
- Verify analyze + test
- Push → PR auto-update mergeable

---

## Khi nào module mới copy từ AUTH

**Bắt buộc** copy patterns cho mọi module có:
- User-facing data (cần repository pattern + error mapping)
- Multi-step UI flow (cần controller state pattern + clearError)
- Firestore collection (cần rules + tests)

**Optional** copy patterns:
- Native widget (`apps/widget/`) — không cần Riverpod, có pattern riêng
- Cloud Function trigger — pattern khác (xem `firebase/functions/CLAUDE.md`)

**KHÔNG copy mù:**
- Session lifecycle (Pattern #9) chỉ apply cho auth module
- KeepAlive listen (Pattern #6) chỉ cần nếu controller phải sống xuyên route transitions

---

## Caveats — chỗ AUTH chưa hoàn hảo

- `reauthenticateWithCredential` + `updateEmail` còn `UnimplementedError` — Profile/Settings T7 sẽ implement
- `isEmailAvailable` yêu cầu Firebase Console > **Email Enumeration Protection TẮT** (workaround pre-MVP)
- In-session account deletion: ~1h delay đến token refresh — chấp nhận edge case
- Production deploy cần `assetlinks.json` + custom domain (xem ADR-0005)

---

## Khi pattern không khớp module mới

Module có nhu cầu khác AUTH → **đừng ép pattern**. Discuss với leader, viết spec riêng, có thể tạo reference architecture mới (vd `feed.md` cho Feed module pattern).

Nguyên tắc: **AUTH là chuẩn, không phải dogma.** Adapt khi có lý do rõ ràng.

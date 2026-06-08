# Phase 2 — Solo Polish Playbook

> **Bối cảnh:** Project Meep đã bàn giao lại cho ThienPDM solo. Anh sẽ chạy 7 PR fix theo DAG để close 9 P0 release blocker từ audit pass 1.
>
> **Reference:** `docs/audits/99_global_fix_order.md` (fix order DAG + effort estimate)
>
> **Workflow style:** Sequential 1 PR 1 lúc. Mỗi PR có spec ngắn + implement + verify local + self-review + PR. Anh tự work qua sub-session pair hoặc orchestrator session.

---

## Cách dùng playbook này

### Workflow per PR

```
1. Đọc section PR tương ứng trong playbook này.
2. Tạo branch local từ develop.
3. Implement theo "Implementation steps".
4. Verify theo "Verify checklist".
5. Self-review qua /review skill.
6. Push + tạo PR theo template "PR description template".
7. Anh merge → next PR.
```

### Split-session protocol (nếu anh dùng pair session riêng)

Khi pair session done, copy về session orchestrator (chính) 3 thứ:

```
1. SPEC anh + pair agreed:
   - What/Why/Acceptance criteria

2. DIFF cuối cùng (git diff develop...HEAD):
   - Verify implementation match spec không

3. VERIFY result:
   - flutter analyze output (pass/fail count)
   - flutter test output (pass/fail count)
   - Manual emulator test note (golden path passes)
```

Orchestrator session review → approve push hoặc request changes → push + PR.

### Branch naming convention (husky verified)

Format: `fix/<DevName>/<short-desc>` (lowercase kebab-case).

DevName của anh: `ThienPDM`.

Examples:
- `fix/ThienPDM/firebase-app-check`
- `fix/ThienPDM/android-release-signing`
- `fix/ThienPDM/feed-firebase-leakage`

### Commit message convention (CLAUDE.md)

Vietnamese body, English type prefix. Tham khảo CLAUDE.md §Git — Commits.

```
fix(<scope>): <mô tả tiếng Việt ngắn>

<body tiếng Việt — giải thích WHY nếu cần>

Closes audit issue ARCH-LAYER-001 (#293).
```

---

## DAG order (7 PR sequential)

| # | Batch | Branch | Closes audit | Effort | Skill cite |
|---|---|---|---|---|---|
| 1 | B1.1 | `fix/ThienPDM/firebase-app-check` | SEC-APPCHECK-001 (#294) | 30 min | — |
| 2 | B1.2 | `fix/ThienPDM/android-release-signing` | TEST-SIGN-001 (#299) | 30-60 min | — |
| 3 | B1.3 | `fix/ThienPDM/camera-permission-fallback` | UX-CAMERA-UX-001 (#300) | 1-2h | flutter-fix-layout-issues |
| 4 | B1.4 | `fix/ThienPDM/feed-firebase-leakage` | ARCH-LAYER-001/002 (#293) | 3-4h | flutter-apply-architecture-best-practices + flutter-add-widget-test |
| 5 | B2.1 | `fix/ThienPDM/users-public-profile-migration` | SEC-USER-SEC-001 (#294) + PERF-FRIEND-001 (#297) | 1-2 ngày | — |
| 6 | B2.2 | `fix/ThienPDM/feed-listener-fan-in` | PERF-FEED-001 (#297) | 2-3h | flutter-apply-architecture-best-practices |
| 7 | B3 | `feat/ThienPDM/integration-tests` | TEST-E2E-001 (#299) | 1 ngày | flutter-add-integration-test |

**Tổng:** ~3-4 ngày solo focused work.


---

# PR #1 — B1.1: Firebase App Check activation

**Closes:** SEC-APPCHECK-001 (PR #294)
**Branch:** `fix/ThienPDM/firebase-app-check`
**Effort:** 30 phút
**Risk:** Low (config-only, no business logic change)

## Spec

- **What:** Activate Firebase App Check trong main.dart với Play Integrity provider (release) + Debug provider (debug build).
- **Why:** Audit P0 — chưa activate App Check → any client gọi Firestore/Storage/Functions với staging API key hardcoded (`firebase_options.dart:56`) → automated traffic không bị block, quota crusher + cost path mở.
- **Acceptance:**
  - [ ] `FirebaseAppCheck.instance.activate(...)` được gọi sau `Firebase.initializeApp` trong `main.dart`
  - [ ] `kDebugMode` guard: Debug provider khi debug, Play Integrity khi release
  - [ ] Pubspec thêm `firebase_app_check: ^0.3.1+x` (verify latest)
  - [ ] `flutter analyze` clean
  - [ ] App launch trên debug Android emulator không crash

## Implementation steps

### 1. Add dependency
```bash
cd apps/mobile
flutter pub add firebase_app_check
```

### 2. Modify `main.dart`
Tìm block `await Firebase.initializeApp(options: ...)` (line ~52-60).

Thêm SAU initializeApp, TRƯỚC `runApp`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
);
```

### 3. Document debug token usage (CLAUDE.md trong apps/mobile)

Trong debug mode lần đầu chạy, Logcat sẽ in 1 dòng:
```
Enter this debug secret into the allow list in the Firebase Console for your project:
```

Anh copy token đó → Firebase Console → App Check → Apps → debug-token allowlist.

### 4. Enable enforcement trên Firebase Console (post-merge)

**KHÔNG** làm trong PR này. Note trong PR description:
- Sau khi merge + deploy mobile build mới với App Check active,
- Anh tự enable enforce qua Firebase Console cho: Firestore + Storage + Functions
- Verify production traffic vẫn pass trước khi tighten

## Verify checklist

```bash
cd apps/mobile

# Static check
flutter analyze --no-pub
# Expected: 0 errors

# Pub get fresh
flutter pub get

# Build sanity
flutter build apk --debug
# Expected: BUILD SUCCESSFUL
```

Manual emulator test:
- [ ] Launch app trên Android emulator
- [ ] App start không crash (Firebase initializeApp + AppCheck activate OK)
- [ ] Logcat có dòng "App Check token" (debug provider hoạt động)
- [ ] Sign-in flow vẫn work (Firestore/Auth access ok)

## PR description template

```markdown
## Mục đích

Closes SEC-APPCHECK-001 (audit #294 P0).

Activate Firebase App Check để block automated abuse traffic tới Firestore/Storage/Functions. Production blocker theo CLAUDE.md §Security Guardrails.

## Thay đổi

- `pubspec.yaml`: add `firebase_app_check: ^0.3.x`
- `main.dart`: gọi `FirebaseAppCheck.instance.activate(...)` sau `Firebase.initializeApp`
  - Debug build: `AndroidProvider.debug`
  - Release build: `AndroidProvider.playIntegrity`

## Test plan

- [x] `flutter analyze --no-pub`: 0 errors
- [x] `flutter build apk --debug`: BUILD SUCCESSFUL
- [x] Emulator launch: app start không crash
- [x] Logcat: debug token printed
- [x] Sign-in flow: vẫn work

## Followup (KHÔNG trong PR này)

Sau khi merge + deploy mobile build có App Check:
1. Anh copy debug token từ Logcat → Firebase Console → App Check → Debug tokens
2. Enable enforce trên Firebase Console (Firestore + Storage + Functions) trong staging trước
3. Verify production traffic không bị block (false positive)
4. Sau đó enforce production project

Reference: docs/audits/05_security_firebase_audit.md APPCHECK-001 fix steps.
```


---

# PR #2 — B1.2: Android release signing config

**Closes:** TEST-SIGN-001 (PR #299)
**Branch:** `fix/ThienPDM/android-release-signing`
**Effort:** 30-60 phút
**Risk:** Medium (touch build config, mất keystore = không update app)

## Spec

- **What:** Tạo upload keystore + cấu hình `key.properties` + sửa `build.gradle.kts` để release build sign với upload key, KHÔNG debug key.
- **Why:** Audit P0 — `signingConfig = signingConfigs.getByName("debug")` ở `build.gradle.kts:42` → Play Store sẽ REJECT bundle ký bằng debug key, anh không thể release app.
- **Acceptance:**
  - [ ] Keystore file tạo + backup an toàn (1Password / private vault)
  - [ ] `key.properties` setup local (gitignored)
  - [ ] `build.gradle.kts` đọc keystore qua env vars hoặc `key.properties`
  - [ ] `flutter build appbundle --release` succeed + bundle ký bằng upload key
  - [ ] `.gitignore` đã chặn `*.keystore` + `key.properties` (CLAUDE.md §Secrets verify)

## Implementation steps

### 1. Tạo upload keystore (1 lần duy nhất, BACKUP RẤT QUAN TRỌNG)

```bash
cd apps/mobile/android
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Nhập:
- Password keystore (lưu vào password manager, KHÔNG commit)
- Tên / org / location (thông tin meaningful)
- Password key (có thể same với keystore password)

**BACKUP NGAY:** copy `upload-keystore.jks` vào private vault (1Password / Drive private). Mất keystore = không thể update app trên Play Store, phải tạo app mới + tất cả user phải reinstall.

### 2. Tạo `key.properties` (gitignored)

`apps/mobile/android/key.properties`:
```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3. Verify gitignore

```bash
grep -E "key.properties|upload-keystore|\*\.keystore|\*\.jks" .gitignore
```

Expected: cả `*.keystore`, `*.jks`, `key.properties` đều trong .gitignore. CLAUDE.md §Secrets đã có sẵn — verify giữ nguyên.

### 4. Sửa `apps/mobile/android/app/build.gradle.kts`

**Đầu file** (sau `plugins {}` block):
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**Trong `android {}` block, sau `defaultConfig {}`**, THÊM `signingConfigs`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}
```

**Sửa `buildTypes.release`:**
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        // Followup (audit issue REL-MINIFY-001 P1):
        // isMinifyEnabled = true
        // isShrinkResources = true
        // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

(`minifyEnabled` + `shrinkResources` để PR riêng sau — đó là REL-MINIFY-001 P1.)

### 5. Verify build

```bash
cd apps/mobile
flutter build appbundle --release
```

Bundle output: `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.

Verify signed by upload key:
```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head -20
```

Expected: alias `upload`, not `androiddebugkey`.

## Verify checklist

```bash
# Gitignore guard
grep -E "key.properties|\*\.keystore|\*\.jks" .gitignore
# Expected: all 3 present

# Build
cd apps/mobile && flutter build appbundle --release
# Expected: BUILD SUCCESSFUL + bundle file generated

# Signing verify
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
# Expected: jar verified
```

Manual checks:
- [ ] Backup keystore vào private vault (TRƯỚC khi push PR)
- [ ] `key.properties` không tracked (`git status` không hiện)
- [ ] `upload-keystore.jks` không tracked (`git status` không hiện)

## PR description template

```markdown
## Mục đích

Closes TEST-SIGN-001 (audit #299 P0).

Tạo upload keystore + cấu hình release signing để Play Store accept bundle. Trước đây `signingConfig = signingConfigs.getByName("debug")` → Play Store reject.

## Thay đổi

- `android/app/build.gradle.kts`:
  - Load `key.properties` (gitignored)
  - Add `signingConfigs.release` với upload alias
  - `buildTypes.release.signingConfig = signingConfigs.getByName("release")`
- Untracked (KHÔNG commit, đã trong .gitignore):
  - `android/upload-keystore.jks` (backup an toàn private vault)
  - `android/key.properties`

## Test plan

- [x] `flutter build appbundle --release`: BUILD SUCCESSFUL
- [x] `jarsigner -verify ...aab`: signed by upload alias (không phải androiddebugkey)
- [x] `git status` không hiện key.properties hoặc *.jks
- [x] `.gitignore` đã chặn `*.keystore`, `*.jks`, `key.properties` (existing)
- [x] Keystore backed up vào private vault

## Followup (KHÔNG trong PR này)

- REL-MINIFY-001 P1: Enable minifyEnabled + shrinkResources + ProGuard rules
- DOCS-REL-001: Document keystore restore procedure + Play Store upload steps
```


---

# PR #3 — B1.3: Camera permission fallback UX

**Closes:** UX-CAMERA-UX-001 (PR #300)
**Branch:** `fix/ThienPDM/camera-permission-fallback`
**Effort:** 1-2 giờ
**Risk:** Low (UI add-only, không touch logic)
**Skill cite:** `flutter-fix-layout-issues` (cho layout fallback widget)

## Spec

- **What:** Thêm fallback UI khi camera permission denied — anh không có CTA nào → user stuck. Add: error state + "Mở Cài đặt" CTA + retry button.
- **Why:** Audit P0 UX — `_ViewfinderContent.build` error branch (camera_section.dart:511-520) và `_DualViewfinderContent` error branch (line 344-368) hiển thị error text trần, không có cách user recover.
- **Acceptance:**
  - [ ] Permission denied → hiện `CameraPermissionFallback` widget với:
    - Icon + tiêu đề Vietnamese ("Cần quyền truy cập máy ảnh")
    - Subtitle giải thích lý do
    - "Mở Cài đặt" button → mở app settings (anh dùng `app_settings` hoặc `permission_handler`)
    - "Thử lại" button → re-request permission
  - [ ] Permission permanent denied → cùng UI nhưng button text khác ("Mở Cài đặt" thay vì retry)
  - [ ] Widget test cho fallback widget pass

## Implementation steps

### 1. Check current permission package

Đọc `apps/mobile/pubspec.yaml` xem có `permission_handler` hoặc `camera` plugin tự handle. Nếu chưa có:

```bash
cd apps/mobile
flutter pub add permission_handler
```

### 2. Tạo widget fallback

`apps/mobile/lib/features/feed/presentation/widgets/camera_permission_fallback.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionFallback extends StatelessWidget {
  const CameraPermissionFallback({
    super.key,
    required this.permanentlyDenied,
    required this.onRetry,
  });

  final bool permanentlyDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "Cần quyền truy cập máy ảnh",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              permanentlyDenied
                  ? "Anh đã từ chối vĩnh viễn. Mở Cài đặt để cấp lại quyền."
                  : "Cấp quyền để chụp ảnh và chia sẻ với bạn bè.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: permanentlyDenied
                  ? () => openAppSettings()
                  : onRetry,
              icon: Icon(permanentlyDenied
                  ? Icons.settings
                  : Icons.refresh),
              label: Text(permanentlyDenied
                  ? "Mở Cài đặt"
                  : "Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Wire vào camera_section.dart

Tìm error branch `_ViewfinderContent.build` (line 511-520) và `_DualViewfinderContent` (line 344-368). Replace error text với:

```dart
if (cameraState.error?.code == "permission-denied" ||
    cameraState.error?.code == "permission-permanent") {
  return CameraPermissionFallback(
    permanentlyDenied: cameraState.error!.code == "permission-permanent",
    onRetry: () => ref
        .read(appCameraControllerProvider.notifier)
        .initialize(),
  );
}
// fallback: keep existing error text cho non-permission errors
```

### 4. Update `AppCameraController.initialize` (app_camera_controller.dart:25-45)

Map permission errors thành typed AppError với code field rõ ràng:

```dart
final status = await Permission.camera.request();
if (status.isDenied) {
  state = AsyncValue.error(
    AppError.fromUnknown(
      Exception("permission-denied"),
      fallback: "Cần quyền truy cập máy ảnh",
    ),
    StackTrace.current,
  );
  return;
}
if (status.isPermanentlyDenied) {
  state = AsyncValue.error(
    AppError.fromUnknown(
      Exception("permission-permanent"),
      fallback: "Anh đã từ chối quyền vĩnh viễn",
    ),
    StackTrace.current,
  );
  return;
}
```

### 5. Widget test

`apps/mobile/test/features/feed/presentation/widgets/camera_permission_fallback_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meep/features/feed/presentation/widgets/camera_permission_fallback.dart';

void main() {
  testWidgets("CameraPermissionFallback denied — show retry button",
      (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: CameraPermissionFallback(
        permanentlyDenied: false,
        onRetry: () => retried = true,
      ),
    ));

    expect(find.text("Cần quyền truy cập máy ảnh"), findsOneWidget);
    expect(find.text("Thử lại"), findsOneWidget);
    expect(find.text("Mở Cài đặt"), findsNothing);

    await tester.tap(find.text("Thử lại"));
    expect(retried, isTrue);
  });

  testWidgets("CameraPermissionFallback permanent — show settings button",
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CameraPermissionFallback(
        permanentlyDenied: true,
        onRetry: () {},
      ),
    ));

    expect(find.text("Mở Cài đặt"), findsOneWidget);
    expect(find.text("Thử lại"), findsNothing);
    expect(find.textContaining("vĩnh viễn"), findsOneWidget);
  });
}
```

## Verify checklist

```bash
cd apps/mobile

# Static
flutter analyze --no-pub
# Expected: 0 errors

# Test fallback widget
flutter test test/features/feed/presentation/widgets/camera_permission_fallback_test.dart
# Expected: All tests pass
```

Manual emulator test (camera permission flow):
- [ ] Fresh install → camera screen → permission dialog → deny → fallback widget hiện với "Thử lại"
- [ ] Tap "Thử lại" → permission dialog lại → grant → camera preview hoạt động
- [ ] Deny twice + "Don't ask again" → fallback widget hiện với "Mở Cài đặt"
- [ ] Tap "Mở Cài đặt" → mở Android Settings app
- [ ] Grant trong Settings → quay lại app → camera preview hoạt động

## PR description template

```markdown
## Mục đích

Closes UX-CAMERA-UX-001 (audit #300 P0).

Camera permission denied UX trước đây hiển thị error text trần, không CTA → user stuck trong golden path post creation. PR này add fallback widget với retry + "Mở Cài đặt" CTA tùy theo permission state.

## Thay đổi

- New: `features/feed/presentation/widgets/camera_permission_fallback.dart`
- Edit: `features/feed/presentation/camera_section.dart` — wire fallback vào 2 error branches
- Edit: `features/feed/application/app_camera_controller.dart` — map permission errors với typed AppError code
- New: widget test cho fallback (2 case: denied + permanent denied)

## Skill cite

`flutter-fix-layout-issues` (`.claude/skills/flutter-fix-layout-issues/SKILL.md`) — Layout fallback widget pattern.

## Test plan

- [x] `flutter analyze --no-pub`: 0 errors
- [x] Widget test pass (2 case)
- [x] Manual: deny → fallback + Thử lại works
- [x] Manual: permanent deny → fallback + Mở Cài đặt works
- [x] Manual: grant qua Settings → quay lại app → camera works
```


---

# PR #4 — B1.4: Feed Firebase leakage refactor

**Closes:** ARCH-LAYER-001 + ARCH-LAYER-002 (PR #293 — 2 P0 gộp)
**Branch:** `fix/ThienPDM/feed-firebase-leakage`
**Effort:** 3-4 giờ
**Risk:** High (touch hot path, dễ break feed)
**Skill cite:** `flutter-apply-architecture-best-practices` + `flutter-add-widget-test`

## Spec

- **What:** Bỏ tất cả call FirebaseAuth.instance và FirebaseFirestore.instance direct trong feed widget + controller. Replace bằng provider injection theo Pattern #1 (Skeleton) và Pattern #4 (controller). Add widget test verify behavior.
- **Why:** Audit P0 — widget+controller test impossible. Widget gọi FirebaseAuth.instance.currentUser direct (`feed_section.dart:80, home_screen.dart:589`). Controller gọi FirebaseFirestore.instance.collection.doc.id direct (`post_controller.dart:107`).
- **Acceptance:**
  - [ ] `feed_section.dart` + `home_screen.dart` không còn `FirebaseAuth.instance` references
  - [ ] `feed_controller.dart` + `post_controller.dart` không còn `FirebaseAuth.instance` / `FirebaseFirestore.instance` references
  - [ ] `currentUidProvider` được dùng thay cho FirebaseAuth direct
  - [ ] PostRepository gen postId server-side, không client direct
  - [ ] Widget test cho FeedSection pass (override providers, không cần real Firebase)
  - [ ] `flutter analyze` clean
  - [ ] Manual: feed scroll + post creation work như trước

## Implementation steps

### 1. Verify currentUidProvider tồn tại

Grep `currentUidProvider` trong `apps/mobile/lib/features/auth`. Expected: provider trả `Stream<String?>` hoặc `AsyncValue<String?>` từ FirebaseAuth `authStateChanges`. Nếu chưa có, tạo trong `apps/mobile/lib/features/auth/application/auth_providers.dart`.

### 2. Refactor `feed_section.dart` line 80

Trước: dòng gọi `FirebaseAuth.instance.currentUser?.uid`.

Sau: `ref.watch(currentUidProvider).valueOrNull`.

Đồng thời:
- Verify FeedSection là ConsumerWidget (có ref trong build). Nếu là StatelessWidget, đổi extends.
- Remove import firebase_auth từ file.

### 3. Refactor `home_screen.dart` line 589

Same pattern như `feed_section.dart`. `_PostPage` cần đổi từ StatelessWidget sang ConsumerWidget nếu chưa.

### 4. Refactor `feed_controller.dart` line 56

Trước: `final uid = FirebaseAuth.instance.currentUser!.uid;`

Sau: dùng `ref.read(currentUidProvider).valueOrNull` + typed null check → emit UnauthenticatedError state nếu uid null. Loại bỏ force bang để tránh NoSuchMethodError khi race với signOut.

### 5. Refactor `post_controller.dart` line 85, 107, 173

Line 85, 173: replace FirebaseAuth direct với `ref.read(currentUidProvider)`.

Line 107: postId mint move xuống PostRepository:
- PostRepository.submitPost signature trả `Future<String>` (postId).
- FirebasePostRepository tạo doc ref bằng `_db.collection.doc()`, set data, return docRef.id.
- PostController.submit không còn touch FirebaseFirestore.instance direct.

### 6. Verify ARCH-FEED-001 dependency (gộp bonus P1)

Trong `feed_controller.dart` line 31-37, providers postRepositoryProvider và storageRepositoryProvider tự construct FirebaseFirestore.instance. Đó là ARCH-FEED-001 P1.

Trong PR này anh gộp luôn:
- Đổi 2 provider thành stub `throw UnimplementedError` theo Pattern #1 Skeleton.
- `main.dart` ProviderScope.overrides bind với FirebaseFirestore.instance + FirebaseStorage.instance.

→ PR này close ARCH-LAYER-001 + ARCH-LAYER-002 + ARCH-FEED-001 (1 P1 bonus).

### 7. Widget test cho FeedSection

Tạo `apps/mobile/test/features/feed/presentation/feed_section_test.dart`:
- ProviderScope với overrides cho currentUidProvider + feedControllerProvider.
- Test case 1: currentUid match authorId → OwnPostCard renders.
- Test case 2: currentUid khác authorId → PostCard (friend variant) renders.
- Mock Stream.value cho uid override.

### 8. Codegen + analyze

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-pub
flutter test test/features/feed/
```

## Verify checklist

```bash
cd apps/mobile

# Grep verify no Firebase direct in feed widgets+controllers
grep -rn "FirebaseAuth.instance\|FirebaseFirestore.instance" \
  lib/features/feed/presentation lib/features/feed/application
# Expected: 0 hits

# Static check
flutter analyze --no-pub
# Expected: 0 errors

# Test
flutter test test/features/feed/
# Expected: All tests pass
```

Manual emulator test (golden path):
- [ ] Launch + sign-in → feed load posts
- [ ] Scroll → pagination work
- [ ] Tap camera → take photo → caption → share → post visible trên feed
- [ ] Own post: hiển thị OwnPostCard styling
- [ ] Friend post: hiển thị PostCard với reaction button
- [ ] Sign out → sign in lại → state reset đúng

## PR description template

```markdown
## Mục đích

Closes ARCH-LAYER-001 + ARCH-LAYER-002 (audit #293 - 2 P0). Bonus close ARCH-FEED-001 (P1).

Refactor feed module bỏ tất cả Firebase direct calls trong widget + controller, replace bằng Riverpod provider injection theo Pattern #1 Skeleton + Pattern #4 Controller.

## Thay đổi

### Widget layer
- feed_section.dart:80 - FirebaseAuth direct → ref.watch(currentUidProvider).valueOrNull
- home_screen.dart:589 - same
- _PostPage extends ConsumerWidget (từ StatelessWidget)
- Remove firebase_auth import từ 2 file

### Controller layer
- feed_controller.dart:56 - replace FirebaseAuth direct với typed null check + UnauthenticatedError
- post_controller.dart:85,107,173 - replace Firebase direct với ref.read(currentUidProvider) + move postId mint xuống PostRepository.submitPost
- PostRepository.submitPost signature: trả Future<String> (postId)

### Provider layer (ARCH-FEED-001 bonus)
- postRepositoryProvider + storageRepositoryProvider đổi sang stub UnimplementedError theo Pattern #1
- main.dart add override với FirebaseFirestore.instance + FirebaseStorage.instance

### Test
- New: test/features/feed/presentation/feed_section_test.dart - widget test verify own vs friend post UI render đúng với mock currentUidProvider

## Skill cite

- flutter-apply-architecture-best-practices (.claude/skills/.../MEEP-ADAPTER.md) - Riverpod injection pattern
- flutter-add-widget-test (.claude/skills/.../MEEP-ADAPTER.md) - ProviderScope overrides cho test
- Reference architecture: .claude/reference-architectures/auth.md Pattern #1 (Skeleton), #4 (Controller), #5 (State)

## Test plan

- [x] grep FirebaseAuth.instance + FirebaseFirestore.instance trong lib/features/feed/{presentation,application} = 0 hits
- [x] flutter analyze --no-pub: 0 errors
- [x] flutter test test/features/feed/: all pass + new widget test pass
- [x] Manual emulator: golden path post creation + feed scroll + own-vs-friend UI work
- [x] Sign out / sign in: state reset đúng
```


---

# PR #5 — B2.1: Users public profile migration (XL effort)

**Closes:** SEC-USER-SEC-001 (PR #294 P0) + PERF-FRIEND-001 (PR #297 P0)
**Branch:** `fix/ThienPDM/users-public-profile-migration`
**Effort:** 1-2 ngày (XL)
**Risk:** High (touch rule + Functions + client multi-file)

## Spec

- **What:** Tách /users/{uid} doc thành 2 path: full doc (owner+friend) và public/profile subcollection (any authed). 6-step rollout theo audit fix plan.
- **Why:** SEC-USER-SEC-001 leak email; PERF-FRIEND-001 N+1 reads. Sau migration cả 2 close cùng lúc.
- **Acceptance:**
  - [ ] CF trigger denormalize public profile
  - [ ] Migration CF backfill existing
  - [ ] Client đổi read paths
  - [ ] Rule tighten /users read
  - [ ] watchFriends batch query (no N+1)
  - [ ] Rules tests cover 4 case (stranger DENY full, ALLOW public, friend ALLOW, owner ALLOW)
  - [ ] No production downtime nếu rollout đúng order


## Implementation steps (6-step rollout)

> **CRITICAL — rollout order:**
> 1. Deploy CF (trigger + migration)
> 2. Wait public/profile populated cho tất cả users
> 3. Deploy client đọc public/profile
> 4. Deploy rule tighten read
>
> Đảo thứ tự = break friend lookup trong production window.

### Step 1: CF trigger denormalize

Tạo `firebase/functions/src/users/onUserProfileChanged.ts`:
- Trigger onDocumentWritten users/{uid}
- Read after data
- Write 3 field (displayName, avatarUrl, username) xuống subcollection public/profile via merge
- Export trong firebase/functions/src/index.ts

### Step 2: Migration CF (one-shot admin trigger)

Tạo `firebase/functions/src/users/migratePublicProfiles.ts`:
- onCall handler
- Verify request.auth.uid trong admin allowlist (anh hardcode ThienPDM uid)
- Throw HttpsError permission-denied nếu không phải admin
- Iterate /users collection
- Per doc: set /users/{uid}/public/profile với 3 field từ parent
- Return processed count

Sau khi deploy: anh trigger qua Firebase Console hoặc CLI. Verify Firestore Console có /users/{uid}/public/profile populated.

### Step 3: Client thêm watchPublicProfile

`apps/mobile/lib/features/profile/data/firebase_profile_repository.dart`:
- Thêm method watchPublicProfile(String uid) trả Stream<PublicProfile>
- Read /users/{uid}/public/profile snapshots

Tạo model `public_profile.dart` freezed:
- displayName, avatarUrl, username (3 String?)
- fromFirestore factory

### Step 4: Rewrite FirebaseFriendRepository.watchFriends

Trước (audit cite line 49-52):
- Future.wait map per friend uid → N parallel get → re-fire mỗi snapshot emit
- 20 friends = 20 reads × 5 emits/session = 100+ reads

Sau:
- Move N parallel get RA NGOÀI snapshot.asyncMap
- Batch query: chia friendUids thành slice 30 (Firestore whereIn cap)
- Per slice: 1 query .where(FieldPath.documentId, whereIn: slice).get()
- → Maximum 1-2 reads cho cả friend list, không re-fire on each emit

### Step 5: Rewrite searchUser (stranger search)

Trước: collection users where username isEqualTo → FAIL sau rule tighten cho stranger

Sau: collectionGroup query
- collectionGroup public where username isEqualTo searchTerm limit 1
- → Match tất cả /users/{uid}/public/profile docs có username field

Thêm composite index trong `firebase/firestore.indexes.json`:
- collectionGroup public
- fields: username ASC + __name__ ASC

### Step 6: Tighten Firestore rule

Sửa `firebase/firestore.rules` line 61-73:
- match users/{uid}: allow read if isOwner(uid) || isFriend(uid)
- match users/{uid}/public/profile: allow read if isAuthed; allow write if false (server-only)

### Step 7: Rules tests

Sửa `firebase/functions/src/firestore.rules.test.ts`:
- describe block: users/{uid} stranger read
- 4 test cases:
  - stranger DENIED full doc
  - stranger ALLOWED public/profile
  - friend ALLOWED full doc
  - owner ALLOWED full doc


## Verify checklist

```bash
# Rules tests
cd firebase/functions && npm test
# Expected: 4 new tests in users stranger read pass

# Client analyze
cd apps/mobile && flutter analyze --no-pub
# Expected: 0 errors

# Existing tests regression
flutter test
# Expected: all pass
```

Manual production rollout checklist (sau khi merge):
- [ ] Deploy Functions trước (CF trigger + migration)
- [ ] Trigger migration CF qua Firebase Console
- [ ] Spot check Firestore: 5-10 users có /users/{uid}/public/profile
- [ ] Deploy mobile build mới (Step 3-5 client changes)
- [ ] Wait 24-48h cho users update
- [ ] Deploy rule tighten (Step 6 — có thể separate PR)
- [ ] Monitor Firestore permission-denied errors trong Crashlytics

## PR description template

```markdown
## Mục đích

Closes SEC-USER-SEC-001 (audit #294 P0) + PERF-FRIEND-001 (audit #297 P0).

6-step migration tách users doc thành full doc owner+friend only và public subcollection any-authed. Đồng thời eliminate N+1 watchFriends qua batch query.

## Thay đổi

### Functions (TS)
- New: src/users/onUserProfileChanged.ts - denormalize 3 field xuống public/profile
- New: src/users/migratePublicProfiles.ts - one-shot admin backfill
- Edit: src/index.ts - export 2 CF mới

### Client (Dart)
- New: features/profile/data/public_profile.dart - freezed model
- Edit: features/profile/data/firebase_profile_repository.dart - thêm watchPublicProfile
- Edit: features/friend/data/firebase_friend_repository.dart - watchFriends batch (eliminate N+1) + searchUser dùng collectionGroup public

### Rules
- Edit: firestore.rules:61-73 - tighten users read + add public/profile subcollection rule
- Edit: firestore.indexes.json - composite index collectionGroup public/{username}

### Tests
- Edit: firestore.rules.test.ts - 4 test mới

## Rollout order (CRITICAL — không đảo)

1. Deploy Functions
2. Trigger migratePublicProfiles
3. Verify Firestore Console
4. Deploy mobile build
5. Wait 24-48h
6. Deploy rule tighten
7. Monitor Crashlytics

## Test plan

- [x] Rules tests: 4 new tests pass
- [x] flutter analyze: 0 errors
- [x] flutter test: all pass (regression check)
- [x] Manual stranger access: thấy public profile only, không email
- [x] Manual friend access: thấy full profile
- [x] watchFriends: 1 batch query thay vì N parallel (verified Firestore reads counter)
```


---

# PR #6 — B2.2: Feed listener fan-in

**Closes:** PERF-FEED-001 (PR #297 P0)
**Branch:** `fix/ThienPDM/feed-listener-fan-in`
**Effort:** 2-3 giờ
**Risk:** Medium (perf-critical refactor, dễ break feed correctness)
**Skill cite:** `flutter-apply-architecture-best-practices`
**Dependency:** PR #4 (LAYER) merged TRƯỚC

## Spec

- **What:** Reduce 31 concurrent Firestore listeners per home open xuống 2-3 listener tối đa. Replace per-author streams + spaceMemberStream với 1 single batched listener qua `where authorId whereIn`.
- **Why:** Audit P0 — `_watchFriendsFeed` (firebase_post_repository.dart:172-221) tạo `authorIds.take(30)` per-author streams + spaceMemberStream → ~31 concurrent listeners → quota crusher + battery drain. Mỗi reload home = 31 read counters tăng.
- **Acceptance:**
  - [ ] Số Firestore listener active per home open ≤ 3 (verify qua Firestore Console reads counter)
  - [ ] Feed order + pagination behavior giống trước (chronological latest first)
  - [ ] No regression: feed scroll smooth, no skipped frame
  - [ ] Widget test cho feed pass

## Implementation steps

### 1. Strategy

Thay 30 per-author streams bằng 1 query duy nhất qua `where("authorId", whereIn: friendUids)`:
- Firestore whereIn cap = 30 (đủ cho friend count typical)
- Order by createdAt desc + limit cho buffer
- Single snapshot stream → 1 listener thay vì 30

Trường hợp friend count > 30: chia thành 2 batch query song song (max 2 listeners) hoặc paginate qua server-side function.

### 2. Refactor _watchFriendsFeed

`apps/mobile/lib/features/feed/data/firebase_post_repository.dart` line 172-221:

Trước (audit cite):
- friendUids.take(30).map → per-author stream
- spaceMemberStream (line 192-201) — riêng listener
- _mergeStreams (line 224-257) — merge N streams

Sau:
- Single query: collection posts where authorId whereIn allUids (friends + self + spaceMembers)
- orderBy createdAt desc limit _bufferSize
- snapshots → 1 listener
- Bỏ _mergeStreams (không cần merge nữa)

### 3. Handle space member feed

Trước có riêng spaceMemberStream cho posts trong shared space. Sau:
- Tính spaceAuthorUids cùng friendUids
- Combine vào 1 whereIn array (cap 30)
- Hoặc nếu > 30, 1 query riêng cho spaceMembers

### 4. Pagination cursor

Cursor startAfterDocument vẫn hoạt động với single query. Verify:
- Lần đầu: query với limit
- Load more: query với startAfterDocument(lastDoc) + limit

### 5. Update FeedState (nếu ARCH-LAYER-003 chưa fix)

Nếu lastDoc vẫn là DocumentSnapshot type (ARCH-LAYER-003 P1 chưa fix), gộp luôn trong PR này:
- Đổi FeedState.lastDoc thành lastDocId (String?)
- Repository.watchFeed accept startAfterId (String?) thay vì DocumentSnapshot

### 6. Test cho listener count

Tạo `apps/mobile/test/features/feed/data/firebase_post_repository_test.dart` test case:
- Setup FakeFirebaseFirestore với 20 friend uids + 50 posts seeded
- Call _watchFriendsFeed
- Verify: 1 query made (qua FakeFirebaseFirestore introspection nếu support)
- Verify: results ordered by createdAt desc + limit hit


## Verify checklist

```bash
cd apps/mobile

# Static
flutter analyze --no-pub

# Test
flutter test test/features/feed/
```

Manual perf verify:
- [ ] Launch app + open home feed
- [ ] Firebase Console → Firestore → Usage → check listener count
- [ ] Expected: 2-3 listeners (1 feed + 1 reactions + 1 friends) thay vì 31
- [ ] Scroll + reload home 5 lần → reads counter increment hợp lý (không 31× mỗi lần)
- [ ] Feed order: latest posts first, đúng chronological
- [ ] Pagination: load more on scroll works

## PR description template

```markdown
## Mục đích

Closes PERF-FEED-001 (audit #297 P0).

Refactor _watchFriendsFeed bỏ 30 per-author streams + spaceMemberStream → 1 batched whereIn query duy nhất. Giảm 31 concurrent listeners xuống 2-3 listener mỗi home open.

## Thay đổi

- features/feed/data/firebase_post_repository.dart:172-221 - rewrite _watchFriendsFeed dùng single whereIn query
- features/feed/data/firebase_post_repository.dart:224-257 - remove _mergeStreams (không cần merge nữa)
- features/feed/application/feed_state.dart - đổi lastDoc DocumentSnapshot sang lastDocId String (gộp ARCH-LAYER-003 P1)
- Repository.watchFeed signature: startAfterId String? thay vì DocumentSnapshot

## Test plan

- [x] flutter analyze: 0 errors
- [x] flutter test: existing tests pass + new repository test (single query verification)
- [x] Manual Firebase Console: listener count 2-3 thay vì 31
- [x] Manual: feed order chronological + pagination + scroll smooth
```


---

# PR #7 — B3: Integration tests golden path

**Closes:** TEST-E2E-001 (PR #299 P0)
**Branch:** `feat/ThienPDM/integration-tests`
**Effort:** 1 ngày
**Risk:** Low (test add-only, không touch production code)
**Skill cite:** `flutter-add-integration-test`
**Dependency:** PR #1-6 merged TRƯỚC (anh muốn E2E test trên golden path đã stable)

## Spec

- **What:** Setup integration_test infrastructure + viết 4 E2E test cho golden path: auth flow, post creation, feed + reaction, friend request.
- **Why:** Audit P0 — ZERO integration test files. CLAUDE.md baseline yêu cầu "Integration test for login + post + feed loop minimum". Khi anh ship M3, không có cách regression test các flow chính.
- **Acceptance:**
  - [ ] `apps/mobile/integration_test/` folder tồn tại
  - [ ] 4 E2E test file pass khi chạy với Firebase emulator
  - [ ] `test_driver/integration_test.dart` host driver tồn tại
  - [ ] CI workflow `pr-check.yml` chạy integration test (có thể skip nếu setup CI emulator phức tạp — note trong followup)
  - [ ] Helper file `_helpers.dart` provide signInTestUser + reusable utilities

## Implementation steps

### 1. Setup test driver

Tạo `apps/mobile/test_driver/integration_test.dart`:
- Single line: `import "package:integration_test/integration_test_driver.dart" as test; void main() => test.integrationDriver();`

Tạo `apps/mobile/integration_test/_helpers.dart`:
- IntegrationTestWidgetsFlutterBinding.ensureInitialized()
- Firebase emulator setup (FirebaseAuth.useAuthEmulator localhost 9099 + FirebaseFirestore.useFirestoreEmulator localhost 8080)
- signInTestUser helper

### 2. Test 1: Auth flow

`apps/mobile/integration_test/auth_flow_test.dart`:
- Pump app
- Tap đăng nhập button → LoginPage
- Enter email test@meep.dev + password TestPass123
- Tap submit
- pumpAndSettle 3s
- Expect FeedPage / HomePage visible
- Open menu → sign out
- Expect LandingPage

### 3. Test 2: Post creation

`apps/mobile/integration_test/post_creation_test.dart`:
- signInTestUser
- Tap camera icon
- Mock camera grant + fake image
- Enter caption ≤ 30 chars
- Tap share → friend multiselect
- Tap gửi
- Expect upload progress
- Expect navigate về feed
- Expect new post visible

### 4. Test 3: Feed + reaction

`apps/mobile/integration_test/feed_reaction_test.dart`:
- signInTestUser
- Wait feed load (with fake posts seeded via emulator)
- Tap reaction button on first post
- Select emoji
- Expect count increment
- Tap own reaction → remove
- Expect decrement

### 5. Test 4: Friend request

`apps/mobile/integration_test/friend_request_test.dart`:
- Sign-in as user A
- Open FriendListPage
- Search user_b
- Tap gửi lời mời
- Sign-out, sign-in as user B
- Open NotificationBanner / FriendRequestsPage
- Tap accept
- Expect friendship visible cả 2 chiều

### 6. Add CI workflow (optional, có thể followup)

Sửa `.github/workflows/pr-check.yml`:
- Add job: integration_test
- Start Firebase emulator
- flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_flow_test.dart
- (4 file → 4 invocation hoặc loop trong shell)

Nếu CI emulator setup phức tạp: skip CI integration, chỉ chạy local. Document trong followup section của PR.


## Verify checklist

```bash
cd apps/mobile

# Local run prerequisites
firebase emulators:start --only=auth,firestore &

# Run integration test
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart

# Or run all in sequence
for test in integration_test/*.dart; do
  flutter drive --driver=test_driver/integration_test.dart --target=$test
done
```

Expected: all 4 test pass khi Firebase emulator running.

## PR description template

```markdown
## Mục đích

Closes TEST-E2E-001 (audit #299 P0).

Setup integration_test infrastructure + viết 4 E2E test cho golden path theo CLAUDE.md baseline yêu cầu (login + post + feed loop minimum, mở rộng thêm friend request).

## Thay đổi

### Infrastructure
- New: test_driver/integration_test.dart - host driver
- New: integration_test/_helpers.dart - emulator setup + signInTestUser helper

### Test files
- New: integration_test/auth_flow_test.dart
- New: integration_test/post_creation_test.dart
- New: integration_test/feed_reaction_test.dart
- New: integration_test/friend_request_test.dart

### CI (optional)
- Edit: .github/workflows/pr-check.yml - add integration_test job với Firebase emulator
  (Nếu CI setup phức tạp, skip → followup E2E-CI-001)

## Skill cite

flutter-add-integration-test (.claude/skills/.../MEEP-ADAPTER.md) - golden path E2E template với Firebase emulator.

## Test plan

- [x] flutter drive 4 file: all pass với Firebase emulator running
- [x] Test cover golden path: auth + post + feed + friend
- [x] No flaky test (run 3 lần consecutive đều pass)
```


---

# Phase 2 — Self-discipline checklist

> Anh đọc trước khi start PR đầu tiên. Mỗi PR strict follow để tránh regression.

## Trước khi push mỗi PR

- [ ] `flutter analyze --no-pub` clean (0 error)
- [ ] `flutter test` pass (test mới + regression test cũ)
- [ ] Manual emulator test golden path liên quan PR
- [ ] Self-review qua `/review` skill
- [ ] PR description theo template
- [ ] Closes statement chỉ rõ audit issue ID + audit PR reference
- [ ] Branch name format husky valid

## Banned phrases (CLAUDE.md §Banned phrases)

KHÔNG viết trong PR/commit/chat:
- "Should pass" / "probably works" / "I am confident"
- Claim done trước khi run `flutter test`
- "Looks correct" thay vì run test

Nếu chưa run test → state: "run `flutter test test/...` to verify".

## Khi gặp ambiguity

Theo CLAUDE.md §Khi gặp ambiguity:
1. Liệt kê interpretation
2. Hỏi 1 câu rõ (ping em qua chat hoặc skill)
3. Đề xuất default + ask confirm

KHÔNG silent pick. KHÔNG over-engineer (thêm flag/abstraction không yêu cầu).

## Anti-pattern phát hiện trong audit

Tránh re-introduce 9 P0 + 34 P1 đã list:
- KHÔNG `FirebaseAuth.instance.currentUser` direct trong widget/controller
- KHÔNG `allow read: if isAuthed()` cho rule có PII
- KHÔNG raw FirebaseException throw trong repository
- KHÔNG signing release với debug key
- KHÔNG bỏ qua self-verify cho mỗi PR

---

# Followup work (KHÔNG trong Phase 2 P0 scope)

Sau khi 7 PR P0 done, anh có thể fix P1/P2/P3 theo groups trong 99_global_fix_order.md:

| Group | Issues count | Estimated effort |
|---|---:|---|
| G1 Architecture cleanup | 7 P1 | 1-2 ngày |
| G2 Firebase rules hardening | 6 P1 | 1 ngày |
| G3 UX states + permissions | 6 P1 | 2 ngày |
| G4 Performance polish | 6 P1 | 1 ngày |
| G5 Testing + CI | 6 P1 | 1-2 ngày |
| G6 Code quality | 3 P1 | 4 giờ |

P2/P3 backlog 71 issues — fix theo capacity, không block M3.

---

# Audit pass 2 (sau khi 7 PR P0 merged)

Em sẽ chạy mini-audit verify:
- 9 P0 fixed correctly (grep evidence file:line không còn match audit pattern)
- No regression (manual test golden path)
- Self-verify 4-pass (compact version)
- Output: `docs/audits/PASS_2_VERIFICATION.md`

Anh ping em `phase 2 P0 done` để start pass 2.

---

# Reference index

| File | Purpose |
|---|---|
| `docs/audits/99_global_fix_order.md` | Master fix order DAG + Phase 2 plan |
| `docs/audits/A_PHASE_BASELINE_SUMMARY.md` | Phase A → B handoff (referenced by Phase 2 cũng) |
| `docs/audits/01..06_*_audit.md` | Source audit reports với issue evidence chi tiết |
| `.claude/skills/<8 skills>/SKILL.md` | Official skill reference (Flutter + Dart team) |
| `.claude/skills/<8 skills>/MEEP-ADAPTER.md` | Meep-specific override (Riverpod, freezed, mocktail prefer) |
| `.claude/reference-architectures/auth.md` | 11-pattern canonical reference (Pattern #1 Skeleton, #2 Repository, #3 Error model, #4 Controller, #5 State, etc.) |
| `CLAUDE.md` (root) | Domain language + Git workflow + Security guardrails |
| `apps/mobile/CLAUDE.md` | Flutter rules: layering, widget split threshold, design tokens |


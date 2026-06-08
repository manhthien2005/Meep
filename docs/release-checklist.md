# Release Checklist — Meep (Android MVP)

> Runbook trước khi ship M3. Theo đúng thứ tự. Mỗi step có command + cách verify.
> Technical terms / commands giữ tiếng Anh.

## 1. Pre-launch checklist (tick từng dòng)

- [ ] Release keystore đã generate + backup vault (xem §2)
- [ ] `key.properties` có trên máy build / CI secrets đã fill (xem §2)
- [ ] `flutter build appbundle --release` BUILD SUCCESSFUL, ký bằng upload key (xem §5)
- [ ] SHA256 fingerprint upload key đã cập nhật vào `firebase/public/.well-known/assetlinks.json`
- [ ] ProGuard giữ rule OK — smoke test auth + Firestore read + feed render trên release build không crash
- [ ] Crashlytics nhận test crash (xem §5)
- [ ] version bump trong `apps/mobile/pubspec.yaml` (single source — xem §3)
- [ ] App Check enabled (SEC APPCHECK-001)
- [ ] Firestore + Storage rules deploy prod
- [ ] Play Store listing assets sẵn sàng (icon, screenshot, mô tả)
- [ ] Privacy policy URL + Terms URL

## 2. Signing key — generate / backup / restore

### Generate (1 lần duy nhất)

```bash
keytool -genkey -v -keystore release.keystore \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

### key.properties (local, gitignored — KHÔNG commit)

```properties
storeFile=release.keystore
storePassword=<password>
keyAlias=upload
keyPassword=<password>
```

Đặt `release.keystore` tại `apps/mobile/android/release.keystore`, `key.properties` tại `apps/mobile/android/key.properties`.

> `build.gradle.kts` resolve `storeFile` qua `rootProject.file(...)` (rootProject = `apps/mobile/android/`), nên keystore phải nằm ở `android/release.keystore` — khớp với cách CI ghi ở `deploy-production.yml`.

### Backup

- Lưu `release.keystore` + password vào vault (1Password/Bitwarden). **MẤT KEY = không update được app trên Play Store vĩnh viễn.**
- Upload cho CI:

```bash
base64 -w0 release.keystore | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS     # = upload
gh secret set ANDROID_KEY_PASSWORD
```

### Restore (máy mới / CI)

- Local: copy keystore từ vault về `apps/mobile/android/release.keystore`, tạo lại `key.properties`.
- CI: `deploy-production.yml` tự decode từ `ANDROID_KEYSTORE_BASE64`.

### Lấy SHA256 fingerprint (cho assetlinks.json)

```bash
keytool -list -v -keystore release.keystore -alias upload | grep SHA256
```

## 3. Version bump (single source = pubspec.yaml)

- Sửa `apps/mobile/pubspec.yaml` dòng `version: X.Y.Z+BUILD`.
- PATCH cho fix-only, MINOR cho feature (theo Conventional Commits từ tag gần nhất).
- CI `deploy-production.yml` đọc version từ pubspec; nếu truyền `workflow_dispatch.inputs.version` mà lệch pubspec → CI fail (chặn version drift).

## 4. Deploy flow

```bash
git checkout deploy && git merge --no-ff origin/develop
git push origin deploy
# -> deploy-production.yml chạy, approve ở GitHub Environments "production"
```

Verify: Firebase Console deploy timestamp + GitHub release tag = pubspec version.

## 5. Smoke test (sau khi có AAB/APK)

### Verify signing

```bash
flutter build appbundle --release
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab | grep -i "alias\|CN="
# -> phải thấy alias "upload" / CN của upload key, KHÔNG phải androiddebugkey
```

### Verify runtime (R8 không strip nhầm)

- Install APK trên thiết bị Android sạch.
- Sign-up user mới -> take post -> verify feed -> verify home-screen widget refresh -> sign out + in lại.

### Verify Crashlytics

- Trigger `FirebaseCrashlytics.instance.crash()` ở build có collection on -> dashboard nhận trong ~5 phút, stacktrace symbolicate được (nhờ ProGuard `-keepattributes SourceFile,LineNumberTable`).

## 6. Rollback

```bash
gh release delete vX.Y.Z
git checkout deploy && git revert <merge-sha> && git push
# redeploy Functions/Rules từ tag trước:
firebase deploy --only functions,firestore:rules,storage:rules --project meep-prod --force
```

## 7. Play Store upload

1. Play Console -> Production -> Create new release.
2. Upload `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.
3. Google Play App Signing: enroll (Google giữ app signing key; upload key = key của mình).
4. Điền release notes (tiếng Việt), chọn rollout %.
5. Submit review.

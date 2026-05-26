# ADR 0005 — Deep Link Architecture cho Android (Password Reset & Invite)

**Status:** Accepted
**Date:** 2026-05-26
**Author:** ThienPDM

---

## Context

Meep dùng Firebase Dynamic Links (email action links) cho password reset, và custom URI scheme `meep://` cho invite links. Hiện tại deep link handling được implement thủ công qua:

1. `AndroidManifest.xml` — `intent-filter` với `android:autoVerify="true"` cho hai domain:
   - `meep-staging.firebaseapp.com` (Firebase email action handler)
   - `meep-staging.web.app` (Firebase hosting)
2. `app_router.dart` — parse `WidgetsBinding.instance.platformDispatcher.defaultRouteName` lúc cold start
3. `GoRouter.onException` — fallback cho warm start khi GoRouter nhận full URL

**Vấn đề được ghi nhận:**

- `defaultRouteName` chỉ capture được cold start intent. Warm start (app đang chạy) đến qua `GoRouter.onException` — fragile.
- Race condition: `refreshListenable` trigger redirect trước khi route `/__/auth/action` được register trong router → `onException` phải handle.
- Không có `assetlinks.json` verified trên production domain → Android App Links verification sẽ fail trên prod build.

---

## Quyết định

### Ngắn hạn (MVP — hiện tại, đã implement)

Giữ cách tiếp cận thủ công với `defaultRouteName` + `onException` fallback. Lý do:

- App chỉ có 1 deep link use case thực sự cần intercept: **password reset email** (`/__/auth/action?mode=resetPassword`).
- Invite link (`meep://profile/:uid`) là custom scheme, không cần `assetlinks.json` và works via `defaultRouteName`.
- Approach hiện tại đã test kỹ (unit tests cho `authRedirect` 5-state machine, integration test qua cold start path).
- Thêm `app_links` plugin là breaking change cần device testing.

### Dài hạn (post-MVP, khi setup production domain)

Migrate sang `app_links` plugin khi:
1. Production domain `meep.app` được setup.
2. `assetlinks.json` được deploy tại `https://meep.app/.well-known/assetlinks.json`.
3. Device testing có thể được thực hiện trên cả cold start + warm start.

---

## Checklist trước khi deploy production

- [ ] Tạo `assetlinks.json` với SHA-256 fingerprint của production keystore:
  ```json
  [{
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "dev.meep.meep",
      "sha256_cert_fingerprints": ["<PROD_SHA256>"]
    }
  }]
  ```
- [ ] Deploy tại `https://meep.app/.well-known/assetlinks.json` (HTTPS, `Content-Type: application/json`).
- [ ] Update `AndroidManifest.xml`: thêm `android:host="meep.app"` vào `intent-filter`.
- [ ] Update `AppConfig.passwordResetActionUrl` với production domain.
- [ ] Test trên device: cold start từ Gmail link → `/login/reset-password?oobCode=xxx`.
- [ ] Test warm start: app foreground nhận link → GoRouter navigate đúng.
- [ ] Verify Firebase Console > Authentication > Action URL trỏ đúng domain.

---

## Alternatives considered

### `app_links` package

```dart
// main.dart — thay thế defaultRouteName
AppLinks().getInitialLink().then((uri) {
  if (uri != null) router.go('${uri.path}?${uri.query}');
});
AppLinks().uriLinkStream.listen((uri) {
  router.go('${uri.path}?${uri.query}');
});
```

**Ưu:** Handles cả cold + warm start thống nhất. Native Android intent stream.
**Nhược:** Thêm dependency, cần test trên device, breaking change với `defaultRouteName` flow.
**Quyết định:** Defer post-MVP.

### Firebase Dynamic Links SDK

**Deprecated** bởi Google (EOL tháng 8/2025). Không dùng.

---

## References

- [Android App Links verification](https://developer.android.com/training/app-links/verify-android-applinks)
- [app_links package](https://pub.dev/packages/app_links)
- `apps/mobile/lib/core/router/app_router.dart` — current implementation
- `apps/mobile/android/app/src/main/AndroidManifest.xml` — intent-filter config

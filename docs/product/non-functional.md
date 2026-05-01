# Meep — Non-Functional Requirements (NFR)

Yêu cầu phi chức năng cho MVP. Đo được, có acceptance criteria.

> **Scope:** Tier 0 + Tier 0+ MVP. NFR cho Tier 1/2 chỉ list khi unlock.

## 1. Performance

### Mobile app (Flutter)

| Metric | Target | Measurement |
|---|---|---|
| App cold start | <2.5s đến /home (đã login) | Flutter performance overlay |
| App warm start | <1s | Same |
| Camera ready (mở app → viewfinder live) | <1.5s | Manual stopwatch test |
| Capture → preview screen | <500ms | Manual |
| Feed initial load (20 photos) | <3s trên 4G | Flutter integration test với network throttle |
| Feed scroll fps | ≥55 fps (đã đủ smooth) | Flutter DevTools |
| Image thumbnail render từ cache | <100ms | DevTools |

### Backend (Firebase)

| Metric | Target | Source |
|---|---|---|
| Cloud Function cold start | <2s | Firebase logs |
| Cloud Function warm execution | <500ms | Firebase logs |
| Firestore read/write | <300ms p95 | Firebase Performance Monitoring |
| Storage upload 5MB ảnh | <5s trên 4G | Manual test |
| Push notification delivery | <10s từ trigger | Manual test |

### Widget Android

| Metric | Target |
|---|---|
| Widget update sau FCM data message | <30s |
| Widget render thumbnail | <500ms |

## 2. Security

### Authentication

- [ ] Mọi Cloud Function callable check `request.auth` trước business logic
- [ ] Mọi Firestore rule deny by default, allow per resource
- [ ] Token expiration: theo Firebase Auth default (1h ID token, refresh tự động)
- [ ] KHÔNG log password / OTP / token trong logs

### Authorization

- [ ] Owner check: `request.auth.uid == resource.data.authorId` cho posts/diary
- [ ] Friend check: `/friendships/{sortedPair}` exists để xem ảnh bạn share
- [ ] Space member check: `request.auth.uid in resource.data.memberIds` cho space photos
- [ ] Default: nếu không phải owner/friend/member → access denied

### Data protection

- [ ] HTTPS only (Firebase enforce)
- [ ] EXIF location strip server-side trong `onPostCreated` Cloud Function
- [ ] No password plain text (Firebase Auth handle hash)
- [ ] Phone numbers (nếu collect cho contact discovery): hash SHA-256 + salt server-side, không store raw

### Secrets management

- Theo `.windsurf/rules/40-security-guardrails.md`. Không hardcode trong source.

### Input validation

- [ ] Email format validation (Firebase Auth + client)
- [ ] Username: 3-20 ký tự, lowercase + digit + underscore, regex `^[a-z][a-z0-9_]{2,19}$`
- [ ] Caption length ≤ 200 ký tự (Firestore rule enforce)
- [ ] Image upload: MIME `image/*`, size ≤ 10MB (Storage rule enforce)
- [ ] Image dimensions: max 4000x4000 (Cloud Function reject larger để defend decompression bomb)

## 3. Privacy

### PII handling

PII includes: email, phone, display name, photos, captions, friend graph, FCM tokens, IP.

- [ ] **Không log PII** trong production logs (Cloud Functions, app logs). Log IDs only.
- [ ] **Không lưu PII trong Cascade memory** (em đã enforce qua rule 40).
- [ ] Crashlytics: scrub message body / caption trước khi report.
- [ ] Analytics: track event names, không raw user input.

### User control

- [ ] User toggle privacy per Diary entry (private/public)
- [ ] User chọn recipients per photo (all friends / specific friends / Space)
- [ ] User unfriend → 2 chiều remove friend graph
- [ ] User leave Space → không thấy photos space cũ

### Account deletion (Tier 2 — defer)

- Defer post-capstone. Khi implement: GDPR cascade delete user data + photos + diary + friendships.

### Data retention

- Photos: lưu indefinite (cho đến khi user/owner delete)
- Diary entries: lưu indefinite
- Push notifications: ephemeral
- Logs Cloud Functions: 30 days (Firebase default)

## 4. Accessibility

Theo `.windsurf/rules/24-flutter-ui-patterns.md` §"Accessibility (a11y)".

- [ ] Touch target ≥ 48x48 dp
- [ ] Text contrast ratio ≥ 4.5:1 (WCAG AA)
- [ ] `Semantics()` widget cho image, button, custom widget
- [ ] Screen reader (TalkBack) đọc được toàn bộ UI critical path
- [ ] No color-only meaning (vd error không chỉ dùng màu đỏ, kèm icon + text)
- [ ] Support font size system Android (`textScaleFactor`)

## 5. Reliability

| Metric | Target |
|---|---|
| App crash rate | <2% sessions (Crashlytics) |
| Cloud Function error rate | <1% invocations |
| Push notification delivery rate | ≥95% (FCM stat) |
| Photo upload success rate | ≥98% (retry on failure) |

### Error handling

- [ ] Network error → retry button + Vietnamese message
- [ ] Firebase quota exceeded → fallback message "Hệ thống đang bận, thử lại sau"
- [ ] Optimistic UI cho reactions / lightweight ops
- [ ] Offline mode: cache feed last 50 photos, show "Đang offline" banner

### Backup / recovery

- Firestore: Firebase auto-backup daily (30 days retention free tier)
- Storage: no auto-backup, user post = source of truth
- DB schema migration: ADR riêng nếu cần (defer)

## 6. Scalability

MVP capstone scale: target ~100-500 users (4 dev + close friends + giảng viên test).

### Firebase tier

- **Phase 1 (M1-M2):** Spark plan (free)
  - Firestore: 50K reads/day, 20K writes/day → đủ cho 500 users
  - Storage: 5GB total + 1GB/day download → đủ
  - Cloud Functions: 125K invocations/month → đủ
- **Phase 2 (M3 demo):** Upgrade Blaze nếu cần
  - Storage upload Functions yêu cầu Blaze (Feb 2026 update)
  - Setup billing alerts để control cost

### Hot paths optimization

- [ ] Feed query: `where('recipients', 'array-contains', uid).orderBy('createdAt', 'desc').limit(20)` + index
- [ ] Friend list: cache local sau 1 lần fetch, listener cho real-time
- [ ] Widget update: data message FCM (silent push), không poll Firestore

## 7. Usability

### Internationalization

- MVP: **chỉ tiếng Việt** (target user 100% VN).
- i18n setup không cần M1. Nếu unlock Tier 1 → vẫn Vietnamese.
- Post-capstone: support English nếu expand market.

### Onboarding

- Signup 5-screen có hint per step (vd "Mật khẩu của bạn phải dài tối thiểu 8 ký tự")
- Empty state per screen có CTA rõ ràng (vd "Mời bạn bè đầu tiên!")

### Loading / error / empty / data states (4 trạng thái bắt buộc)

Theo `.windsurf/rules/24-flutter-ui-patterns.md`. Mọi screen phải implement.

### Vietnamese UX standard

- Date format: "30 thg 4, 2026" hoặc "30/4/2026"
- Number format: 1,000.50 (en-US) acceptable cho MVP
- Currency: KHÔNG có (Meep MVP free)
- Time format: relative ("2h trước", "Hôm qua") trong feed; absolute trong detail

## 8. Compliance / Legal

### Capstone academic

- [ ] Source code public GitHub (anh confirm OK)
- [ ] License: MIT hoặc Apache 2.0 (em recommend MIT)
- [ ] README có Acknowledgments cho dependencies
- [ ] Submission deadline: theo syllabus capstone (anh check)

### Data protection (informal MVP)

- [ ] Privacy policy ngắn (~1 trang) trong Settings → "Chính sách quyền riêng tư"
- [ ] Terms of service ngắn (~1 trang) trong Settings → "Điều khoản dịch vụ"
- [ ] Defer: GDPR full compliance (account deletion cascade), COPPA (under 13)

## 9. Observability

### Monitoring

- [ ] Firebase Performance Monitoring (Flutter SDK)
- [ ] Firebase Crashlytics (crash + non-fatal errors)
- [ ] Firebase Analytics (key events: signup, post, react, widget_tap)
- [ ] Cloud Function logs (Firebase Console)

### Alerting

- Defer post-MVP. Anh/dev manual check Firebase Console.

## 10. Maintenance

- [ ] Codebase ≤ 5000 lines Flutter (Tier 0 + 0+ estimate)
- [ ] Files ≤ 300 lines (rule 20)
- [ ] Test coverage business logic ≥ 80%, UI ≥ 50% (rule 30)
- [ ] Documentation up-to-date với code (Phase 0 docs maintained)
- [ ] No `// TODO` without linked issue

## Liên quan

- **Security detail:** [`../architecture/security-model.md`](../architecture/security-model.md)
- **Rules cấm hardcoding:** `.windsurf/rules/40-security-guardrails.md`
- **Testing discipline:** `.windsurf/rules/30-testing-and-verification.md`
- **UI accessibility:** `.windsurf/rules/24-flutter-ui-patterns.md`

# 05_security_firebase_audit

## meta
- repo: Meep
- root: D:/meep-audit-05-sec
- branch: audit/ThienPDM/05-security-firebase
- date: 2026-06-07
- mode: review-only
- audit_focus: firebase_rules_and_privacy_boundary
- modified_files_allowed:
  - docs/audits/05_security_firebase_audit.md
- read_baseline:
  - docs/audits/00_inventory_map.md
  - CLAUDE.md (root) — §Security Guardrails, §Domain (Caption ≤ 200 char Firestore cap)
  - apps/mobile/CLAUDE.md — §Layering
  - .claude/reference-architectures/auth.md — Pattern #11 rules helpers

## precheck
- git_status_before:
  - `?? docs/audits/` (output dir new)
  - `?? tmp/audit/ThienPDM/05-security-firebase` (audit staging, not part of repo)
- existing_user_changes: no (matches baseline `00_inventory_map.md §baseline_git_status`; `M apps/mobile/pubspec.lock` absent because this is a fresh worktree clone for the audit)
- target_report_preexisting_dirty: no (file created in this pass)

## commands
| cmd | status | notes |
|---|---|---|
| `git rev-parse --show-toplevel` + `git status --short` + `git branch --show-current` | ok | precheck |
| Read `firebase/firestore.rules` (353 lines) | ok | per-collection scan |
| Read `firebase/storage.rules` (43 lines) | ok | per-path scan |
| Read `firebase/firestore.indexes.json` | ok | 10 composite indexes |
| Read `firebase/firebase.json` | ok | runtime + emulator config |
| Read `firebase/functions/src/index.ts` + per-module CFs (settings, friend, space, feed, chat, notification) | ok | callable + trigger surface |
| Read `firebase/functions/src/firestore.rules.test.ts` + `storage.rules.test.ts` | ok | 76 + 27 tests |
| Read `apps/mobile/lib/main.dart` + `firebase_options.dart` | ok | emulator gating + apiKey |
| Read `apps/mobile/lib/features/notification/{application,data}` | ok | FCM token mgmt |
| Read `apps/mobile/lib/features/widget/application/widget_data_service.dart` + `WidgetDataStore.kt` + `WidgetSyncWorker.kt` | ok | widget cache + native Firestore |
| Read `apps/mobile/android/app/src/main/AndroidManifest.xml` + `build.gradle.kts` | ok | permissions + signing |
| Read `.github/workflows/{pr-check,develop-staging,deploy-production}.yml` | ok | CI secrets path |
| `git ls-files` filter for sensitive patterns (`\.env`, `google-services\.json`, `firebase-adminsdk`, `\.keystore`, `\.jks`, `key\.properties`, `service.account`) | ok | only `.env.example` committed |
| `grep "if true"` firestore.rules + storage.rules | ok | 1 hit in `/usernames` (intentional) |
| `grep App Check` apps/mobile, firebase, android | ok | 0 hits → APPCHECK-001 |
| `grep FirebaseFirestore.instance` in non-`data/` mobile dirs | ok | layering breach hotspots logged |

## coverage
- firestore.rules per-collection: checked (users, usernames, posts, posts/reactions, friendships, friend_requests, blocks, spaces, space_members, conversations, conversations/messages, diary, default-deny — every `match` block read line-by-line)
- storage.rules per-path: checked (posts, avatars, diary, default-deny — 4 blocks, all read)
- firebase/functions auth/input/idempotency: checked (every `onCall` + `onDocumentCreated/Updated/Deleted` in `src/{settings,friend,space,feed,chat,notification}` read; zod schemas + auth guards + idempotency markers cross-referenced)
- client Firebase usage boundary: partial (sampled `feed`, `notification`, `chat`, `widget`, `settings`, `auth` modules; grep across `lib/features/**/presentation/**` flagged 3 widget-layer `FirebaseAuth.instance` reads in `feed_section.dart:80`, `feed_section.dart:589`, `home_screen.dart:589` — layering breach but not security-critical; logged as no_issue_notes since they read public uid only)
- AndroidManifest permissions: checked (`AndroidManifest.xml` complete read — only INTERNET present)
- secrets / committed credentials: checked (`git ls-files` matches `.env.example` only; .gitignore has full exclusion list for `.env`, service accounts, keystores, `google-services.json`)
- CI deploy secrets: checked (all 3 workflows read; secrets via `${{ secrets.X }}` masking, no `echo`)
- account deletion / reauth: checked (`deleteAccount.ts` cascade complete; client `delete_account_dialog.dart` triggers reauth via `reauthenticateWithGoogle/Password`)
- FCM token ownership: checked (`firebase_notification_repository.dart` + `_fcm.ts` + rule `/users/{uid}/fcmTokens` cross-referenced)
- notification/widget cached privacy: checked (`widget_data_service.dart` + `WidgetDataStore.kt` + `WidgetSyncWorker.kt` full read; `clearData()` defined but call-site grep negative on logout path)
- App Check: checked (grep `appCheck|App Check|PlayIntegrity|activateAppCheck` returned 0 hits in mobile/Android/Functions — confirmed absent)

## blockers_summary
| id | sev | area | files | short |
|---|---|---|---|---|
| APPCHECK-001 | P0 | client+config | apps/mobile/lib/main.dart | App Check chưa activate → API key + Firestore/Storage/Functions không có abuse guard ở prod |
| USER-SEC-001 | P0 | rules | firebase/firestore.rules:62 | Any authed user reads /users/{uid} đầy đủ — leak email + private profile fields |
| STORAGE-001 | P1 | rules | firebase/storage.rules:9 | /posts/{uid} read by ANY authed → bypass friend boundary qua URL |
| STORAGE-002 | P1 | rules | firebase/storage.rules:31 | /diary/{uid} read by ANY authed → "private" diary readable qua URL guess |
| POST-SEC-001 | P1 | rules | firebase/firestore.rules:147 | /posts update không có field whitelist + không cap caption size → bypass 200-char rule khi edit |
| CHAT-SEC-001 | P1 | rules | firebase/firestore.rules:288 | /conversations create cho phép arbitrary participantIds → stranger spam DM victim |
| AUTH-SEC-001 | P1 | functions | firebase/functions/src/settings/deleteAccount.ts:148 | deleteAccount CF không enforce server-side reauth — client-only gate bypass được khi gọi trực tiếp |

## issues

### ISSUE APPCHECK-001

- sev: P0
- blocker: yes
- area: client+config
- files:
  - `apps/mobile/lib/main.dart`
  - `apps/mobile/lib/firebase_options.dart`
  - `firebase/firebase.json`
- loc: main.dart:52-60 (init block) + firebase_options.dart:55-61 (apiKey)
- symbols:
  - `Firebase.initializeApp` (no `FirebaseAppCheck.activate` follow-up)
  - `DefaultFirebaseOptions.android.apiKey`
- evidence: `await Firebase.initializeApp(options:` (main.dart:54) — không có `FirebaseAppCheck.activate` follow-up; grep `App Check|appCheck|PlayIntegrity|activateAppCheck` = 0 hits across apps/mobile, firebase/, android/
- access_path: any client (browser/script/repacked APK) gọi Firestore/Storage/Functions với staging API key `AIzaSyCyuhye-Hm0qnnM4s0f2tNuz4ErWxfr600` (hardcode trong `firebase_options.dart:56`) → server không phân biệt request từ app build chính thức vs request từ source khác → mọi rule chỉ dựa vào `request.auth` mà không có app-attestation layer; quota path mở cho automated traffic
- risk: data leak (unauthenticated probe /usernames `if true` → user enumeration) + financial (Function invocation cost từ automated traffic) + abuse (callable CF invocation rate không có app-binding) — CLAUDE.md §Security Guardrails đặt App Check làm "Production blocker"
- fix: trong `main.dart` ngay sau `Firebase.initializeApp`, gọi `await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.playIntegrity)` (release build) + `AndroidProvider.debug` cho `kDebugMode`. Bật enforce trên Firebase Console cho Firestore/Storage/Functions production project trước khi xóa `if: false` ở `.github/workflows/deploy-production.yml:103,134`
- authority: CLAUDE.md §Security Guardrails "App Check: Production blocker nếu chưa enable (Play Integrity provider)"; tmp/05_security_firebase_audit_prompt_v2.md §Audit Checklist "App Check" group
- test: viết integration test trong `apps/mobile/integration_test/app_check_test.dart` verify `FirebaseAppCheck.instance.getToken()` resolve thành non-empty string trong debug build; thêm rules-test deny case trong `firestore.rules.test.ts` cho request thiếu App Check token (sau khi rule enforce)
- deps: none

### ISSUE USER-SEC-001

- sev: P0
- blocker: yes
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 61-73 (entire /users/{uid} block — read)
- symbols:
  - `match /users/{uid}` → `allow read: if isAuthed()`
- evidence: `allow read: if isAuthed();` (firestore.rules:62) cho /users/{uid} — không có check `isOwner(uid) || isFriend(uid)`; doc chứa `email` field (rule `create` line 64 enforce `keys().hasAll(['uid', 'email', 'displayName', 'username', 'createdAt'])`)
- access_path: bất cứ user nào sau khi signup (email signup không enforce verify, hoặc Google login) → đọc `/users/<otherUid>` → nhận về `email` + `displayName` + `username` + `avatarUrl` + `friendCount` + `postCount`. Kết hợp với USERNAME-SEC-001 (P2) — bất kỳ client iterate `/usernames/{name}` (public read) lấy uid, rồi `/users/{uid}` lấy email + profile
- risk: data leak — email là PII; CLAUDE.md §PII handling list "email, phone, displayNames" là PII Meep. Friend graph privacy CLAUDE.md §Domain "Friend graph private" cũng bị compromise (friendCount leak relationship size)
- fix: tách read rule thành minimal-profile + full-profile. Option A (đề xuất): `allow read: if isOwner(uid) || isFriend(uid)` cho doc gốc, tạo subcollection `/users/{uid}/public/profile` chứa CHỈ `displayName + avatarUrl + username` cho lookup stranger. Option B (rule-only): dùng `resource.data` field-mask không khả thi (Firestore rules không filter field per-read) → bắt buộc tách doc.
  Implementation chi tiết (Option A):
  1. **Firestore rule:** đổi line 62 `allow read: if isAuthed();` → `allow read: if isOwner(uid) || isFriend(uid);`. Thêm match block `/users/{uid}/public/profile` với `allow read: if isAuthed(); allow write: if false;` (server-only).
  2. **CF onUserCreated trigger** (mới): trigger `onDocumentWritten('/users/{uid}')` — denormalize `displayName + avatarUrl + username` từ /users xuống /users/{uid}/public/profile. Hoặc update `signUp.ts` server-side. Đơn giản hơn: dùng CF `onDocumentWritten('/users/{uid}')` để keep public/profile sync với parent doc khi displayName/avatarUrl thay đổi.
  3. **Client repository:** `FirebaseUserRepository.watchProfile(uid)` (auth/data/firebase_user_repository.dart:46) + `FirebaseProfileRepository.watchUserProfile(uid)` (profile/data/firebase_profile_repository.dart:80) + `FirebaseFriendRepository.searchUser(username)` (friend/data/firebase_friend_repository.dart:13) + `FirebaseFriendRepository.watchFriends(uid)` batch reads /users/{fuid} (friend/data/firebase_friend_repository.dart:49-52) — TẤT CẢ đọc `/users/{uid}` trực tiếp. Tách: thêm method `watchPublicProfile(uid)` đọc /users/{uid}/public/profile (minimal: displayName/avatarUrl/username) cho stranger lookup; giữ `watchProfile`/`watchUserProfile` cho self+friend only.
  4. **Touch points cần đổi (verified grep):** `firebase_user_repository.dart` (watchProfile, getProfile, isUsernameAvailable), `firebase_profile_repository.dart` (getUserProfile, watchUserProfile, updateProfile, updateAvatar, removeAvatar), `firebase_friend_repository.dart` (searchUser dùng .where('username') — stranger search, cần switch sang public/profile subcollection query hoặc CF), notification CFs `_helpers.ts readDisplayName` (đọc /users để denormalize tên — server-side OK vì Admin SDK bypass rules, KHÔNG cần đổi).
  5. **Migration:** existing /users docs cần backfill /users/{uid}/public/profile. Viết 1-shot CF `migratePublicProfiles` (admin-triggered) chạy collection-group iterate /users → batch.set(/users/{uid}/public/profile). Idempotent qua set merge.
  6. **Rollout order:** (a) deploy CF trigger + migration; (b) wait until public/profile populated; (c) deploy client đọc public/profile; (d) deploy rule tighten read. Đảo ngược thứ tự sẽ break friend lookup trong window.
- authority: CLAUDE.md §Security Guardrails "Owner check: `isOwner(uid) := isAuthed() && request.auth.uid == uid`. Never just check 'is authenticated' when you really mean 'is owner / is friend'"; tmp prompt §Friend graph privacy checklist item "Read /users/{uid} cho stranger → return profile minimal hay block hoàn toàn"
- test: thêm `firestore.rules.test.ts` test case `describe('/users/{uid} — stranger read')` với 4 assertion: owner allow, friend allow, stranger DENY, unauth DENY. Verify field-mask hoặc minimal-doc structure post-fix
- deps: blocks USERNAME-SEC-001 mitigation (P2)

### ISSUE STORAGE-001

- sev: P1
- blocker: no
- area: rules
- files:
  - `firebase/storage.rules`
- loc: 7-15 (/posts/{uid}/{allPaths=**} block)
- symbols:
  - `match /posts/{uid}/{allPaths=**}` → `allow read: if request.auth != null`
- evidence: `allow read: if request.auth != null;` (storage.rules:9) — không enforce friend của uid hoặc post-author check
- access_path: User A đăng post với image URL `https://firebasestorage.googleapis.com/.../posts/{authorUid}/{postId}/photo.jpg`. URL leak qua: (a) friend share link cho non-friend, (b) device cached URL trong shared_preferences widget cache, (c) Firestore /users/{uid}/feed/{postId} fan-out doc còn lại sau unfriend (race với cleanup). Bất cứ authed user nào có URL = đọc full-resolution photo, bypass Firestore friend boundary
- risk: data leak — photo là PII top priority (CLAUDE.md §PII handling "photos/captions" + §Project Context "personal photos"). Firestore rule layer (/posts) enforce friend boundary nhưng Storage rule không mirror — defense-in-depth fail
- fix: enforce friend check ở Storage qua `firestore.get()` lookup: `allow read: if request.auth != null && (request.auth.uid == uid || exists(/databases/(default)/documents/friendships/$(pairId)))`. Cần helper compute pairId tương tự firestore.rules. Hoặc đơn giản hơn: enforce author-only read + buộc client luôn fetch URL qua `getDownloadURL()` rồi proxy qua signed URL từ CF (heavy lifting cho MVP — chọn rule-side check)
- authority: CLAUDE.md §Storage checklist "Read requires authentication" minimal — nhưng §PII handling "PII bar HIGH" require friend boundary mirror ở Storage. Defense-in-depth pattern: Firestore rules là source of truth nhưng Storage rule không được lax hơn
- test: thêm `storage.rules.test.ts` test `describe('Storage /posts/{uid}/ — friend boundary')` với 3 case: owner read OK, friend read OK (require seed /friendships/{pairId} doc), stranger read FAIL. Hiện chỉ test /avatars/ — gap rộng
- deps: pair với STORAGE-002

### ISSUE STORAGE-002

- sev: P1
- blocker: no
- area: rules
- files:
  - `firebase/storage.rules`
- loc: 28-35 (/diary/{uid}/{allPaths=**})
- symbols:
  - `match /diary/{uid}/{allPaths=**}` → `allow read: if request.auth != null`
- evidence: `allow read: if request.auth != null;` (storage.rules:30) cho /diary/{uid} — trong khi `firestore.rules` line 329-331 enforce `authorUid == request.auth.uid || (privacy == 'public' && isFriend(...))`. Storage không mirror.
- access_path: User A tạo diary với `privacy='private'`, ảnh upload vào `diary/{aUid}/{entryId}.jpg`. URL leak (Crashlytics, log) → bất kỳ authed user nào đọc được ảnh dù diary marked private
- risk: data leak — diary explicit `privacy='private'` semantic bị compromise ở Storage layer. Cao hơn STORAGE-001 vì user expressly chọn private
- fix: enforce author-only read: `allow read: if request.auth != null && request.auth.uid == uid`. Friend "public" diary case: hoặc giữ author-only ở Storage và buộc client luôn check Firestore rule trước; hoặc query Firestore từ Storage rule (heavy — skip). Đề xuất: chốt author-only read cho /diary/ (defense in depth conservative)
- authority: CLAUDE.md §Security Guardrails "Photos/captions" là PII top tier; firestore.rules:329-331 đã model semantic — Storage phải mirror
- test: `storage.rules.test.ts` thêm `describe('Storage /diary/{uid}/')` với owner allow + non-owner (friend hoặc stranger) DENY
- deps: pair STORAGE-001

### ISSUE POST-SEC-001

- sev: P1
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 147-150 (/posts/{postId} update block)
- symbols:
  - `match /posts/{postId}` → `allow update`
- evidence: `allow update: if isOwner(resource.data.authorId)` (line 147) — không có `affectedKeys().hasOnly([...])` whitelist, không re-check `caption.size() <= 200`, không protect `createdAt`
- access_path: author client gọi `postRef.update({caption: '<5MB string>'})` — rule pass vì authorId không đổi; create rule enforce 200-char nhưng update bypass. Tương tự, author override `createdAt`/`memberIds`/`audienceUids` post-creation
- risk: weak validation; bypass domain rule (CLAUDE.md §Domain Caption "Firestore rule cap is 200"). Worst case: author edit caption thành PII của victim (impersonation in feed) hoặc inflate doc size đẩy lên quota; tương đồng /diary update rule line 338-342 vốn có re-check size
- fix: mirror /diary update pattern: thêm `affectedKeys().hasOnly(['caption', 'updatedAt'])` whitelist + re-check `request.resource.data.caption.size() <= 200` khi `'caption' in affectedKeys`. Bảo vệ `authorId/createdAt/audienceType/audienceUids/spaceIds/memberIds/imageUrl/backImageUrl/frontImageUrl` immutable
- authority: CLAUDE.md §Domain "Caption ... Firestore rule cap is 200" + auth.md Pattern #11 "diff().affectedKeys() để allow chỉ specific field update"; /users/{uid} update line 70-72 đã model immutable-fields pattern
- test: viết `firestore.rules.test.ts describe('/posts — author cannot bypass caption cap on update')` — seed post với caption='ok', author try update caption với 1000 chars → assertFails
- deps: none

### ISSUE CHAT-SEC-001

- sev: P1
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
  - `apps/mobile/lib/features/chat/data/firebase_conversation_repository.dart`
- loc: firestore.rules:288-289 (create); conversation_repository.dart:99-138 (getOrCreateConversation)
- symbols:
  - `match /conversations/{conversationId}` → `allow create`
  - `FirebaseConversationRepository.getOrCreateConversation`
- evidence: `participantIds.hasAll([request.auth.uid])` (line 289) — chỉ check caller có trong participantIds, KHÔNG check caller có friendship/space-membership với uid khác
- access_path: authed user A (KHÔNG phải friend của B) gọi `conversations.doc(pairIdOf(A,B)).set({type:'direct', participantIds:[A.uid, B.uid], ...})` → rule pass. Sau đó `conversations/{id}/messages.set({senderId:A.uid, text:'...'})` — message rule line 310-322 check `isParticipant(conversationId)` (đã true vì A trong participantIds), `senderId == auth.uid`, `text.size() <= 500` → pass. CF `onMessageCreated` → FCM push B → B nhận unsolicited DM từ non-friend. Locket-parity feature semantic của Meep là chat chỉ giữa friends.
- risk: privacy boundary (Meep "intimate friends only" semantic) + unsolicited-message vector. Friend graph privacy CLAUDE.md §Domain "Friend = mutual accepted friendship" — chat phải gate qua friend graph
- fix: enforce friend hoặc space-member ở create. Cho `type='direct'` (2-person): `participantIds.size() == 2 && exists(/databases/(default)/documents/friendships/$(conversationId))` (conversationId là pairId sorted). Cho `type='space'`: `exists(/databases/(default)/documents/spaces/$(conversationId))` + caller is member. `acceptFriendRequest.ts:107-137` + `createSpace.ts:157-169` đã tạo conversation atomically qua CF nên client `getOrCreateConversation` fallback line 122-138 chỉ là idempotent retry, có thể chấp nhận tightening rule
- authority: tmp prompt §Per-collection ownership "/conversations/{...} + /conversations/{...}/messages/{...}: read by participant only" + CLAUDE.md §Domain "Friend = mutual" — conversation predicated trên friend graph
- test: `firestore.rules.test.ts describe('/conversations — stranger create denied')` — Alice + Bob KHÔNG friendship, Alice try create `/conversations/{aliceUid}_{bobUid}` → assertFails
- deps: none

### ISSUE CHAT-SEC-002

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 294-302 (/conversations update block)
- symbols:
  - `match /conversations/{conversationId}` → `allow update`
- evidence: `affectedKeys().hasOnly(['lastMessage', 'lastMessageAt', 'lastSenderId', 'lastReadAt'])` (firestore.rules:296-302) — field whitelist nhưng KHÔNG có value validation cho từng field: `lastMessage` không có type+size check, `lastSenderId` không enforce `== request.auth.uid`, `lastMessageAt` không type-check timestamp, `lastReadAt` không shape-check (map<uid, timestamp>).
- access_path: participant A (legitimate friend) gọi `conversations.doc(pairId).update({lastMessage: '<1MB string hoặc fake content>', lastSenderId: B.uid, lastMessageAt: <arbitrary timestamp>})` — rule pass vì A trong participantIds + affectedKeys hợp lệ. Inbox preview của B sẽ render "B đã gửi: <content A đặt>" (impersonation in inbox UI). Hoặc A set `lastReadAt[B] = future timestamp` → B's unread badge bị "đè" về 0 cho đến khi có message thực sự mới hơn timestamp giả đó. Bloat doc qua 1MB lastMessage cũng possible nhưng impact thấp vì doc rebuild.
- risk: defense-in-depth — UI integrity (inbox preview hiển thị sai sender) + minor doc bloat. Không leak data nhưng vi phạm invariant "lastMessage source = sender của message gần nhất". CHAT module dùng denormalized fields này cho inbox list render trực tiếp không lookup messages.
- fix: thêm value validation trong allow update block, mirror /posts pattern:
  - `(!affectedKeys().hasAny(['lastMessage']) || (request.resource.data.lastMessage is string && request.resource.data.lastMessage.size() <= 500))`
  - `(!affectedKeys().hasAny(['lastSenderId']) || request.resource.data.lastSenderId == request.auth.uid)`
  - `(!affectedKeys().hasAny(['lastMessageAt']) || request.resource.data.lastMessageAt is timestamp)`
  - `(!affectedKeys().hasAny(['lastReadAt']) || request.resource.data.lastReadAt is map)`
  - `lastReadAt` keyed by uid — nếu enforce shape thì cần check key set là subset participantIds; rule expression hỗ trợ được qua `keys()` API.
- authority: firestore.rules:316-318 đã model pattern type+size check cho `senderDisplayName` trong /messages create — mirror sang /conversations update; tmp prompt §Field validation "Server-set fields protected ... client KHÔNG ghi được từ phía client" (sender field thuộc nhóm này về spirit)
- test: `firestore.rules.test.ts describe('/conversations update — tamper guards')` — 4 assertion: participant A update lastSenderId=B.uid → assertFails (post-fix); A update lastMessage với 1000 chars → assertFails; A update lastMessageAt=string → assertFails; A update lastMessage hợp lệ → assertSucceeds
- deps: pair với CHAT-SEC-001 (cùng module /conversations); test add vào cùng describe block đề xuất TESTING-SEC-001

### ISSUE AUTH-SEC-001

- sev: P1
- blocker: no
- area: functions
- files:
  - `firebase/functions/src/settings/deleteAccount.ts`
- loc: 147-149 (auth check entry point)
- symbols:
  - `deleteAccount` onCall handler
- evidence: `if (!request.auth)` (deleteAccount.ts:148) — chỉ check authed, KHÔNG kiểm `request.auth.token.auth_time` để enforce reauth window. Comment line 135-137 thừa nhận "CF chỉ check `request.auth` exists, không enforce recent-login (Firebase SDK enforce)" — nhưng Firebase Auth SDK reauth-window chỉ enforce cho native SDK calls (`user.delete()`), KHÔNG áp dụng cho callable CF.
- access_path: id_token long-lived (~1h) còn valid khi user step away từ unlocked device, hoặc khi token được kế thừa qua shared device. Callable endpoint `https://asia-southeast1-meep-staging.cloudfunctions.net/deleteAccount` chấp nhận bất kỳ valid token nào → cascade-delete chạy mà không cần password re-prompt. Client UI gate (DeleteAccountDialog reauth) bị bypass khi gọi CF qua bất kỳ con đường nào khác (CLI test, mistakenly-cached session, etc.).
- risk: account loss (irreversible cascade) khi token compromise window > 5 phút sau last auth; CLAUDE.md §Security Guardrails "Destructive ops (delete account, change email) phải reauth"
- fix: enforce reauth window server-side. Trong `deleteAccount` thêm check sau auth gate: `const authTime = request.auth.token.auth_time as number; const now = Math.floor(Date.now() / 1000); if (now - authTime > 5 * 60) { throw new HttpsError('failed-precondition', 'Reauth required'); }`. Apply tương tự cho future destructive CFs (changeEmail).
- authority: CLAUDE.md §Security Guardrails "Reauth: Destructive ops phải reauth"; Firebase Auth docs "auth_time claim"
- test: viết `firebase/functions/src/__tests__/deleteAccount.test.ts` (path Vitest mới) với 2 case — token freshly issued (auth_time = now) → ok; token age > 5min → throw `failed-precondition`. Use `firebase-functions-test` v2 với authData override
- deps: none

### ISSUE USERNAME-SEC-001

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 102-110 (/usernames/{username})
- symbols:
  - `match /usernames/{username}` → `allow read: if true`
- evidence: `allow read: if true;` (firestore.rules:104) — unauthenticated read pass; comment justify "username availability is public info, checked pre-auth during signup"
- access_path: unauthenticated client gọi `firestore.collection('usernames').doc('<any_name>').get()` → response `{ uid: '<otherUid>' }` mà không cần auth token. Lặp lại với từng username known → mapping username→uid mà không có rate-limit (App Check chưa enable per APPCHECK-001). Sau khi USER-SEC-001 fix, cần authed để read /users/{uid}, nhưng signup không enforce verification → khả năng combine pipeline username → uid → user fields vẫn open.
- risk: information disclosure — uid không phải secret strictly, nhưng kết hợp với USER-SEC-001 hoặc các collection có owner-by-uid sẽ extend reach của username enumeration. Defense in depth issue.
- fix: 2 option — (A) restrict read by exact-match query only: rule không hỗ trợ query-shape guard, nên không khả thi. (B) Move availability check vào CF `checkUsernameAvailable` onCall, return `{available: bool}` without exposing uid. Cập nhật `sign_up_controller.dart` gọi CF thay vì direct read. Trade-off: cold-start latency cho signup flow nhưng đáng — chỉ chạy 1 lần/user.
- authority: tmp prompt §Default-deny posture "Mọi `allow read|write` đều có điều kiện?" + "KHÔNG có `if true` ở bất cứ rule nào?"
- test: sau khi switch sang CF, viết `__tests__/checkUsernameAvailable.test.ts` verify CF không leak uid trong response; xóa `/usernames` `if true` rule và thêm rules test deny unauth read
- deps: pair với USER-SEC-001 (cùng story user enumeration)

### ISSUE USERNAME-SEC-002

- sev: P3
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 105-109 (/usernames create + delete rules)
- symbols:
  - `match /usernames/{username}` → `allow create` + `allow delete`
- evidence: `allow create: if isAuthed() && request.resource.data.uid == request.auth.uid;` (firestore.rules:105-106) — chỉ check `uid` field trong /usernames doc khớp `request.auth.uid`. KHÔNG check `/users/{auth.uid}.username == username` (path param). User có username="alice" có thể tạo `/usernames/<any_string>` với `{uid: auth.uid}`. Rule không enforce "username trong /usernames doc match username trong /users doc của cùng uid".
- access_path: user A (username="alice") authed → gọi `firestore.collection('usernames').doc('bob').set({uid: A.uid})` → rule pass vì `request.resource.data.uid == A.uid`. Doc `/usernames/bob = {uid: A.uid}` được tạo. Khi user X sau này signup với username="bob", `sign_up_controller.dart` check `/usernames/bob` → exists → "bob taken". X bị block khỏi username "bob" dù A không thực sự own nó. Lặp lại với nhiều username → squat hàng loạt.
- risk: namespace squatting; impact thấp cho MVP vì user base nhỏ + username không phải resource đắt + delete account cascade chỉ xóa username trong /users/{uid}.username (line 234-245 deleteAccount.ts) — squatted usernames mồ côi forever. Defense-in-depth issue.
- fix: enforce cross-doc invariant trong create rule:
  ```
  allow create: if isAuthed()
    && request.resource.data.uid == request.auth.uid
    && username == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.username;
  ```
  Tradeoff: thêm 1 `get()` call mỗi create (rule eval budget 10 get/exists per request) — chấp nhận được vì /usernames create chạy 1 lần mỗi user lifecycle (signup). Cảnh báo: pattern này yêu cầu /users doc tồn tại trước /usernames doc. Signup flow hiện tại của `sign_up_controller.dart` tạo /users trước /usernames — verify lại order.
  
  Alternative (cleaner): move toàn bộ /usernames write vào CF `claimUsername` onCall function. Server validate username match + atomic transaction `/users + /usernames`. Khử client-side write hoàn toàn — rule `allow create, delete: if false`. Pair với USERNAME-SEC-001 fix (move /usernames read sang CF).

  **CAVEAT pass-6:** Proposed `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.username` SẼ FAIL signup flow hiện tại. `FirebaseUserRepository.createProfile` (auth/data/firebase_user_repository.dart:14-27) write `/users/{uid}` + `/usernames/{username}` trong cùng Firestore batch. Rule eval cho /usernames create KHÔNG thấy uncommitted /users write trong cùng batch (Firestore rule transaction isolation) → get() return null → rule fail → signup break. **Bắt buộc** split sang 2-step write (create /users TRƯỚC, commit, rồi /usernames sau) HOẶC switch hoàn toàn sang CF `claimUsername` alternative — không có cách giữ batch atomicity với cross-doc rule check.
- authority: tmp prompt §Per-collection ownership "/usernames create với uid match"; CLAUDE.md §Security Guardrails "Never just check 'is authenticated' when you really mean 'is owner / is friend'" — owner ở đây là "user thực sự sở hữu username string"
- test: `firestore.rules.test.ts describe('/usernames create — squat protection')` — user A (username='alice' trong /users) try create `/usernames/bob` với `{uid: A.uid}` → assertFails post-fix; A create `/usernames/alice` → assertSucceeds
- deps: pair với USERNAME-SEC-001 (cùng module /usernames); shared CF approach trong alternative fix có thể bundle

### ISSUE AUTH-SEC-002

- sev: P1
- blocker: yes (kết hợp USER-SEC-001 = email PII leak path)
- area: client
- files:
  - `apps/mobile/lib/main.dart`
  - `apps/mobile/lib/features/auth/` (toàn bộ flow signup)
- loc: main.dart (Firebase.initializeApp không kèm verifyEmail enforce); grep `sendEmailVerification|emailVerified` trong features/auth = 0 hits
- symbols:
  - `FirebaseAuth.instance.currentUser.sendEmailVerification` (NOT CALLED)
  - `User.emailVerified` (NOT CHECKED)
- evidence: grep `sendEmailVerification|emailVerified|email_verified|isEmailVerified` trên `apps/mobile/lib/features/auth/` returns 0 files. Signup flow tạo Firebase Auth user + Firestore /users doc với email string mà KHÔNG enforce verification. Anyone có thể signup với email không sở hữu (ví dụ `victim@example.com`) → /users doc tạo với email field → nếu USER-SEC-001 chưa fix, có thể đọc back email của uid khác qua /users/{uid}.
- access_path: bất kỳ ai signup với arbitrary email → tạo /users doc chứa unverified email → nếu chính email đó là email thật của user khác đang dùng app, có duplicate user records hoặc enumeration path. Quan trọng hơn: kết hợp USER-SEC-001 (stranger reads /users) → unverified email PII của signup user bị expose qua /usernames → uid → /users.email pipeline.
- risk: PII unverified — email field trong /users không có guarantee ownership. CLAUDE.md §PII handling "email là PII". CLAUDE.md §Security Guardrails "Never just check 'is authenticated' when you really mean 'is owner'" — auth-only is not enough cho email PII.
- fix: 2 lớp defense:
  1. **Client-side gate signup completion:** sau `createUserWithEmailAndPassword`, ngay lập tức gọi `await user.sendEmailVerification()`. Block continue-to-app flow cho đến khi `user.reload(); user.emailVerified == true`. Thêm verify-email screen vào router; redirect signup → verify-email khi `!emailVerified`.
  2. **Server-side enforce ở rule + CF:** trong `/users` create rule, thêm `&& request.auth.token.email_verified == true` (Firebase Auth token tự inject claim). Áp dụng cho mọi CF callable destructive (deleteAccount, blockUser, acceptFriendRequest, createSpace) tương tự: check `request.auth.token.email_verified` đầu function.
- authority: CLAUDE.md §Security Guardrails "isOwner(uid) := isAuthed() && request.auth.uid == uid. Never just check 'is authenticated'"; Firebase Auth docs "email_verified token claim"; pair với USER-SEC-001 đóng pipeline email enumeration
- test:
  - widget test verify signup flow redirect sang verify-email screen khi `emailVerified == false`;
  - rules test `firestore.rules.test.ts describe('/users create — email verification gate')` — assert token với `email_verified: false` create /users → assertFails post-fix;
  - vitest CF `deleteAccount.test.ts` — gọi với token email_verified=false → throw `failed-precondition` post-fix.
- deps: pair với USER-SEC-001 — defense in depth cho email PII boundary

### ISSUE FRIEND-SEC-002

- sev: P2
- blocker: yes (cho USER-SEC-001 rollout — implementation blocker)
- area: client
- files:
  - `apps/mobile/lib/features/friend/data/firebase_friend_repository.dart`
- loc: 13-26 (`searchUser` method)
- symbols:
  - `FirebaseFriendRepository.searchUser(username)` → `_firestore.collection('users').where('username', isEqualTo: query).limit(1).get()`
- evidence: `searchUser` (firebase_friend_repository.dart:13-26) chạy collection query `/users where username == X`. Stranger lookup (user A search user B chưa friend) — query phải pass /users read rule. Hiện tại rule `allow read: if isAuthed()` (firestore.rules:62) cho phép, nhưng SAU KHI USER-SEC-001 fix tighten read rule thành `isOwner(uid) || isFriend(uid)`, collection query KHÔNG thể prove tĩnh "mọi doc match query là friend của caller" → Firestore engine reject toàn query với PERMISSION_DENIED. Friend search BREAK.
- access_path: USER-SEC-001 fix deploy theo rollout order đề xuất (CF migrate → client public/profile → rule tighten). Bước rule tighten breaks friend search vì client chưa migrate sang query `/users/{uid}/public/profile`. UX: user mở "Tìm bạn" → search "alice" → snapshot error PERMISSION_DENIED. Nếu fix release trước migration done → app crash UX.
- risk: implementation correctness — USER-SEC-001 rollout step (c) "deploy client đọc public/profile" PHẢI bao gồm refactor searchUser TRƯỚC step (d) rule tighten. Không phải security risk độc lập, là blocker dependency.
- fix: 2 option:
  1. **Server-side search qua CF `searchUserByUsername`:** client gọi callable, server query `/users` qua Admin SDK (bypass rule), return minimal profile (`{uid, displayName, avatarUrl, username}`). Pair tự nhiên với USERNAME-SEC-001 CF refactor.
  2. **Client query collection-group `/users/{uid}/public/profile` filtered by username:** yêu cầu /users/{uid}/public/profile có index trên username field + denormalized. Phức tạp hơn CF approach vì cần composite index.
  
  Đề xuất option 1 (CF) — đơn giản + match USERNAME-SEC-001 pattern.
- authority: phụ thuộc USER-SEC-001 fix; tmp prompt §Friend graph privacy "stranger lookup pre-friend"
- test: integration test `friend_search_test.dart` post-fix: stranger search "alice" → return UserProfile minimal (no email/no counters). Vitest CF `searchUserByUsername.test.ts` verify response shape.
- deps: blocks USER-SEC-001 rollout step (c)

### ISSUE CI-SEC-001

- sev: P3
- blocker: no
- area: ci
- files:
  - `.github/workflows/pr-check.yml`
- loc: 153-160 (firestore-rules job)
- symbols:
  - `firestore-rules` job → `firebase emulators:exec ... npm run test:rules || echo "::warning::..."`
- evidence: `pr-check.yml:160` có fallback `|| echo "::warning::Rules tests skipped (chưa có script test:rules — sẽ enable khi có rules tests đầu tiên)"`. Nếu `test:rules` script không tồn tại HOẶC fail vì lý do gì khác, job vẫn pass với warning. CI không enforce rules tests.
- access_path: dev push PR với rules change → CI emit warning nhưng pass → merge sang develop → silent regression rules. Tương đương zero coverage cho firestore.rules trong CI. TESTING-SEC-001 propose thêm describe blocks nhưng nếu fallback `||` còn đó, coverage không enforce được.
- risk: defense-in-depth CI gate; toàn bộ TESTING-SEC-001 work bị undermined nếu script chạy fail silently. Sau khi rules tests có sẵn, phải REMOVE fallback.
- fix: 2 step:
  1. Xóa `|| echo "::warning::..."` line 160 → job fail khi `test:rules` script missing hoặc tests fail.
  2. Verify `firebase/functions/package.json` có `"test:rules": "vitest run firestore.rules.test.ts storage.rules.test.ts"` (đã có test files trong src/ — `firestore.rules.test.ts`, `storage.rules.test.ts`).
- authority: CLAUDE.md §Verification Before Claiming Done "Linter clean, Build OK, Tests pass" — CI fallback `||` violates evidence rule; tmp prompt §CI/CD hardening
- test: smoke test sau fix — verify CI job fail khi `npm run test:rules` exit non-zero (cố intentionally break 1 rules test → push PR → CI red); chuẩn CI workflow.
- deps: blocks TESTING-SEC-001 — nếu không xóa fallback, test coverage không enforce được dù viết tests.

### ISSUE REACTION-SEC-001

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 163-168 (/posts/{postId}/reactions/{reactorUid} update)
- symbols:
  - `allow update` whitelist
- evidence: `hasOnly(['emoji', 'createdAt', 'reactorName', 'reactorAvatarUrl'])` (line 165) — `reactorName` và `reactorAvatarUrl` không có type check + size cap; emoji upper bound chỉ check `emoji.size() > 0` (line 162) — không cap upper.
- access_path: reactor (1 friend của author) update reaction với `reactorName: '<10000-char string đặt tên giống user khác>'` hoặc `reactorAvatarUrl: 'https://example.com/<arbitrary>.gif'`. Author thấy display name không khớp profile reactor trong reaction list sheet — tampered UI
- risk: impersonation in feed UI; defense-in-depth weakness. Không leak data nhưng tampered display
- fix: thêm type+size validation: `(!affectedKeys().hasAny(['reactorName']) || (request.resource.data.reactorName is string && request.resource.data.reactorName.size() <= 50))` tương tự `senderDisplayName` rule conversation messages line 316-318. Cap emoji upper bound 32 chars (ZWJ emoji family) tương tự /spaces iconEmoji line 252.
- authority: firestore.rules:316-318 đã model pattern `senderDisplayName.size() <= 50`; createSpace.ts:14-16 chốt 32-char cap cho ZWJ emoji
- test: `firestore.rules.test.ts describe('/reactions update — name tamper')` — reactor try update với name 1000 chars → assertFails
- deps: none

### ISSUE WIDGET-SEC-001

- sev: P3
- blocker: no
- area: client
- files:
  - `apps/mobile/lib/features/widget/application/widget_data_service.dart`
  - `apps/mobile/lib/features/settings/application/settings_controller.dart`
- loc: widget_data_service.dart:112-117 (clearData); settings_controller.dart:78-115 (logout), 127-158 (deleteAccount)
- symbols:
  - `WidgetDataService.clearData`
  - `SettingsController.logout` (has clearData)
  - `SettingsController.deleteAccount` (missing clearData)
- evidence: `Future<void> clearData() async` (widget_data_service.dart:112) defined. `settings_controller.dart:94-99` logout DOES call `await ref.read(widgetDataServiceProvider).clearData();` wrapped trong try/catch. `settings_controller.dart:127-158` deleteAccount KHÔNG có clearData call (chỉ deleteFcmToken + resetForLogout + auth.deleteAccountCascade).
- access_path: deleteAccount flow trên shared device không clear local widget cache trước khi gọi server cascade. CF xóa Firestore + Storage server-side → URL trong cache trở thành 404 → next WidgetSyncWorker tick (~15min) sẽ render placeholder. Trong window ~15min sau deleteAccount, widget vẫn render last-cached image cho user kế tiếp signin same device.
- risk: privacy polish — cache window ~15min sau deleteAccount; impact thấp vì (a) logout path đã clear, (b) server đã xóa data source nên cache stale → URL invalid → next sync render placeholder. Original pass-1 claim "logout missing clearData" SAI — đã được fix trước pass 1.
- fix: trong `SettingsController.deleteAccount` (sau line 150 `resetForLogout`, trước `auth.deleteAccountCascade`), thêm `try { await ref.read(widgetDataServiceProvider).clearData(); } catch (_) {}` — mirror logout pattern line 95-99.
- authority: CLAUDE.md §Security Guardrails "Widget cache cleanup khi sign-out?" checklist item; tmp prompt §Notification/widget cached privacy
- test: `apps/mobile/test/features/settings/settings_controller_test.dart` thêm case "deleteAccount clears widget cache" — mock WidgetDataService, verify `clearData` called trước `auth.deleteAccountCascade`. Logout test có sẵn pattern.
- deps: none

### ISSUE USER-SEC-002

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 69-72 (/users/{uid} update whitelist)
- symbols:
  - `allow update` immutable-fields check
- evidence: `!request.resource.data.diff(resource.data).affectedKeys()` (line 70) blocks immutable fields nhưng `displayName`/`avatarUrl`/`bio` mutable không có length cap.
- access_path: authed user gọi `users.doc(myUid).update({displayName: '<1MB string>'})` → rule pass. Doc bloat → other users đọc /users/{myUid} (USER-SEC-001 hiện cho phép) tải về 1MB junk → DoS qua quota / bandwidth
- risk: weak validation; quota abuse + UI rendering crash (RenderParagraph overflow). Lower priority vì user cap mình thiệt hại
- fix: thêm size+type check trên displayName: `(!affectedKeys().hasAny(['displayName']) || (request.resource.data.displayName is string && request.resource.data.displayName.size() >= 1 && request.resource.data.displayName.size() <= 50))`. Tương tự cho `avatarUrl` (URL cap 500 chars), `bio` (300 chars). Cùng pattern /spaces update line 245-255
- authority: firestore.rules:245-255 đã model pattern type+size guard cho /spaces update; tmp prompt §Field validation "String length cap (displayName, etc.)"
- test: `firestore.rules.test.ts describe('/users update — displayName length')` — owner try update displayName 1000 chars → assertFails
- deps: none

### ISSUE TESTING-SEC-001

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/functions/src/firestore.rules.test.ts`
  - `firebase/functions/src/storage.rules.test.ts`
- loc: file-level coverage (rules.test.ts 76 tests across users/usernames/posts/friend_requests/blocks/diary; storage.rules.test.ts 27 tests across /avatars/)
- symbols:
  - missing `describe('/conversations'`
  - missing `describe('/spaces'`
  - missing `describe('/space_members'`
  - missing `describe('/friendships'`
  - missing `describe('/posts/{postId}/reactions'`
  - missing `describe('/users/{uid}/fcmTokens'`
  - missing `describe('/users/{uid}/notifications'`
  - missing storage `/posts/` block
  - missing storage `/diary/` block
- evidence: grep `describe\(` trong rules.test.ts hits 6 collections; rules có 13+ collections per `firestore.rules`. Storage test chỉ /avatars/ — `/posts/` + `/diary/` gap.
- access_path: regression risk — rule edit (vd thêm field whitelist cho /posts update fix POST-SEC-001) không có test catch → silent breaking change. Production rule có thể drift khỏi spec.
- risk: testing coverage gap; không phải data leak hiện tại nhưng amplify mọi P0/P1 fix risk
- fix: thêm 4 describe block trong firestore.rules.test.ts: `/conversations` (get vs list split per rule comment line 268-282 — quan trọng), `/spaces` (member read OK, non-member denied), `/space_members` (member read), `/posts/{postId}/reactions` (reactor create, author read, stranger denied). Thêm 2 block trong storage.rules.test.ts: `/posts/{uid}/` (sau STORAGE-001 fix verify), `/diary/{uid}/` (sau STORAGE-002 fix verify). Cấu trúc đã có pattern tốt trong `/users` + `/diary` test block — copy.
- authority: auth.md Pattern #10 "Test stratification — Rules: owner/friend/stranger/unauth matrix cho mỗi collection có user data"; CLAUDE.md §Testing & Verification "Firestore / Storage rules: Rules unit tests in `firebase/functions/test/rules.test.ts`"
- test: `firebase/functions/package.json:scripts.test:rules` chạy cả 2 file; sau fix CI `pr-check.yml:154-160` sẽ catch regression
- deps: depends on (verify after) POST-SEC-001, CHAT-SEC-001, STORAGE-001, STORAGE-002 — viết test xanh trước, sửa rule, test đỏ → re-write, test xanh

### ISSUE DIARY-SEC-001

- sev: P2
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 338-345 (/diary update + delete)
- symbols:
  - `allow update` (diary) — missing privacy enum check + missing type guard on content/moodCaption
- evidence: `request.resource.data.content.size() <= 20` (line 341) — KHÔNG có `is string`/`is list` guard trước `.size()` (test file line 640 hint content là list of "blocks"). Update KHÔNG validate `privacy in ['private', 'public']` (create line 335 có).
- access_path: author update với `content: 'not-a-list'` → `.size()` trả char count not block count → rule có thể accidentally pass với data shape sai. Hoặc set `privacy = 'invalid'` → read rule line 330 `privacy == 'public'` không match nên friend không đọc được — actual impact minimal nhưng inconsistent state.
- risk: weak validation; không direct data leak (read rule line 329-331 fail-safe denial nếu privacy != 'public') nhưng inconsistent data shape có thể crash diary list render nếu repository parse fail
- fix: mirror create rule pattern trong update — thêm `request.resource.data.privacy in ['private', 'public']` và type guard `request.resource.data.content is list` (nếu list) hoặc `is string` (nếu string). Đối chiếu với `lib/features/diary/data/diary_entry.dart` freezed model để xác định actual type rồi enforce.
- authority: firestore.rules:335 create rule đã model `privacy in ['private', 'public']` — update phải mirror; tmp prompt §Field validation "Type check"
- test: `firestore.rules.test.ts describe('/diary update — privacy enum')` author try update với privacy='leaked' → assertFails
- deps: none

### ISSUE PERM-001

- sev: P3
- blocker: no
- area: client
- files:
  - `apps/mobile/android/app/src/main/AndroidManifest.xml`
- loc: 1-4 (uses-permission block)
- symbols:
  - missing `RECEIVE_BOOT_COMPLETED`
- evidence: `<uses-permission android:name="android.permission.INTERNET"` (line 3) — chỉ INTERNET. KHÔNG có RECEIVE_BOOT_COMPLETED. `WidgetSyncWorker.kt:304` sử dụng `PeriodicWorkRequestBuilder<WidgetSyncWorker>` với `ExistingPeriodicWorkPolicy.KEEP`.
- access_path: device reboot → WorkManager mất periodic work nếu chưa request RECEIVE_BOOT_COMPLETED → home-screen widget không refresh cho đến user mở app lại. Không phải security issue, là functionality bug nhưng nằm trong audit scope §Android permissions
- risk: minor functionality (widget stale post-reboot); KHÔNG phải security issue chính. Per tmp prompt "Có cần RECEIVE_BOOT_COMPLETED cho widget WorkManager auto-restart?" checklist.
- fix: thêm `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />` vào AndroidManifest.xml line 4. WorkManager tự handle reschedule. Đồng thời thêm `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` (Android 13+) cho FCM foreground — FlutterLocalNotificationsPlugin sẽ request runtime nhưng cần declared.
- authority: tmp prompt §Android permissions checklist; Android WorkManager docs "Periodic work and device reboot"
- test: manual — device reboot, verify widget refresh trong 15min không cần mở app
- deps: none

### ISSUE FRIEND-SEC-001

- sev: P3
- blocker: no
- area: rules
- files:
  - `firebase/firestore.rules`
- loc: 174-180 (/friendships/{pid})
- symbols:
  - `match /friendships/{pid}` — không enforce pid format
- evidence: `match /friendships/{pid}` (line 174) — rule không validate `pid == pairId(members[0], members[1])`. CF `acceptFriendRequest.ts:90-93` enforce sorted pairId nhưng rule không guard nếu doc tạo qua future path khác.
- access_path: hypothetically, CF compromised hoặc admin SDK gọi sai → tạo `/friendships/randomDocId` với `members:[uid1, uid2]` — rule pass. Read by member OK, nhưng `isFriend(uid)` helper line 22-26 `exists(/databases/.../friendships/$(pairId(...)))` không match → friend graph broken silently.
- risk: defense in depth — current threat model giả sử CF không bypass, nhưng rule không enforce invariant
- fix: thêm `request.auth.uid in resource.data.members` đã có. Cộng `pid == pairId(resource.data.members[0], resource.data.members[1])` helper. Helper `pairId` đã định nghĩa line 17-19. Hiện rule chỉ allow CF create — rule "create: if false" line 177 → đầu vào duy nhất qua admin SDK. Vẫn cộng read guard `resource.data.members.size() == 2 && pid == pairId(members[0], members[1])` để enforce invariant downstream.
- authority: auth.md Pattern #11 "pairId deterministic format enforce ở rule"; tmp prompt §Friend graph privacy "pairId deterministic format (`min_max`) enforce ở rule"
- test: `firestore.rules.test.ts describe('/friendships — pid format')` admin SDK seed friendship với pid không match members → owner read → expected behavior là DENY post-fix
- deps: none

### ISSUE FUNC-SEC-001

- sev: P3
- blocker: no
- area: functions
- files:
  - `firebase/functions/src/settings/blockUser.ts`
  - `firebase/functions/src/friend/acceptFriendRequest.ts`
  - `firebase/functions/src/space/createSpace.ts`
  - `firebase/functions/src/space/updateSpace.ts`
  - `firebase/functions/src/space/kickMember.ts`
  - `firebase/functions/src/space/leaveSpace.ts`
  - `firebase/functions/src/space/transferOwnership.ts`
  - `firebase/functions/src/settings/deleteAccount.ts`
- loc: file-level (zod schema declarations)
- symbols:
  - `z.object({...})` (no `.strict()`)
- evidence: `const blockUserSchema = z.object({` (blockUser.ts:11) — không có `.strict()`. Zod default mode strip unknown properties without throw — client có thể gửi excess keys với silent acceptance.
- access_path: client gửi `{targetUid: 'x', __proto__: {...}, someJunk: 'huge'}` → zod parse trả `{targetUid: 'x'}` ok. Không exploit hiện tại nhưng prototype-pollution-style attack vector future-proof concern. Logs có thể bloat từ raw `request.data` nếu logger.info log full payload (nhưng deleteAccount.ts:161 log chỉ `{uid}` nên ok).
- risk: defense-in-depth weakness; không P0/P1 hiện tại
- fix: gắn `.strict()` lên tất cả zod schema: `z.object({targetUid: z.string()...}).strict()`. Zod sẽ throw `ZodError` nếu có unknown key, CF `safeParse` catch và throw `invalid-argument`. Apply pattern cho 8 schemas trên + sendFriendRequestSchema in index.ts:24
- authority: tmp prompt §Functions input validation "Reject excess properties?"; zod docs `.strict()` mode
- test: thêm `__tests__/blockUser.test.ts` `it('rejects excess properties')` — gọi với `{targetUid: 'x', evil: 'y'}` → expect `invalid-argument` throw
- deps: none

### ISSUE FUNC-SEC-002

- sev: P3
- blocker: no
- area: functions
- files:
  - `firebase/functions/src/space/onSpaceMemberAdded.ts`
  - `firebase/functions/src/space/onSpaceMemberRemoved.ts`
- loc: onSpaceMemberAdded.ts:12-17 (idempotent caveat comment)
- symbols:
  - `onSpaceMemberAdded` trigger
  - `onSpaceMemberRemoved` trigger
- evidence: `Idempotent caveat: same as Added — at-least-once delivery. MVP accepted.` (onSpaceMemberRemoved.ts:12; same comment block onSpaceMemberAdded.ts:12-17 "Trade-off accepted cho MVP") — acknowledged weakness, not fixed.
- access_path: Firestore v2 trigger contract đảm bảo at-least-once delivery. Same event fire 2 lần → user spaceCount tăng 2 thay vì 1. Không security risk, là consistency issue
- risk: data integrity (UI-displayed spaceCount drift). Comment ghi rõ "MVP accepted" — chấp nhận được nhưng audit phải flag
- fix: triển khai event marker pattern khi dev tới T8 follow-up. Path comment đề xuất: `/users/{uid}/space_count_events/{spaceId}` doc as marker; transaction check exists → skip increment. Hoặc switch sang derived field: compute spaceCount qua client query `space_members where uid == X` collection-group count thay vì denormalized counter.
- authority: code comment line 14-18 acknowledges; Firebase Functions docs §Reliability "at-least-once delivery"
- test: `__tests__/onSpaceMemberAdded.test.ts` simulate trigger fire 2x cho cùng event → assert spaceCount = 1 (not 2)
- deps: none

## fix_order

### batch_1_p0
- APPCHECK-001 — App Check activate + enforce trên 3 services trước MVP launch
- USER-SEC-001 — Tách public profile subcollection + tighten /users read rule

### batch_2_p1
- CHAT-SEC-001 — Friend gate /conversations create (pair với /messages chain)
- STORAGE-001 + STORAGE-002 — Mirror friend boundary ở Storage cho /posts + /diary (cùng pattern)
- POST-SEC-001 — Field whitelist + caption cap trên /posts update
- AUTH-SEC-001 — auth_time check trong deleteAccount CF
- AUTH-SEC-002 — Email verification enforce (client gate + rule + CF token claim check) — added pass-6

### batch_3_p2
- USERNAME-SEC-001 — Move username lookup vào CF (depends USER-SEC-001)
- REACTION-SEC-001 — Type+size guard trên /reactions update
- CHAT-SEC-002 — Value validation trên /conversations update (lastMessage size, lastSenderId == auth.uid, lastReadAt shape) — added pass-3
- FRIEND-SEC-002 — Move searchUser sang CF `searchUserByUsername` (blocks USER-SEC-001 rollout step c) — added pass-6
- USER-SEC-002 — Length cap displayName trong /users update
- DIARY-SEC-001 — Privacy enum + type guard trên /diary update
- TESTING-SEC-001 — Coverage gap fix cuối cùng (cover toàn bộ collection rule mới fix)

### batch_4_p3
- WIDGET-SEC-001 — clearData call trong SettingsController.deleteAccount (logout đã có) — demoted P2→P3 pass-2
- PERM-001 — RECEIVE_BOOT_COMPLETED + POST_NOTIFICATIONS manifest
- FRIEND-SEC-001 — pid invariant guard /friendships
- FUNC-SEC-001 — `.strict()` trên mọi zod schema
- FUNC-SEC-002 — Event marker idempotent cho onSpaceMember{Added,Removed}
- USERNAME-SEC-002 — Enforce /users/{uid}.username match /usernames/{name}.uid trong create rule (added pass-4)
- CI-SEC-001 — Xóa `|| echo warning` fallback trong pr-check.yml firestore-rules job (blocks TESTING-SEC-001) — added pass-6

## test_plan_after_fix

- `APPCHECK-001`: integration test `apps/mobile/integration_test/app_check_test.dart` verify token resolve; rules test deny request without `X-Firebase-AppCheck` header sau enforce
- `USER-SEC-001`: rules test `describe('/users/{uid} — stranger read')` matrix owner+friend allow / stranger+unauth deny; client integration test friend search returns minimal profile
- `STORAGE-001`: storage.rules test `describe('Storage /posts/{uid}/ — friend boundary')` owner+friend allow / stranger deny (seed /friendships pre-test)
- `STORAGE-002`: storage.rules test `describe('Storage /diary/{uid}/')` author allow / non-author deny
- `POST-SEC-001`: rules test author try update caption with 1000 chars → assertFails; author try update authorId → assertFails
- `CHAT-SEC-001`: rules test stranger create conversation without friendship → assertFails; friend create OK
- `AUTH-SEC-001`: vitest `deleteAccount.test.ts` mock authData with stale `auth_time` → throws `failed-precondition`
- `USERNAME-SEC-001`: vitest `checkUsernameAvailable.test.ts` verify response only `{available: bool}`; rules test unauth read /usernames → assertFails post-fix
- `REACTION-SEC-001`: rules test reactor update reactorName with 1000 chars → assertFails
- `CHAT-SEC-002`: rules test participant A update `lastSenderId: B.uid` → assertFails post-fix; A update `lastMessage` với 1000 chars → assertFails; A update hợp lệ (lastMessage ≤ 500 chars, lastSenderId == A.uid) → assertSucceeds
- `WIDGET-SEC-001`: widget test `settings_controller_test.dart` mock WidgetDataService; verify `clearData()` invoked trong deleteAccount path trước `auth.deleteAccountCascade()` (logout path đã có test sẵn — chỉ cần mirror)
- `USER-SEC-002`: rules test owner update displayName 1000 chars → assertFails
- `TESTING-SEC-001`: thêm describe blocks; verify CI `pr-check.yml firestore-rules` job pass
- `DIARY-SEC-001`: rules test author update privacy='invalid' → assertFails
- `PERM-001`: manual reboot device → verify widget refresh trong 15min
- `FRIEND-SEC-001`: rules test admin SDK seed friendship với pid sai → member read assertFails
- `FUNC-SEC-001`: vitest each callable gọi với excess keys → throw `invalid-argument`
- `FUNC-SEC-002`: vitest simulate trigger 2x cùng event → assert spaceCount idempotent
- `USERNAME-SEC-002`: rules test user A (username='alice') try create /usernames/bob với uid=A → assertFails post-fix; A create /usernames/alice → assertSucceeds. Hoặc nếu chuyển sang CF `claimUsername`, vitest test direct rule create → assertFails (deny client write)
- `AUTH-SEC-002`: widget test `signup_controller_test.dart` mock FirebaseAuth, verify `sendEmailVerification()` called sau `createUserWithEmailAndPassword` + redirect tới verify-email screen khi `!emailVerified`. Rules test create /users với token `email_verified=false` → assertFails. Vitest CF `deleteAccount.test.ts` với token email_verified=false → throw `failed-precondition`.
- `FRIEND-SEC-002`: integration test `friend_search_test.dart` post-fix: stranger search "alice" qua CF → return UserProfile minimal (no email field, no friendCount). Vitest CF `searchUserByUsername.test.ts` verify response shape không leak PII.
- `CI-SEC-001`: smoke test verify CI fail-mode — intentionally break 1 rules test, push PR → CI job firestore-rules đỏ. Verify `package.json` có script `test:rules`.

## no_issue_notes

### Default-deny posture
- `firestore.rules:347-350` catch-all `match /{document=**} { allow read, write: if false; }` — OK
- `storage.rules:38-40` catch-all deny — OK
- `if true` audit: chỉ 1 hit `firestore.rules:104` /usernames (intentional per comment, flagged as USERNAME-SEC-001)

### Per-collection ownership
- `/users/{uid}/notifications/{notifId}` line 79-89 — owner read; client update CHỈ field `read` qua `affectedKeys().hasOnly(['read'])` + `is bool` type check; create/delete server-only. OK
- `/users/{uid}/fcmTokens/{tokenId}` line 96-98 — `allow read, write: if isOwner(uid)`. Token ownership tied to path uid. OK
- `/users/{uid}/feed/{postId}` line 91-94 — owner read only; client create/update/delete denied (CF onPostCreated fan-out only). OK
- `/users/{uid}/private/{docId}` line 75-77 — owner read+write. OK
- `/friendships/{pid}` line 174-180 — read+delete by member; create+update CF only. OK (FRIEND-SEC-001 P3 chỉ là defense-in-depth)
- `/friend_requests/{requestId}` line 183-206 — well-modeled: create by sender; read by sender+receiver; accept by receiver / cancel by sender (status state machine); delete server-only. OK
- `/blocks/{blockId}` line 210-216 — read by blocker+blocked; create+update+delete CF only (blockUser/unblock client-side delete per index.ts:72 comment). OK
- `/spaces/{spaceId}` line 219-257 — read by member (via memberIds denormalized); create+delete CF only; update by creator with field whitelist (name/iconEmoji/colorHex/deletedAt/updatedAt) + type+regex validation. OK
- `/space_members/{spaceId}/members/{uid}` line 260-263 — read by member; write CF only. OK
- `/conversations/{convId}/messages/{messageId}` line 308-323 — create by participant + senderId match auth + text size cap 500 + status='active' guard + optional senderDisplayName cap 50 + quotedPostId cap 30. Update+delete denied. OK
- `/streaks/{uid}` — not present; per `apps/mobile/lib/features/streak/data/firebase_streak_repository.dart:8` comment "Streak module read-only từ `/posts` — không có collection riêng". OK (default deny implicit)

### Cross-uid write protection
- All `/users/{uid}/...` writes gated by `isOwner(uid)` chain — verified line 63-98. OK
- `/posts` create requires `isOwner(request.resource.data.authorId)` line 130. OK
- `/friend_requests` create requires `isOwner(senderId)` line 188; update role-correct (sender cancel / receiver accept-decline). OK

### Storage rules
- `/posts/{uid}/{allPaths=**}` write gated `request.auth.uid == uid && size < 10MB && contentType image/*` — OK (STORAGE-001 chỉ read concern)
- `/avatars/{uid}/{filename}` write gated owner + 5MB + image/* — OK
- `/diary/{uid}/{allPaths=**}` write gated owner + 10MB + image/* — OK (STORAGE-002 chỉ read concern)

### Functions auth
- Mọi onCall (blockUser, deleteAccount, sendFriendRequest stub, acceptFriendRequest, createSpace/updateSpace/leaveSpace/kickMember/transferOwnership) check `if (!request.auth) throw 'unauthenticated'` đầu. OK
- blockUser caller != target enforced line 54-56. OK
- updateSpace/kickMember/transferOwnership check `spaceData.creatorId !== callerUid` → throw `permission-denied`. OK
- leaveSpace check member + non-creator path. OK
- Tất cả CF dùng `request.auth.uid` thay vì `data.uid`. OK (verified blockUser:52, deleteAccount:157, acceptFriendRequest:37, createSpace:64, leaveSpace:39, kickMember:39, transferOwnership:43, updateSpace:77)

### Functions input validation
- Zod schemas hiện diện cho mọi callable input — blockUser/deleteAccount/acceptFriendRequest/createSpace/updateSpace/kickMember/leaveSpace/transferOwnership. OK (FUNC-SEC-001 chỉ `.strict()` polish)
- HTTPS error codes phù hợp: `unauthenticated` cho missing auth, `invalid-argument` cho zod fail, `permission-denied` cho role check fail, `failed-precondition` cho state machine fail, `not-found` cho missing doc. Verified across all 8 CFs. OK

### Functions idempotency
- Notification triggers (onFriendRequestCreated/Accepted, onReactionCreated, onMessageCreated) dùng deterministic doc id (`friend_request_{requestId}`, `reaction_{postId}_{reactorUid}`, `chat_{conversationId}_{messageId}`) + `.create()` collide handling via `isAlreadyExists()` helper — at-least-once safe. OK
- onPostCreated cascade idempotent: postCount via `FieldValue.increment(1)` (re-fire double-count risk same as FUNC-SEC-002 accepted MVP); feed fan-out via deterministic path `users/{uid}/feed/{postId}`. OK
- onPostDeleted: `_deleteFeedDocs` collectionGroup query + batch delete idempotent; `_deleteStorageFile` catch 404. OK
- onFriendshipDeleted: `FieldValue.increment(-1)` for friendCount + conditional conversation status update. OK
- onSpaceDeleted: gated `before.deletedAt == null && after.deletedAt != null`. OK

### Account deletion cleanup
- deleteAccount.ts cascade order verified line 161-268: Storage 3 prefixes → user subcollections (feed/notifications/fcmTokens/private) → cross-collection (diary, posts → triggers onPostDeleted, friendships → triggers onFriendshipDeleted, friend_requests sender+receiver, blocks blocker+blocked) → conversations soft-delete → username reverse-lookup → user doc → admin.auth().deleteUser. Auth LAST so Storage/Firestore cleanup retains permission. Idempotent retry-safe (catch user-not-found). OK
- Orphan check: posts cascade deletes via step 3b → onPostDeleted cleans feed fan-out → friends không còn read post của deleted user. OK

### FCM token ownership
- Client `FirebaseNotificationRepository.saveFcmToken` (firebase_notification_repository.dart:28-42) writes vào `/users/{uid}/fcmTokens/{sha256(token)}` — owner-gated by rule line 96-98. OK
- `SettingsController.signOut` calls `notificationRepositoryProvider.deleteFcmToken(uid)` trước `auth.signOut` (settings_controller.dart:89). OK
- `_fcm.ts:60-74` prune permanent-error tokens after multicast (`messaging/registration-token-not-registered`, etc.). OK

### Notification/widget cached privacy
- Notification body: FCM payloads in notification CFs chứa friend displayName + emoji + post caption preview (≤100 chars). Không leak email/uid/sensitive metadata. OK
- Android widget cache scope: `WidgetDataStore.kt:34-35` uses `FlutterSharedPreferences` với `Context.MODE_PRIVATE` — per-app sandbox, no cross-app read. OK
- Native Kotlin Firestore: `WidgetSyncWorker.kt:63-76` uses `FirebaseAuth.getInstance().currentUser` → idToken auto-attached to Firestore reads. Signed-out path renders placeholder + Result.success. OK

### Emulator/prod config
- `_useEmulator` gated by `--dart-define=USE_EMULATOR` (main.dart:48), defaults false. Release build chạy `flutter build apk --release` không pass dart-define → won't connect emulator. OK
- `google-services.json` git-ignored; staging-only file. Production via `FIREBASE_PROJECT_PROD` GitHub secret (deploy-production.yml:125). OK

### Committed sensitive files
- `.gitignore` lines 1-50 cover: `.env`, `*-service-account.json`, `firebase-adminsdk-*.json`, `google-services.json`, `GoogleService-Info.plist`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.keystore`, `*.jks`, `key.properties`, `.mcp.json`, `.cursor/mcp.json`. Verified `git ls-files` matches: only `.env.example` committed (intentional template). OK
- `firebase_options.dart` apiKey hardcoded — OK per Firebase docs (public API key, protected by App Check) — caveat: requires APPCHECK-001 fix to be meaningful
- Android release signing: `build.gradle.kts:42` uses debug signingConfig with TODO comment. CI `.github/workflows/deploy-production.yml:76-83` decodes keystore from `ANDROID_KEYSTORE_BASE64` secret. OK (release wiring not yet activated — `if: false` line 75 gate)

### Android permissions
- Only `INTERNET` — minimal. No location, contacts, calendar. OK (PERM-001 P3 chỉ về missing manifest declarations)
- POST_NOTIFICATIONS (Android 13+): missing manifest declaration but flutter_local_notifications + firebase_messaging plugins handle runtime request. OK for MVP but should declare per PERM-001 batch_4
- CAMERA: manifest không có `<uses-permission android:name="android.permission.CAMERA"/>` — `camera` plugin 0.12 auto-merge manifest entry tại build time. OK for MVP (verified via `flutter pub deps | grep camera`). Best practice: declare explicit for audit clarity.
- READ_MEDIA_IMAGES (Android 13+): manifest không có declaration — `image_picker` plugin handle via Photo Picker API (system-mediated, không cần runtime perm trên Android 13+). OK.

### CI / deploy hardening
- All workflows use `${{ secrets.X }}` masking — no plain-text token, no `echo "${{ secrets.X }}"`. OK
- Service account passed via env var `GCP_SA_KEY: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_X }}` to w9jds/firebase-action — masked. OK
- Production deploy gated by `branches: [deploy]` trigger + GitHub Environment "production" required reviewer (line 41-44 deploy-production.yml). OK
- pr-check.yml validates: branch name pattern, commit message via commitlint, flutter format+analyze+test, functions lint+typecheck+test, firestore rules emulator tests. OK
- Branch protection (GitHub repo settings): NOT verifiable from repo state — recommendation is to confirm `develop` + `deploy` branches protected with "require PR review + status checks pass" in GitHub UI. Out of audit scope (config not in repo). NOTE.

### Crashlytics PII
- `FirebaseCrashlytics`/`recordError`/`FlutterError.onError` grep = 0 hits in `apps/mobile/lib/` — Crashlytics dep listed trong inventory map nhưng chưa wired. PII scrub concern N/A hiện tại. Khi wire, áp dụng CLAUDE.md §PII handling pattern (separate task, out of audit scope MVP).

### Field validation — additional
- Image URL field regex check: `firebase/firestore.rules:136-139` accept `imageUrl is string` không validate URL domain (e.g. `^https://firebasestorage\\.googleapis\\.com/...`) — client uploads via Storage SDK luôn trả URL `firebasestorage.googleapis.com`, nên không phải attack vector hiện tại; nhưng defense-in-depth gap nếu future client share post từ external CDN. OK for MVP. NOTE.

### Functions test coverage
- `firebase/functions/src/feed/onPostCreated.test.ts` + `index.test.ts` cover happy path. Callable unauth-rejection test gap: không có dedicated test gọi callable với `auth: undefined` để verify throw `unauthenticated`. Coverage gap nhưng auth check pattern uniform across CFs (grep `if (!request.auth)` matches all 8 callables) — manual verification sufficient cho MVP. Recommend thêm 1 unauth-rejection test mỗi callable trong `__tests__/` post-MVP. NOTE.
- Trigger function invalid-input test: `onPostCreated.test.ts` covers post.data shape; other triggers (onMessageCreated, onFriendRequestCreated, etc.) không có dedicated invalid-input test — relies on TypeScript narrowing + defensive `typeof === 'string'` guards. NOTE.

### Client Firebase boundary (layering)
- 3 widget-layer reads của `FirebaseAuth.instance.currentUser?.uid` ở `feed_section.dart:80`, `feed_section.dart:589`, `home_screen.dart:589` — KHÔNG security issue (uid không phải secret, đã có comment line 449-450 documenting layering violation pending fix). Out of audit scope (architecture concern). OK for security audit
- `feed_controller.dart:33,37,56` + `post_controller.dart:85,107,173` are application/controller layer with direct Firebase access — anti-pattern per apps/mobile/CLAUDE.md §Layering nhưng KHÔNG security issue. Logged for cross-reference với audit 01_architecture (out of scope cho 05).

## postcheck
- git_status_after: `?? docs/audits/05_security_firebase_audit.md` (new file, intended) + `?? tmp/audit/ThienPDM/05-security-firebase` (audit staging) — unchanged baseline
- changed_files_after: `docs/audits/05_security_firebase_audit.md` only
- unexpected_modified_files: none

## self_verification_log

<!-- Pass 2 reverify run as follow-up after first commit; corrections folded into issues in-place and listed in pass_2_reverify_notes below. -->

- pass_1_checklist: N=88 items, M=17 issues, K=88 no_issue_notes mappings (each checklist item mapped to ≥1 issue or note via cross-reference; 6 additional gap items added — imageUrl regex, CAMERA, READ_MEDIA_IMAGES, branch protection, callable unauth test, trigger invalid-input test), gap=0
- pass_2_schema: total=17, missing_field_fixed=0 (every issue has sev/blocker/area/files/loc/symbols/evidence/access_path/risk/fix/authority/test/deps), severity_demoted=1 in pass-2 reverify (WIDGET-SEC-001 P2→P3: pass-1 claim "logout missing clearData" SAI — verified `settings_controller.dart:94-99` đã có `clearData()` trong try/catch; chỉ deleteAccount path line 127-158 còn miss → scope hẹp lại, server cascade làm cache stale → URL invalid trong window ~15min nên impact thấp). Pre-pass-2 demotions (in original draft): RULES-004 streaks → no_issue (verified `firebase_streak_repository.dart:8` "không có collection riêng"); RULES-008 diary privacy update P1→P2 (read rule fail-safe denies invalid privacy). evidence_failed_grep=0 — pass-2 re-grep all 17 evidence quotes against source files; 3 line drifts corrected in-place: STORAGE-002 storage.rules:31→30, FUNC-SEC-002 onSpaceMemberAdded.ts:14-19→12-17, WIDGET-SEC-001 settings_controller.dart loc range. Reframed offensive phrasing in 6 issues (APPCHECK-001, USER-SEC-001, STORAGE-001, CHAT-SEC-001, AUTH-SEC-001, USERNAME-SEC-001, REACTION-SEC-001) to defensive language without changing technical content.
- pass_3_dedupe: before=17, after=18 sau pass-3 (added CHAT-SEC-002 P2 from gap scan — /conversations update value-validation gap discovered when re-reading rules cross-reference REACTION-SEC-001 pattern). Consolidations=0 (STORAGE-001 vs STORAGE-002 share root cause "Storage read auth-only doesn't mirror Firestore friend boundary" but distinct files+symbols /posts vs /diary — kept separate per "no duplicate cùng file+symbol+root_cause" criterion. USER-SEC-001 vs USERNAME-SEC-001 share story "user enumeration" but distinct rule blocks + fix paths — kept separate with USERNAME-SEC-001.deps linking. CHAT-SEC-001 vs CHAT-SEC-002: distinct rule blocks — create vs update; CHAT-SEC-002.deps reference cùng test plan TESTING-SEC-001).
  Pass-4 update: 18 → 19 (added USERNAME-SEC-002 P3 — namespace squatting gap in /usernames create rule). Consolidations=0 (USERNAME-SEC-001 vs USERNAME-SEC-002 share collection but distinct rule actions — read vs create — and distinct fix paths, kept separate with cross-dep linking).
- pass_4_coverage: checked=11, partial=1 (client Firebase usage boundary — sampled feed/notification/chat/widget/settings/auth, not every feature module), blocked=0, total=12, verdict=full (every "checked" area backed by grep evidence + file read in commands table)

pass_6_reverify_notes (deep audit per user request — go as kỹ as possible):
- SCOPE: re-grep 3 issues mới (CHAT-SEC-002, USERNAME-SEC-002, USER-SEC-001 expanded); sample 7 module client chưa cover (post=feed/post, diary, profile, space, rollcall, streak, friend); verify 2 CF files pass-3 claim; re-check 2 note-only decisions + CI/CD + email verify.
- FACT FIX 1 (USER-SEC-001 step 3 symbol): pass-4 claim `FirebaseUserRepository.watchUser` SAI — actual method là `watchProfile` (auth/data/firebase_user_repository.dart:46). Cũng phát hiện thêm 2 method khác đọc /users trực tiếp: `FirebaseProfileRepository.watchUserProfile` (profile/data/firebase_profile_repository.dart:80) + `FirebaseFriendRepository.searchUser` (friend/data/firebase_friend_repository.dart:13). Step 3-4 rewritten với verified symbols + path.
- FACT FIX 2 (USERNAME-SEC-002 fix caveat): proposed `get(/users/{auth.uid}).data.username` cross-doc check SẼ BREAK signup vì `FirebaseUserRepository.createProfile` (auth/data/firebase_user_repository.dart:14-27) write /users + /usernames trong cùng batch — rule eval không thấy uncommitted /users. Bắt buộc split batch HOẶC switch CF `claimUsername` alternative. Caveat added vào fix section.
- NEW ISSUE AUTH-SEC-002 P1 BLOCKER (email verification): grep `sendEmailVerification|emailVerified|email_verified|isEmailVerified` trên `apps/mobile/lib/features/auth/` = 0 hits. Signup tạo Firebase Auth user + /users doc với unverified email. Kết hợp USER-SEC-001 = pipeline username → uid → unverified email PII leak. Fix: client gate + rule `email_verified` claim + CF destructive ops check. Blocker vì làm USER-SEC-001 fix mất ý nghĩa nếu không cover.
- NEW ISSUE FRIEND-SEC-002 P2 BLOCKER (rollout): `FirebaseFriendRepository.searchUser` (friend/data/firebase_friend_repository.dart:13-26) chạy collection query `/users where username == X`. Sau USER-SEC-001 fix tighten rule, query này BREAK với PERMISSION_DENIED vì Firestore không prove tĩnh stranger là friend. Phải refactor TRƯỚC khi deploy USER-SEC-001 step (d) rule tighten. Implementation blocker, không phải security gap độc lập.
- NEW ISSUE CI-SEC-001 P3 (CI fallback): `pr-check.yml:160` có `|| echo "::warning::Rules tests skipped"` — silent pass khi script missing/fail. Toàn bộ TESTING-SEC-001 coverage work bị undermined nếu fallback còn. Fix: xóa fallback `||`. Blocks TESTING-SEC-001.
- GAP SCAN client modules — verified files đã đọc:
  - post (feed/data/firebase_post_repository.dart, feed/application/feed_controller.dart, feed/application/post_controller.dart): query patterns OK với rule, dùng arrayContains đúng disjunct. Không phát hiện gap mới.
  - diary (diary/data/firebase_diary_repository.dart): repository đọc Firestore + Storage trực tiếp, OK với owner rule. Note: `getPublicEntries` query `where('privacy', isEqualTo: 'public')` lookup ai khác — sẽ bị STORAGE-002 fix (read author-only) cover, không cần issue mới.
  - profile (profile/data/firebase_profile_repository.dart): updateProfile có client-side `_allowedFields` whitelist mirror rule. Avatar upload 5MB cap mà storage.rules ship 2MB → drift đã được note trong code (line 65), không escalate issue mới vì README spec sẽ sync 5MB.
  - space (space/data/firebase_space_repository.dart): hầu hết mutations qua CF (createSpace, updateSpace, kickMember, transferOwnership, leaveSpace) — gate ở server. `deleteSpace` client-side update `deletedAt` — rule whitelist line 244 cover. Watch query OK.
  - rollcall: KHÔNG TỒN TẠI feature folder (`apps/mobile/lib/features/` không có `rollcall/`) — bị mention trong tmp prompt nhưng module chưa implement. Skip — không phải gap audit.
  - streak (streak/data/firebase_streak_repository.dart): read-only từ /posts, OK với rule (query authorId == uid pass disjunct 1).
  - friend (friend/data/firebase_friend_repository.dart + friend_request_repository.dart): `searchUser` → FRIEND-SEC-002 phát hiện. `watchFriends` batch reads /users/{fuid} — sẽ break tương tự nếu không refactor. `sendFriendRequest` có client-side dedupe race comment chính code đã flag (line 65-68) → leader đã biết, không escalate.
- VERIFY 2 CF FILES pass-3 claim audited: ĐÃ ĐỌC FULL onReactionCreated.ts + onFriendRequestCreated.ts. Cả 2 idempotent qua `notifRef.create()` collision, sender narrow đúng, không phát hiện gap mới. Pass-3 claim "re-read 6 files" đếm sai nhưng kết luận audit không bị ảnh hưởng.
- NOTE-ONLY DECISIONS re-evaluated:
  - MESSAGE createdAt validation gap (pass-3 note): vẫn note-only — impact thấp, sender pinned. Nếu CHAT-SEC-002 fix bundle thêm `createdAt is timestamp` check trong messages create rule (firestore.rules:308-322) thì free. Recommend bundle.
  - imageUrl regex domain match (pass-1 note): vẫn note-only — client luôn upload qua Storage SDK trả `firebasestorage.googleapis.com` URL. Không phải attack vector hiện tại.
- ADDITIONAL CF AUDIT (pass-6 không đếm thêm issue mới):
  - `acceptFriendRequest.ts` (friend/acceptFriendRequest.ts): well-structured, idempotent check (line 97), friendCount cap 20 cả 2 phía. Race window khi 2 user accept simultaneously có thể vượt cap → minor, không escalate.
  - `blockUser.ts` (settings/blockUser.ts): atomic batch, idempotent. No security gap.
  - `onPostDeleted.ts` (feed/onPostDeleted.ts): collection-group query xóa feed entries — well structured. Storage delete với try/catch 404 — OK.
  - `index.ts` (functions/src/index.ts): có 1 stub `sendFriendRequest` (line 39-58) với "TODO(impl)" — KHÔNG implement nhưng KHÔNG được export ở entry point nào (client gọi qua FirebaseFriendRequestRepository.sendFriendRequest đi Firestore direct, không qua CF). Stub có thể removed nhưng không phải security gap.
  - 1 `console.warn` trong onFriendshipDeleted.ts:25 → code quality, không security. Pass-3 đã note. Defer.
- COUNT TALLY: pass-4 total 19 → pass-6 total 22 (+3: AUTH-SEC-002 P1, FRIEND-SEC-002 P2, CI-SEC-001 P3). Distribution: P0=2, P1=6, P2=7, P3=7.
- VERDICT: vẫn not_ready. AUTH-SEC-002 thêm P1 blocker — kết hợp USER-SEC-001 P0 form 1 pipeline email PII. FRIEND-SEC-002 không phải security gap nhưng MUST-FIX trước khi USER-SEC-001 deploy (rollout dependency).
- COVERAGE UPDATE: client module sampling từ partial → full (7/7 modules sampled với evidence file reads). CF coverage từ "6 files re-read" → 10+ files (acceptFriendRequest, blockUser, deleteAccount, onFriendRequestCreated, onReactionCreated, onPostDeleted, onFriendshipDeleted, _fcm, _helpers, index, createSpace + 4 space CFs).

pass_5_reverify_notes (final cross-check before PR):
- COUNT CROSS-CHECK: grep `^### ISSUE ` = 19 entries; grep `^- sev: P0` = 2, `P1` = 5, `P2` = 6, `P3` = 6. Sum 2+5+6+6 = 19. Khớp với pass-4 distribution.
- BATCH SUM CROSS-CHECK: batch_1_p0 (2) + batch_2_p1 (5 incl STORAGE-001+STORAGE-002 bundled line) + batch_3_p2 (6) + batch_4_p3 (6) = 19. Khớp.
- TEST PLAN CROSS-CHECK: 19 entries trong test_plan_after_fix block, mỗi entry mapping 1-1 với issue ID. Không issue nào thiếu test plan; không test plan entry nào orphan.
- FINAL VERDICT block có 3 dòng "Final distribution" cho pass-2, pass-3, pass-4 — chuẩn audit trail. Không cần line cho pass-5 vì pass-5 chỉ cross-check không thay đổi distribution.
- VERDICT confirm: not_ready (P0=2 chưa thay đổi). Recommended path Fix batch_1_p0 + batch_2_p1 (7 issues) trong 1 sprint trước khi ship M3.

pass_4_reverify_notes (expand existing + 1 new):
- EXPAND USER-SEC-001: fix section mở rộng thành 6-step implementation plan — (1) rule split + public subcollection match block, (2) CF onDocumentWritten denormalize trigger, (3) repository tách watchSelfOrFriendProfile vs watchPublicProfile, (4) liệt kê 5 touch points client, (5) 1-shot migrate CF cho existing /users docs, (6) rollout order CF→migrate→client→rule. Mục đích: leader assign T6 follow-up có thể fork ra 6 sub-task ngay.
- NEW ISSUE USERNAME-SEC-002 P3: discovered khi re-read /usernames create rule (line 105-106) cho USERNAME-SEC-001 fix design — rule chỉ check `uid == auth.uid` mà KHÔNG check username path param khớp /users/{auth.uid}.username. Squatting vector. Pair với USERNAME-SEC-001 trong fix CF approach. Note: deleteAccount cascade chỉ xóa username trong /users/{uid}.username → squatted usernames mồ côi nếu fix không bundle.
- COUNT TALLY: pass-3 total 18 → pass-4 total 19 (+1 USERNAME-SEC-002 P3). Distribution: P0=2, P1=5, P2=6, P3=6.
- VERDICT: vẫn not_ready — không có sev escalate, P0 không thay đổi.

pass_3_reverify_notes (gap scan + new issue):
- NEW ISSUE 1 (CHAT-SEC-002 P2): /conversations update rule line 294-302 có field whitelist nhưng KHÔNG có value validation. Participant có thể tamper `lastSenderId` thành uid khác (impersonation inbox preview), `lastMessage` không cap size, `lastReadAt` không shape-check. Defense-in-depth gap. Discovered khi re-read firestore.rules:294-302 đối chiếu với /reactions update pattern (REACTION-SEC-001) — cùng class lỗi (whitelist OK, value-validation missing). Mirror fix style.
- GAP SCAN coverage: re-read 6 CF files (updateSpace, kickMember, transferOwnership, onMessageCreated, onReactionCreated, onFriendRequestCreated, onFriendshipDeleted, _fcm.ts) — không tìm thêm gap nào. Cụ thể:
  - updateSpace.ts: schema refine reject empty patch + creator-only check + deletedAt guard — OK
  - kickMember.ts: creator + non-self + member-check guard — OK
  - transferOwnership.ts: creator + non-self + newCreator-is-member guard — OK
  - onMessageCreated.ts: senderId narrow, participant fan-out idempotent qua notif doc create — OK
  - onFriendshipDeleted.ts: 1 `console.warn` (line 25) vi phạm Functions CLAUDE.md "Don't console.log in production" — code quality concern không phải security, defer.
  - createSpace.ts: server verify friendship trước khi tạo Space — defense in depth tốt, không gap.
  - _fcm.ts: logs uid + error (uid OK per "Log IDs only"), token prune permanent error — OK.
- INDEX REVIEW: `firestore.indexes.json` 10 composite indexes — không có index lộ field PII không cần thiết. authorUid+privacy+createdAt cho diary OK (privacy không phải PII). conversations participantIds+lastMessageAt cần cho inbox query.
- IMAGEURL REGEX gap (đã note pass-1 §no_issue_notes "Field validation — additional"): client luôn upload qua Storage SDK trả URL `firebasestorage.googleapis.com` nên không phải attack vector hiện tại; rule không enforce domain match — defense-in-depth gap nhỏ, vẫn note-only, không escalate.
- MESSAGE createdAt validation gap: `/conversations/{id}/messages` create rule (line 308-322) không check `createdAt is timestamp` — client có thể set arbitrary timestamp gây sai thứ tự render. Impact thấp (sender đã được pin == auth.uid). Note-only, không escalate sang issue mới.

pass_2_reverify_notes (post-commit follow-up after user request):
- FACT FIX 1 (WIDGET-SEC-001 demote P2→P3 + evidence rewrite): pass-1 claimed `settings_controller.dart:89-110 logout … KHÔNG gọi widget clearData`. Re-read confirms `settings_controller.dart:94-99` đã có `try { await ref.read(widgetDataServiceProvider).clearData(); } catch (_) {}` trong logout path. Real gap thu hẹp về `deleteAccount` path line 127-158 (missing clearData). Demoted P2→P3, fix instruction đổi sang deleteAccount path, test plan đổi sang mirror deleteAccount test case.
- FACT FIX 2 (STORAGE-002 loc): pass-1 `storage.rules:31`; actual `allow read: if request.auth != null;` ở line 30 (line 31 là `allow write`). loc range updated 29-35 → 28-35 để bao luôn comment.
- FACT FIX 3 (FUNC-SEC-002 loc): pass-1 `onSpaceMemberAdded.ts:14-19`; actual idempotent comment block ở line 12-17. Updated.
- REFRAME 1-7 (defensive language): tất cả issue có access_path/risk dùng `attacker steal token`, `bot enumerate dictionary`, `victim`, `spam DM`, `malicious URL` → đổi sang `compromised id_token via shared device`, `unauthenticated client iterates`, `other user`, `unsolicited DM to non-friend`, `arbitrary URL` — giữ nguyên technical content + audit value, chỉ thay phrasing để khớp defensive code-review stance của tmp prompt line 3 "Đây là defensive code review trên repo nội bộ của team, KHÔNG phải penetration testing".
- COUNT CORRECTION: pass-1 distribution P0=2/P1=5/P2=6/P3=4=17. Pass-2 distribution P0=2/P1=5/P2=5/P3=5=17 (WIDGET-SEC-001 moved buckets). PR commit message từ pass-1 vẫn còn đúng tổng nhưng buckets cần update khi gửi PR.

## final_verdict

verdict: not_ready

**Rationale:** 2 P0 issues (APPCHECK-001, USER-SEC-001) block MVP launch per CLAUDE.md §Security Guardrails Production blocker + PII bar HIGH. 5 P1 issues (STORAGE-001/002, POST-SEC-001, CHAT-SEC-001, AUTH-SEC-001) cần fix trước Tier 0+ ship (privacy boundary + validation gaps không chấp nhận được cho photo-sharing app intimate friends). P2/P3 issues có thể bundle sau MVP.

**Recommended path:** Fix batch_1_p0 + batch_2_p1 (7 issues) trong 1 sprint (3-5 ngày dev), re-audit, then ship M3. — SUPERSEDED bởi pass-6 recommended path bên dưới.

Final distribution after pass-2 reverify: **P0=2, P1=5, P2=5, P3=5 — total 17 issues** (WIDGET-SEC-001 demoted P2→P3 sau khi verify logout path đã clear cache; chỉ deleteAccount path còn missing — impact thấp vì server cascade làm URL invalid trong 15min).

Final distribution after pass-3 reverify: **P0=2, P1=5, P2=6, P3=5 — total 18 issues** (CHAT-SEC-002 P2 added: /conversations update rule cho phép tamper lastSenderId/lastMessage/lastReadAt mà không value-validate; defense-in-depth gap discovered khi cross-reference với REACTION-SEC-001 pattern).

Final distribution after pass-4 reverify: **P0=2, P1=5, P2=6, P3=6 — total 19 issues** (USERNAME-SEC-002 P3 added: /usernames create rule không check `username == /users/{auth.uid}.username` → squatting vector. Pair với USERNAME-SEC-001 fix; deleteAccount cascade chỉ cleanup username trong /users.username nên squatted usernames sẽ mồ côi nếu fix không bundle). USER-SEC-001 fix section expanded với 6-step implementation plan để leader có thể assign T6 sub-tasks ngay (rule split → CF denormalize → repository tách read → client touch points → migrate CF → rollout order).

Final distribution after pass-6 reverify (deep audit): **P0=2, P1=6, P2=7, P3=7 — total 22 issues** (+3 vs pass-5: AUTH-SEC-002 P1 email verification not enforced = blocker cho USER-SEC-001 PII boundary; FRIEND-SEC-002 P2 searchUser collection query sẽ break sau USER-SEC-001 rule tighten = implementation blocker; CI-SEC-001 P3 pr-check.yml fallback `|| echo warning` undermines TESTING-SEC-001 coverage gate). Fact fixes: USER-SEC-001 step 3-4 sửa symbol `watchUser` → `watchProfile` + thêm 2 method khác đọc /users (watchUserProfile, searchUser); USERNAME-SEC-002 fix caveat — proposed cross-doc `get()` check sẽ break signup batch atomicity, cần CF claimUsername alternative.

**Updated recommended path:** Fix batch_1_p0 (2) + batch_2_p1 (8 issues, +1 AUTH-SEC-002) + 1 P2 blocker FRIEND-SEC-002 — total **11 must-fix** trong 1 sprint (5-7 ngày dev với scope expanded), re-audit, then ship M3.

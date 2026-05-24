# TODO: Auth

> Plan: `docs/plans/2026-05-04-auth.md`
> Spec: `docs/specs/2026-05-04-auth.md`
> Tier: T0 · Milestone M1
> Owner: ThienPDM (toàn bộ module — sample module cho team)
> Blocked by: —

---

## Phase 1 — Setup & Shared

- [x] **T1** — Firebase init + `main.dart` + `AppRouter` với redirect guard 3 states — PR #165
- [x] **T11** — Shared widgets (`AppPrimaryButton`, `AppBackButton`, `AppGoogleButton`, `AppTextInput`) + design tokens — PR #157

---

## Phase 2 — Data layer

- [ ] **T2** — `UserProfile` model — full schema (auth + profile fields), freezed + TimestampConverter
- [ ] **T3** — `FirebaseAuthRepository` impl (signUp, signIn, Google, signOut, deleteCurrentUser, reauthenticate, updateEmail)
- [ ] **T4** — `FirebaseUserRepository` (atomic batch write users + usernames)
- [ ] **T5** — Firestore rules `/users/{uid}` + `/usernames/{username}` + rules tests

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/auth/` — 0 failures
- [ ] `firebase emulators:exec --only firestore "npm run test:rules"` — auth rules pass

---

## Phase 3 — Application layer

- [ ] **T6** — `SignUpController` (4-step state machine + `checkUsername` debounce + `createAccount` + rollback `deleteCurrentUser`)
- [ ] **T7** — `LoginController` + `signInWithGoogle` (check `/users/{uid}`) + `sendPasswordReset`

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/auth/` — 0 failures

---

## Phase 4 — UI Screens

- [ ] **T8** — `IntroPage` (Figma 556:2136) + wire tất cả auth routes vào router
- [ ] **T9** — Signup flow 4 màn hình: `SignUpEmailPage` + `SignUpPasswordPage` + `SignUpNamePage` + `SignUpUsernamePage`
- [ ] **T10** — Login flow: `LoginEmailPage` + `LoginPasswordPage` (forgot password + success auto-navigate 1.5s)

## Checkpoint: Auth complete ✓
- [ ] `flutter test test/features/auth/` — 0 failures
- [ ] `flutter analyze` + `dart format` clean
- [ ] Manual: signup → login → auto-login → Google Sign-In new user → Google Sign-In returning → forgot password → logout

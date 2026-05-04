# TODO: Auth

> Plan: `docs/plans/2026-05-04-auth.md`
> Spec: `docs/specs/2026-05-04-auth.md`
> Epic: #1 — M1 (2026-05-13)

---

## Phase 1: Foundation

- [ ] **T1** — Firebase init + AppRouter (`main.dart` + `core/router/app_router.dart`)
- [ ] **T2** — `UserProfile` model (freezed + json_serializable)
- [ ] **T3** — `AuthRepository` contract update + `FirebaseAuthRepository` impl
- [ ] **T4** — `UserRepository` abstract + `FirebaseUserRepository` (batch write users+usernames)
- [ ] **T5** — Firestore rules: `/users/{uid}` + `/usernames/{username}`

## Checkpoint: Data layer ✓
- [ ] `flutter test test/features/auth/` ALL PASS
- [ ] `firebase deploy --only firestore:rules --project meep-staging` OK

---

## Phase 2: Application Layer

- [ ] **T6** — `SignUpController` (SignUpState + 4-step state machine + createAccount)
- [ ] **T7** — `LoginController` + Google Sign-In (check `/users/{uid}`)

## Checkpoint: App layer ✓
- [ ] `flutter test test/features/auth/` ALL PASS

---

## Phase 3: UI Screens

- [ ] **T8** — `IntroPage` + router wiring (2 CTA → /signup/email, /login/email)
- [ ] **T9** — Signup screens: `SignUpEmailPage` + `SignUpPasswordPage`
- [ ] **T10** — Signup screens: `SignUpNamePage` + `SignUpUsernamePage` (username availability)
- [ ] **T11** — Login screens: `LoginEmailPage` + `LoginPasswordPage` (forgot pw + success state)

## Checkpoint: Auth complete ✓
- [ ] All tests PASS
- [ ] Manual E2E: signup → login → auto-login → logout → Google Sign-In

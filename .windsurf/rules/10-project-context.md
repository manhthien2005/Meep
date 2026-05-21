---
trigger: always_on
---

> ⚠️ **DEPRECATED 2026-05-21** — Source of truth ở `.cursor/rules/10-project-context.mdc`. File này freeze, không sync solo-dev model + ADR-0004.

# Project Context — Meep

## What Meep is

A small, intimate photo-sharing app for close friends. Mobile-first.

- **Primary client:** Flutter (Dart). **MVP target: Android only.** iOS deferred post-MVP per `docs/adr/0002-android-first-defer-ios.md` (Flutter codebase stays cross-platform-ready — adding iOS later does not require rewrites).
- **Headline differentiator:** home-screen widget showing the latest images. MVP = Android AppWidget (Kotlin). iOS WidgetKit (Swift) deferred.
- **Backend:** Firebase first (Auth, Firestore, Storage, Cloud Functions, FCM). A Node/TypeScript service is added only when something genuinely cannot be done in Firebase.
- **Team capstone:** 4 student devs (including the team leader). Decisions must keep onboarding cost low (new dev productive in <1 day) and ops surface lean.

## Why "Firebase first"

| Need | Firebase choice |
|---|---|
| Auth (email + Google; Apple Sign-In deferred with iOS) | Firebase Auth |
| Realtime data, friend graph, posts | Firestore |
| Image storage | Cloud Storage |
| Push notifications | Firebase Cloud Messaging |
| Server-side logic (image resize, fan-out, moderation) | Cloud Functions for Firebase (Node + TypeScript) |
| Crash + analytics | Crashlytics + Firebase Analytics |

A standalone Node/TypeScript backend is added only when:

1. Long-running work that does not fit Cloud Functions cold-start / time budget.
2. Heavy 3rd-party integrations needing custom rate-limiting / queueing.
3. Logic Cloud Functions cannot host efficiently (e.g. WebSocket).

In every other case → keep it in Firebase. Reduces ops surface for the team (4-dev capstone, no dedicated DevOps).

## Team

- **4 devs** (including the team leader).
- Dev name format: PascalCase + abbreviation, e.g. `ThienPDM`, `KhoaLND`.
- Leader is default reviewer (CODEOWNERS).
- Branching: `develop` (integration) → `deploy` (production releases). Feature branch format: `<type>/<DevName>/<short-desc>`.
- Commit messages in Vietnamese (Conventional Commits with Vietnamese descriptions).
- Task tracking: GitHub Projects v2.
- Full team workflow doc: `docs/team-workflow.md`.

## Repository layout

Current scaffolded state lives in `AGENTS.md` §2. Folders not yet created (will appear when first feature lands there):

- `apps/widget/` — native code for the home-screen widget (MVP: Android AppWidget only; iOS WidgetKit deferred per ADR-0002).
- `services/api/` — OPTIONAL standalone Node/TS BE. Only if a Cloud Function cannot do the job.

**Do not pre-create empty folders.** Inside `apps/mobile/lib/`, the canonical layering is `core/` (DI, theme, error, routing) + `features/<feature>/{data,application,presentation}/` — see `21-flutter-rules.md` for the strict layering rules.

## Core MVP scope

Defensive plan + optimistic stretch. Full catalog: `docs/product/features.md`. Detailed breakdown + day estimates: memory `mvp-tier-priority`.

### Tier 0 — Locket parity (firm, must ship M3)

1. Auth (signup 5-screen email/Google + login + logout + auto-login) — M1
2. Friends (invite username/link + accept/decline + friend list) — M2
3. Camera basic (back + flip front + capture + caption text + album picker) — M2
4. Share photo (upload + metadata + push trigger) — M2
5. Feed (vertical list + cache + pagination) — M2
6. Push notification (FCM Android) — M3
7. Reaction (single emoji react) — M3
8. Widget Android (latest image + tap deep link) — M3

### Tier 0+ — Meep differentiator (firm, must ship M3)

9. Diary basic (text entry + 1-3 images attach; **no** canvas editor) — M3
10. Space basic (groups + send photo to space; **no** theme switch, **no** group chat) — M3
11. RollCall basic (weekly notif + special post + multi-emoji react; **no** 168h archive) — M3
12. Profile screen (avatar + username + bio + grid posts) — M2

### Tier 1 — Stretch goals (unlock per retro 13/5 + 27/5)

- Settings basic (edit profile + logout)
- Streak/Kỷ niệm calendar (read-only)
- Chat 1-1 từ ảnh (photo-anchored, **no** group thread)

### Tier 2 — Won't have (defer post-capstone, fixed)

Cut regardless of velocity: Diary canvas editor, dual camera (multi-camera API), video recording, memory cards, caption stickers system (music/weather/season/decoration), group chat in Space, theme switch per Space, block/report, account deletion, RollCall 168h archive, RollCall feed gating.

## Non-goals (MVP)

- iOS targeting (build, distribution, iOS-specific features). Codebase stays cross-platform-ready; switching iOS back on is a separate scoped task post-MVP.
- Apple Sign-In (only required when iOS comes back).
- iOS WidgetKit / Swift native code.
- Public posting / followers / suggestions.
- Free-form messaging (chat must be photo-anchored — Tier 1 stretch only).
- Stories / ephemeral content.
- Multiple device accounts simultaneously logged in.
- Account deletion (GDPR cascade) — defer post-capstone.
- Block / Report user (moderation system) — defer post-capstone.

## Naming convention

- **Folder names:** `kebab-case` (`feed-controller/`, `post-repository/`).
- **Dart files:** `snake_case` (`feed_controller.dart`).
- **Dart classes:** `UpperCamelCase` (`FeedController`).
- **Dart variables/methods:** `lowerCamelCase` (`fetchFeed()`).
- **TypeScript:** ESLint default — `camelCase` for vars/functions, `PascalCase` for classes/types.
- **Firestore collections:** plural `lower_snake_case` (`posts`, `friend_requests`).
- **Firestore document fields:** `camelCase` (`createdAt`, `authorId`).
- **Storage paths:** `posts/{uid}/{postId}/{filename}.jpg`.

## Decisions already made (do NOT re-litigate without good reason)

- Flutter (not React Native, not native + native).
- Riverpod 2 with code-gen for state management.
- `freezed` + `json_serializable` for data classes.
- Firebase first for backend.
- Node 20 + TypeScript (strict) for any server-side code.
- `vitest` for TypeScript tests (over Jest).
- `flutter_test` + `fake_cloud_firestore` + `firebase_auth_mocks` for Flutter tests.

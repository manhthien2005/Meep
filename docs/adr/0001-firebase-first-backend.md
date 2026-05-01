# 0001. Firebase first for the backend

**Date:** 2026-04-30
**Status:** Accepted

## Context

Meep is a private photo-sharing app with a small set of MVP needs:

- Auth (email + Apple + Google).
- Realtime data: friend graph, posts, push notifications.
- Image storage with per-user access control.
- Server-side image resize + push fan-out.
- Crash reporting + analytics.

The project is **solo-developed**. Time spent on ops (servers, deploys, monitoring, scaling) is time not spent on the product. The MVP audience is small (close friends), so cost-at-scale is not the dominant concern.

## Decision

Use **Firebase as the primary backend**:

- Firebase Auth for identity.
- Firestore for friend graph, posts, notifications.
- Cloud Storage for images.
- Cloud Functions for Firebase (Node 20 + TypeScript, region `asia-southeast1`) for triggers + callable RPCs.
- Firebase Cloud Messaging (FCM) for push.
- Crashlytics + Firebase Analytics for observability.

A self-hosted Node/TypeScript service is added **only when something genuinely cannot be done in Firebase** (long-running tasks beyond Cloud Functions limits, heavy 3rd-party integrations, or features that need WebSockets).

## Alternatives considered

### Option A — Roll our own Node + Postgres + Redis + S3

Pros:
- Full control over data model, schema migrations, query plans.
- Cost ceiling is predictable (1 VM + DB).
- No vendor lock-in.

Cons:
- Heavy ops surface for one developer (deploys, backups, monitoring, scaling).
- Auth is non-trivial (especially Apple Sign-In and Google).
- Push notifications require integrating APNs + FCM separately.
- Image storage with per-user ACL needs custom signed URLs.

### Option B — Supabase

Pros:
- Postgres + auth + storage in one product.
- Realtime subscriptions over WebSockets.

Cons:
- Mobile SDKs are less mature than Firebase's, especially for Flutter + iOS.
- Push notifications still need a separate FCM-equivalent.
- Smaller ecosystem of patterns / docs / examples for Flutter.
- Less battle-tested on mobile-first apps at our scale.

### Option C — Firebase first (chosen)

Pros:
- Mature Flutter SDKs (`firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging`).
- Auth providers built-in (email, Apple, Google).
- Push notifications natively integrated.
- Per-document security rules cover most ACL needs without backend code.
- Solo dev productivity is highest here.

Cons:
- Vendor lock-in (mitigated by keeping business logic in clients/Functions, not in proprietary Firebase tools).
- Cost can grow non-linearly at scale (Firestore reads, Functions invocations) — acceptable for MVP, revisit at 10k+ users.
- NoSQL data model requires denormalization for join-like queries (acceptable, see `.windsurf/rules/23-firestore-rules.md`).

## Consequences

### Positive

- Solo dev can ship the MVP with no dedicated server / DB / queue / push infra to run.
- Auth complexity is the SDK's problem, not ours.
- Security rules enforce per-document ACL declaratively (testable with `@firebase/rules-unit-testing`).

### Negative

- We're locked to Google Cloud / Firebase pricing trajectory. If costs become prohibitive, migrating off Firestore is a multi-week project.
- Some queries (full-text search, complex joins, aggregations) are awkward → add Cloud Functions or accept denormalization.
- Realtime listeners count as billable reads — design with care for the friend feed.

### Neutral / unknowns

- If we ever add web (Flutter Web or React PWA), Firebase still works but requires cross-origin config and separate auth flows.
- Long-term: if MVP succeeds, a dedicated BE may be added for specific subsystems (image processing pipelines, abuse detection). It does not require migrating off Firebase.

# CONTEXT.md — Domain Language for Meep

> Shared vocabulary between the human and the agent. Use these terms exactly when discussing the system or writing code. Disambiguates overloaded words and locks naming consistency.

## Core entities

| Term | Definition | Lives at |
|---|---|---|
| **User** | An authenticated person, identified by `uid` (Firebase Auth UID, string). Has `displayName`, `avatarUrl`. | Firestore: `/users/{uid}` |
| **Post** | One photo + optional caption shared by a User to their friends. NEVER public. Always tied to one author. | Firestore: `/posts/{postId}` |
| **Caption** | The text accompanying a Post. ≤ 200 chars. Optional (a post can be photo-only). | Field `caption` in `/posts/{postId}` |
| **Friend** | Another User with whom the current User has a mutual accepted friendship. Bidirectional. | Derived from `/friendships/{pairId}` |
| **Friend graph** | The set of all friendships across all Users. Bidirectional, no public following. | Firestore: `/friendships` |
| **Friend request** | A pending invite from one User to another. Becomes a Friend when accepted. | Firestore: `/friend_requests/{requestId}` |
| **Feed** | The chronological list of friends' Posts visible to the current User. Cursor-paginated, latest first. | Computed by querying `/posts` filtered by friend `authorId`s |
| **Notification** | A push message about a friend's activity (new post, accepted request). Persisted per user. | Firestore: `/users/{uid}/notifications/{notifId}` + FCM push |

## Identifiers

| Term | Format | Example |
|---|---|---|
| `uid` | Firebase Auth UID — opaque string, ≤ 128 chars | `7Mk9x2QR8vN3yL4pHzAj` |
| `postId` | Auto-generated Firestore doc ID, 20 chars | `aB3xKzqrL5MnPq7Ws2Yd` |
| `pairId` | **Sorted** `uidA_uidB` for friendship lookup. Always `min < max` to make it deterministic. | `7Mk9x2QR_xZ1fGh4Bp9Q` |
| `requestId` | Auto-generated Firestore doc ID for friend requests | `cD9zLmrqW3NpKj5Rs8Yt` |
| `notifId` | Auto-generated Firestore doc ID for notifications | `eF2hQrsbT8VnLk6Zp4Mw` |

```dart
// Pair ID computation — must be deterministic
String pairIdOf(String a, String b) {
  return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
}
```

## Architectural patterns

| Pattern | What it means | Where it appears |
|---|---|---|
| **Fan-out** | Cloud Function pattern: when a Post is created, the Function enumerates the author's Friends and pushes a Notification to each. NOT done client-side. | `firebase/functions/src/index.ts` `onPostCreated` |
| **Denormalize** | Copy a value (e.g. `authorName`, `authorAvatarUrl`) into a Post document so the Feed query needs no JOIN. Trade write complexity for read speed. | `/posts/{postId}` fields `authorName`, `authorAvatarUrl` |
| **Repository** | Class abstracting Firebase calls so widgets/controllers do NOT touch `FirebaseFirestore.instance` directly. Lives in `lib/features/<feature>/data/`. | e.g. `AuthRepository`, `PostRepository` |
| **Cursor pagination** | Use `startAfterDocument(lastDoc)` instead of `offset()` (Firestore has no efficient offset). | Feed query, friend list |
| **ServerTimestamp** | Use `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt`. Never trust client clocks. | Every doc with timestamps |

## Disambiguation — terms with overloaded meanings

The same word means different things depending on context. Always specify which.

### "Widget"

| Term | Meaning | Where the code lives |
|---|---|---|
| **Widget (Flutter)** | A UI component (`StatelessWidget`, `ConsumerWidget`, `StatefulWidget`). Building block of every screen. | `apps/mobile/lib/features/<feature>/presentation/` |
| **Widget (home-screen)** | The native iOS WidgetKit / Android AppWidget showing latest Meep images on the user's home screen. The headline differentiator. | `apps/widget/` (iOS Swift + Android Kotlin) — not yet scaffolded |

When unclear, write **"home-screen widget"** for native, just **"widget"** for Flutter UI.

### "Provider"

| Term | Meaning | Library |
|---|---|---|
| **Provider (Riverpod)** | A `Provider<T>` / `StreamProvider<T>` / `FutureProvider<T>` / `NotifierProvider<T>`. Riverpod 2 idiom. | `flutter_riverpod` |
| **Provider (Firebase Auth)** | An OAuth identity provider — Google, Apple, email/password. | `firebase_auth` |

When unclear, write **"Riverpod provider"** vs **"auth provider"**.

### "Storage"

| Term | Meaning |
|---|---|
| **Storage (Firebase)** | Cloud Storage for Firebase — where images live. Bucket: `<project>.appspot.com`. |
| **Storage (local)** | On-device cache (SharedPreferences / Hive / SQLite). For offline / widget data. |

When unclear, write **"Cloud Storage"** vs **"local cache"**.

### "Rule"

| Term | Meaning |
|---|---|
| **Rule (Firestore)** | A `.rules` file declaring per-collection access policy. |
| **Rule (Cascade)** | A `.windsurf/rules/*.md` file giving the agent instructions. |
| **Rule (lint)** | An entry in `analysis_options.yaml` or ESLint config. |

Write **"Firestore rules"**, **"agent rules"**, **"lint rules"** to be explicit.

## Anti-terms — words to AVOID

| Avoid | Use instead | Why |
|---|---|---|
| `user_id` | `uid` | Inconsistent with Firebase Auth field name |
| `friend_id` | `pairId` (for friendship doc) or `friendUid` (for the friend's User) | Ambiguous what "friend ID" refers to |
| `image` | `imageUrl` (for the URL string) or `image bytes` (for raw data) | Both meanings clash |
| "the database" | "Firestore" | We don't have "a database" — we have specific products (Firestore, Storage, Auth) |
| "the backend" | "Cloud Functions" / "the (optional) Node BE in `services/api/`" | Same reason |
| "save" | "create" / "update" / "upsert" | Vague — say which write op |
| "fetch" | "read once" (`get()`) / "watch" (`snapshots()`) | Different perf characteristics |

## Status fields enum

| Field | Values |
|---|---|
| `friend_requests.status` | `pending` / `accepted` / `declined` / `cancelled` |
| `posts.uploadStatus` (if used) | `uploading` / `uploaded` / `failed` |
| `notifications.read` | `true` / `false` (boolean, default false) |

## Update policy for this file

- **When to update:** new entity introduced, new disambiguation needed, naming convention changes.
- **When NOT to update:** transient implementation details, internal helper names.
- **Review:** quick re-read at start of each `/spec` session — if a new term appears in the spec discovery phase, add it here BEFORE coding.

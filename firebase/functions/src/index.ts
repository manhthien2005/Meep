import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { z } from 'zod';

initializeApp();

setGlobalOptions({
  region: 'asia-southeast1',
  maxInstances: 10,
});

// ===== Schemas =====

const sendFriendRequestSchema = z.object({
  toUid: z.string().min(1).max(128),
});

// ===== Callable functions =====

/**
 * Send a friend request from the calling user to `toUid`.
 *
 * TODO(impl):
 *   - check the requester is not blocked by the target
 *   - check no pending request already exists between the pair
 *   - write the request doc with serverTimestamp()
 *   - send an FCM notification to the target
 */
export const sendFriendRequest = onCall((request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Login required');
  }

  const parsed = sendFriendRequestSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError('invalid-argument', parsed.error.message);
  }

  const { toUid } = parsed.data;
  const fromUid = request.auth.uid;

  if (fromUid === toUid) {
    throw new HttpsError('failed-precondition', 'Cannot friend yourself');
  }

  // TODO(impl): see comment above.
  return { ok: true, fromUid, toUid };
});

// ===== Firestore triggers =====

/**
 * Fan out a notification to all friends of the post author.
 *
 * TODO(impl):
 *   - read the post doc
 *   - look up friend uids in /friendships
 *   - load FCM tokens from /users/{uid}/private/fcm
 *   - call messaging.sendEachForMulticast(...)
 */
export const onPostCreated = onDocumentCreated(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  (event) => {
    const post = event.data?.data();
    if (!post) return;
    // TODO(impl): see comment above.
    console.warn(`onPostCreated fired for ${event.params.postId} — TODO: fan out`);
  },
);

// ===== Friend module stubs =====

/**
 * Accept a pending friend request and create the friendship doc.
 *
 * TODO(F/T5/ThienPDM):
 *   1. Verify request exists + status == 'pending' + request.auth.uid == receiverId
 *   2. Check sender.friendCount < 20 AND receiver.friendCount < 20
 *      → throw FAILED_PRECONDITION if either >= 20
 *   3. Firestore batch (1 commit, atomic):
 *      a. Create /friendships/{pairId} (uid1, uid2, members, createdAt)
 *      b. Create /conversations/{pairId} (type='direct', participantIds=[uid1,uid2])
 *      c. Update /friend_requests/{requestId}.status = 'accepted'
 *      d. FieldValue.increment(1) friendCount for both sender and receiver
 *   4. Send FCM notification to sender
 *   5. Return { success: true, pairId: string }
 *
 * Note: conversationId == pairId (sorted uid1_uid2) — consistent with friendship docId.
 * Idempotent: if A→B and B→A send requests simultaneously, detect and create 1 friendship only.
 */
export const acceptFriendRequest = onCall((request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
  // TODO(F/T5/ThienPDM): see comment above.
  return { ok: true };
});

/**
 * Clean up friend-related data when a friendship is deleted.
 *
 * TODO(F/T6/ThienPDM):
 *   1. Decrement friendCount for uid1 and uid2 using FieldValue.increment(-1)
 *      → use transaction for idempotency
 *   2. Update /conversations/{pairId}.status = 'unfriended' if conversation exists
 *      → do NOT crash if conversation doesn't exist
 *   3. Batch delete cross-feed entries:
 *      - Delete /users/{uid1}/feed/{postId} WHERE authorId == uid2 AND spaceId == null
 *      - Delete /users/{uid2}/feed/{postId} WHERE authorId == uid1 AND spaceId == null
 *   4. Preserve Space posts (spaceId != null) — do NOT delete from feed
 *
 * Note: This CF owns feed cleanup (Home/Camera/Feed module concern).
 * Home/Camera/Feed module does NOT create a separate CF for this cleanup.
 * CF must be idempotent: re-running after partial failure produces same final state.
 */
export const onFriendshipDeleted = onDocumentDeleted(
  { document: 'friendships/{pairId}', region: 'asia-southeast1' },
  (_event) => {
    // TODO(F/T6/ThienPDM): see comment above.
  },
);

// ===== Settings module stubs =====

/**
 * Block a user: create /blocks doc + remove friendship + update conversation status.
 *
 * TODO(SE/impl):
 *   - verify target exists + caller != target
 *   - create /blocks/{blockerUid}_{targetUid}
 *   - delete /friendships/{pairId} if exists
 *   - update /conversations/{pairId}.status = 'blocked' if exists
 */
export const blockUser = onCall((request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
  // TODO(SE/impl): see comment above.
  return { ok: true };
});

/**
 * Unblock a user: delete /blocks doc + delete /friendships/{pairId} if exists.
 * Atomic via Admin SDK batch — client cannot write /blocks directly.
 *
 * TODO(SE/impl):
 *   - verify caller != target
 *   - delete /blocks/{blockerUid}_{targetUid} if exists
 *   - delete /friendships/{pairId} if exists
 */
export const unblockUser = onCall((request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
  // TODO(SE/impl): see comment above.
  return { ok: true };
});

/**
 * Delete account: re-authenticate, then cascade-delete all user data.
 *
 * TODO(SE/impl):
 *   - delete /users/{uid} + subcollections
 *   - delete /posts by uid from Storage + Firestore
 *   - delete /friendships where uid is member
 *   - delete Firebase Auth account
 */
export const deleteAccount = onCall((request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');
  // TODO(SE/impl): see comment above.
  return { ok: true };
});

// ===== Feed module stubs =====

/**
 * Clean up Storage assets when a post is deleted.
 *
 * TODO(FE/impl):
 *   - delete posts/{uid}/{postId}/photo.jpg from Storage
 *   - remove fan-out feed entries in /users/{uid}/feed/{postId}
 */
export const onPostDeleted = onDocumentDeleted(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  (_event) => {
    // TODO(FE/impl): see comment above.
  },
);

// ===== Notification module stubs =====

/** TODO(N/impl): send FCM to receiver + persist /notifications doc */
export const onFriendRequestCreated = onDocumentCreated(
  { document: 'friend_requests/{requestId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(N/impl) */ },
);

/** TODO(N/impl): send FCM to original sender + persist /notifications doc */
export const onFriendRequestAccepted = onDocumentCreated(
  { document: 'friendships/{pairId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(N/impl) */ },
);

/** TODO(N/impl): send FCM to post owner + persist /notifications doc */
export const onReactionCreated = onDocumentCreated(
  { document: 'posts/{postId}/reactions/{reactionId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(N/impl) */ },
);

// ===== Space module stubs =====

export const createSpace = onCall((req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Login required');
  return { ok: true }; // TODO(SP/impl)
});
export const leaveSpace = onCall((req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Login required');
  return { ok: true }; // TODO(SP/impl)
});
export const kickMember = onCall((req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Login required');
  return { ok: true }; // TODO(SP/impl)
});
export const transferOwnership = onCall((req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Login required');
  return { ok: true }; // TODO(SP/impl)
});

export const onSpaceMemberAdded = onDocumentCreated(
  { document: 'spaces/{spaceId}/members/{uid}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/impl) */ },
);
export const onSpaceMemberRemoved = onDocumentDeleted(
  { document: 'spaces/{spaceId}/members/{uid}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/impl) */ },
);
export const onSpacePostCreated = onDocumentCreated(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/impl) — only processes posts where data.spaceId != null */ },
);
export const onSpaceDeleted = onDocumentUpdated(
  { document: 'spaces/{spaceId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/impl) — fires when deletedAt field is set (soft delete) */ },
);

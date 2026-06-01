import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { z } from 'zod';

// Feed module
export { onPostCreated } from './feed/onPostCreated.js';
export { onPostDeleted } from './feed/onPostDeleted.js';

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

// onPostCreated — implemented in ./feed/onPostCreated.ts

// ===== Friend module =====

export { acceptFriendRequest } from './friend/acceptFriendRequest.js';
export { onFriendshipDeleted } from './friend/onFriendshipDeleted.js';

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

// onPostCreated + onPostDeleted implemented in ./feed/ — exported above

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

// ===== Space module =====

export { createSpace } from './space/createSpace.js';
export { leaveSpace } from './space/leaveSpace.js';
export { kickMember } from './space/kickMember.js';
export { transferOwnership } from './space/transferOwnership.js';

export const onSpaceMemberAdded = onDocumentCreated(
  { document: 'space_members/{spaceId}/members/{uid}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/T8/impl) */ },
);
export const onSpaceMemberRemoved = onDocumentDeleted(
  { document: 'space_members/{spaceId}/members/{uid}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/T8/impl) */ },
);
// onSpacePostCreated — DELETED per Option A. spacePostFanOut là helper
// gọi từ feed/onPostCreated khi post.spaceId != null (T9).
export const onSpaceDeleted = onDocumentUpdated(
  { document: 'spaces/{spaceId}', region: 'asia-southeast1' },
  (_event) => { /* TODO(SP/T10/impl) — fires when deletedAt field is set (soft delete) */ },
);

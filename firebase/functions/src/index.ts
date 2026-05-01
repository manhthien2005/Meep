import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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
export const sendFriendRequest = onCall(async (request) => {
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
  async (event) => {
    const post = event.data?.data();
    if (!post) return;
    // TODO(impl): see comment above.
    console.warn(`onPostCreated fired for ${event.params.postId} — TODO: fan out`);
  },
);

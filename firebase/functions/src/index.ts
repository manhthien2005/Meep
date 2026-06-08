import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { z } from "zod";

// Feed module
export { onPostCreated } from "./feed/onPostCreated.js";
export { onPostDeleted } from "./feed/onPostDeleted.js";

// Settings module
export { blockUser } from "./settings/blockUser.js";
export { deleteAccount } from "./settings/deleteAccount.js";

initializeApp();

setGlobalOptions({
  region: "asia-southeast1",
  maxInstances: 10,
  memory: "256MiB",
  timeoutSeconds: 60,
});

// ===== Schemas =====

const sendFriendRequestSchema = z
  .object({
    toUid: z.string().min(1).max(128),
  })
  .strict();

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
    throw new HttpsError("unauthenticated", "Login required");
  }

  const parsed = sendFriendRequestSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const { toUid } = parsed.data;
  const fromUid = request.auth.uid;

  if (fromUid === toUid) {
    throw new HttpsError("failed-precondition", "Cannot friend yourself");
  }

  // TODO(impl): see comment above.
  return { ok: true, fromUid, toUid };
});

// ===== Firestore triggers =====

// onPostCreated — implemented in ./feed/onPostCreated.ts

// ===== Friend module =====

export { acceptFriendRequest } from "./friend/acceptFriendRequest.js";
export { onFriendshipDeleted } from "./friend/onFriendshipDeleted.js";

// ===== Settings module stubs =====

// blockUser — implemented in ./settings/blockUser.ts (exported above).
// unblockUser stub gỡ bỏ: T1 đã quyết unblock = client-side delete
// `/blocks/{blockerUid}_{targetUid}` (OQ5 resolved trong #116). CF không cần.
// deleteAccount — implemented in ./settings/deleteAccount.ts (exported above).

// onPostCreated + onPostDeleted implemented in ./feed/ — exported above

// ===== Notification module =====

export { onFriendRequestCreated } from "./notification/onFriendRequestCreated.js";
export { onFriendRequestAccepted } from "./notification/onFriendRequestAccepted.js";
export { onReactionCreated } from "./notification/onReactionCreated.js";

// ===== Chat module =====

export { onMessageCreated } from "./chat/onMessageCreated.js";

// ===== Space module =====

export { createSpace } from "./space/createSpace.js";
export { updateSpace } from "./space/updateSpace.js";
export { leaveSpace } from "./space/leaveSpace.js";
export { kickMember } from "./space/kickMember.js";
export { transferOwnership } from "./space/transferOwnership.js";
export { onSpaceMemberAdded } from "./space/onSpaceMemberAdded.js";
export { onSpaceMemberRemoved } from "./space/onSpaceMemberRemoved.js";
export { onSpaceDeleted } from "./space/onSpaceDeleted.js";
// onSpacePostCreated — KHÔNG export per Option A: spacePostFanOut là
// helper gọi từ feed/onPostCreated khi post.spaceId != null (đã wire).

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

const acceptFriendRequestSchema = z.object({
  requestId: z.string().min(1),
});

/**
 * Accept a pending friend request and create the friendship doc.
 *
 * Steps:
 * 1. Verify request exists + status == 'pending' + request.auth.uid == receiverId
 * 2. Check sender.friendCount < 20 AND receiver.friendCount < 20
 * 3. Firestore batch (1 commit, atomic):
 *    a. Create /friendships/{pairId}
 *    b. Create /conversations/{pairId}
 *    c. Update /friend_requests/{requestId}.status = 'accepted'
 *    d. FieldValue.increment(1) friendCount for both users
 * 4. Return { success: true, pairId: string }
 *
 * Idempotent: if A→B and B→A send requests simultaneously, detect and create 1 friendship only.
 */
export const acceptFriendRequest = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = acceptFriendRequestSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { requestId } = parsed.data;
    const receiverId = request.auth.uid;
    const db = getFirestore();

    // Step 1: Verify friend request
    const requestDoc = await db.collection('friend_requests').doc(requestId).get();

    if (!requestDoc.exists) {
      throw new HttpsError('not-found', 'Friend request not found');
    }

    const requestData = requestDoc.data();
    if (!requestData) {
      throw new HttpsError('not-found', 'Friend request data missing');
    }

    if (requestData.status !== 'pending') {
      throw new HttpsError('failed-precondition', `Request already ${String(requestData.status)}`);
    }

    if (requestData.receiverId !== receiverId) {
      throw new HttpsError('permission-denied', 'Not the receiver of this request');
    }

    const senderId = String(requestData.senderId);

    // Step 2: Check friendCount < 20 for both users
    const [senderDoc, receiverDoc] = await Promise.all([
      db.collection('users').doc(senderId).get(),
      db.collection('users').doc(receiverId).get(),
    ]);

    if (!senderDoc.exists || !receiverDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const senderData = senderDoc.data();
    const receiverData = receiverDoc.data();

    if (!senderData || !receiverData) {
      throw new HttpsError('not-found', 'User data missing');
    }

    const senderFriendCount = typeof senderData.friendCount === 'number' ? senderData.friendCount : 0;
    const receiverFriendCount = typeof receiverData.friendCount === 'number' ? receiverData.friendCount : 0;

    if (senderFriendCount >= 20) {
      throw new HttpsError('failed-precondition', 'Sender has 20 friends already');
    }

    if (receiverFriendCount >= 20) {
      throw new HttpsError('failed-precondition', 'Receiver has 20 friends already');
    }

    // Compute pairId (sorted)
    const pairId = senderId < receiverId ? `${senderId}_${receiverId}` : `${receiverId}_${senderId}`;
    const uid1 = senderId < receiverId ? senderId : receiverId;
    const uid2 = senderId < receiverId ? receiverId : senderId;

    // Check if friendship already exists (idempotent)
    const friendshipDoc = await db.collection('friendships').doc(pairId).get();
    if (friendshipDoc.exists) {
      // Already friends - just update request status and return
      await db.collection('friend_requests').doc(requestId).update({
        status: 'accepted',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { success: true, pairId };
    }

    // Step 3: Firestore batch write
    const batch = db.batch();

    // 3a. Create friendship
    batch.set(db.collection('friendships').doc(pairId), {
      uid1,
      uid2,
      members: [uid1, uid2],
      createdAt: FieldValue.serverTimestamp(),
    });

    // 3b. Create conversation
    batch.set(db.collection('conversations').doc(pairId), {
      type: 'direct',
      participantIds: [uid1, uid2],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 3c. Update friend request status
    batch.update(db.collection('friend_requests').doc(requestId), {
      status: 'accepted',
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 3d. Increment friendCount for both users
    batch.update(db.collection('users').doc(senderId), {
      friendCount: FieldValue.increment(1),
    });
    batch.update(db.collection('users').doc(receiverId), {
      friendCount: FieldValue.increment(1),
    });

    await batch.commit();

    return { success: true, pairId };
  },
);

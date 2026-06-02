import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

/**
 * Schema validation for blockUser CF input.
 *
 * Server source of truth: client (`FirebaseBlockRepository.blockUser`) chỉ
 * gửi `targetUid` — server tự derive `blockerUid` từ `request.auth.uid`.
 */
const blockUserSchema = z.object({
  targetUid: z.string().min(1).max(128),
});

/**
 * Block a user atomically.
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Guard: blockerUid != targetUid (no self-block).
 * 3. Idempotent: nếu /blocks/{blockerUid}_{targetUid} đã tồn tại → return success.
 * 4. Atomic batch (Admin SDK bypass rules):
 *    a. Create /blocks/{blockerUid}_{targetUid} { blockId, blockerUid,
 *       blockedUid, createdAt }
 *    b. Delete /friendships/{pairId} nếu tồn tại — pairId sorted (lex thấp
 *       trước), match Friend repository convention.
 *    c. Update /conversations/{pairId}.status = 'blocked' nếu tồn tại.
 * 5. Return { success: true }.
 *
 * Notes:
 * - blockId asymmetric ({blockerUid}_{blockedUid}, NOT sorted) — khác pairId.
 *   Client `isBlocked()` query cả 2 chiều để detect bidirectional.
 * - Friendship deletion sẽ trigger `onFriendshipDeleted` CF (đã wire) →
 *   cross-feed cleanup handled there.
 * - `batch.delete()` an toàn với doc không tồn tại (no-op), nên không cần
 *   pre-read friendship. `batch.update()` throws NOT_FOUND → phải pre-read
 *   conversation.
 */
export const blockUser = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = blockUserSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { targetUid } = parsed.data;
    const blockerUid = request.auth.uid;

    if (blockerUid === targetUid) {
      throw new HttpsError('invalid-argument', 'Cannot block yourself');
    }

    const db = getFirestore();
    const blockId = `${blockerUid}_${targetUid}`;
    const blockRef = db.collection('blocks').doc(blockId);

    // Step 3: Idempotent check.
    const existing = await blockRef.get();
    if (existing.exists) {
      return { success: true };
    }

    // pairId sorted (lex thấp trước) — match FirebaseFriendRepository.
    const pairId =
      blockerUid < targetUid
        ? `${blockerUid}_${targetUid}`
        : `${targetUid}_${blockerUid}`;

    const friendshipRef = db.collection('friendships').doc(pairId);
    const conversationRef = db.collection('conversations').doc(pairId);

    // Pre-read conversation: batch.update() throws NOT_FOUND nếu doc không
    // tồn tại; conditional update.
    const conversationSnap = await conversationRef.get();

    const now = FieldValue.serverTimestamp();
    const batch = db.batch();

    // 4a. Create /blocks/{blockerUid}_{targetUid}
    batch.set(blockRef, {
      blockId,
      blockerUid,
      blockedUid: targetUid,
      createdAt: now,
    });

    // 4b. Delete /friendships/{pairId} — batch.delete an toàn với non-existent.
    batch.delete(friendshipRef);

    // 4c. Update /conversations/{pairId}.status = 'blocked' nếu tồn tại.
    if (conversationSnap.exists) {
      batch.update(conversationRef, {
        status: 'blocked',
        updatedAt: now,
      });
    }

    await batch.commit();

    return { success: true };
  },
);

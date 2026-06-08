import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

const leaveSpaceSchema = z
  .object({
    spaceId: z.string().min(1),
  })
  .strict();

/**
 * Member rời Space (không phải creator).
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Load Space + verify caller là member + KHÔNG phải creator.
 *    Creator phải `transferOwnership` trước, hoặc dùng `deleteSpace` (soft).
 * 3. Atomic batch:
 *    a. Xóa /space_members/{spaceId}/members/{callerUid}
 *    b. Update /spaces/{spaceId}.memberIds: arrayRemove(callerUid)
 *       + memberCount: decrement(1)
 *    c. Update /conversations/{spaceId}.participantIds: arrayRemove(callerUid)
 *
 * Note: KHÔNG xóa posts của caller — quyết định product (Locket parity):
 * post đã share thì giữ trong feed members khác. CF `onSpaceMemberRemoved` (T8)
 * sẽ decrement /users/{uid}.spaceCount.
 */
export const leaveSpace = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = leaveSpaceSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { spaceId } = parsed.data;
    const callerUid = request.auth.uid;
    const db = getFirestore();

    const spaceRef = db.collection('spaces').doc(spaceId);
    const spaceDoc = await spaceRef.get();
    if (!spaceDoc.exists) {
      throw new HttpsError('not-found', 'Space not found');
    }

    const spaceData = spaceDoc.data();
    if (!spaceData) {
      throw new HttpsError('not-found', 'Space data missing');
    }

    if (spaceData.deletedAt != null) {
      throw new HttpsError('failed-precondition', 'Space already deleted');
    }

    const memberIds = Array.isArray(spaceData.memberIds)
      ? (spaceData.memberIds as string[])
      : [];
    if (!memberIds.includes(callerUid)) {
      throw new HttpsError('permission-denied', 'Not a member of this Space');
    }

    if (spaceData.creatorId === callerUid) {
      throw new HttpsError(
        'failed-precondition',
        'Creator must transferOwnership trước khi leave (hoặc deleteSpace)',
      );
    }

    const batch = db.batch();

    batch.delete(
      db
        .collection('space_members')
        .doc(spaceId)
        .collection('members')
        .doc(callerUid),
    );

    batch.update(spaceRef, {
      memberIds: FieldValue.arrayRemove(callerUid),
      memberCount: FieldValue.increment(-1),
    });

    batch.update(db.collection('conversations').doc(spaceId), {
      participantIds: FieldValue.arrayRemove(callerUid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return { success: true };
  },
);

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

const transferOwnershipSchema = z.object({
  spaceId: z.string().min(1),
  newCreatorUid: z.string().min(1),
});

/**
 * Creator chuyển quyền sở hữu Space cho member khác. Bước bắt buộc trước
 * khi creator muốn `leaveSpace` (creator không được leave trực tiếp).
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Load Space + verify:
 *    - caller là creator hiện tại
 *    - newCreator KHÁC caller
 *    - newCreator là member của Space
 * 3. Atomic batch:
 *    a. /spaces/{spaceId}.creatorId = newCreatorUid
 *    b. /space_members/{spaceId}/members/{caller}.role = 'member'
 *    c. /space_members/{spaceId}/members/{newCreator}.role = 'creator'
 *
 * Note về downstream UX (T4 wire):
 * - SpaceController.watchMySpaces sẽ emit Space mới với creatorId update.
 * - SpaceManagementSheet rebuild — "Xóa Space" button ẩn cho caller cũ,
 *   hiện cho newCreator.
 */
export const transferOwnership = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = transferOwnershipSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { spaceId, newCreatorUid } = parsed.data;
    const callerUid = request.auth.uid;

    if (callerUid === newCreatorUid) {
      throw new HttpsError(
        'invalid-argument',
        'newCreatorUid phải khác caller',
      );
    }

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

    if (spaceData.creatorId !== callerUid) {
      throw new HttpsError(
        'permission-denied',
        'Only current creator can transferOwnership',
      );
    }

    const memberIds = Array.isArray(spaceData.memberIds)
      ? (spaceData.memberIds as string[])
      : [];
    if (!memberIds.includes(newCreatorUid)) {
      throw new HttpsError(
        'failed-precondition',
        'newCreatorUid phải là member của Space',
      );
    }

    const batch = db.batch();

    batch.update(spaceRef, {
      creatorId: newCreatorUid,
    });

    const membersCol = db
      .collection('space_members')
      .doc(spaceId)
      .collection('members');

    batch.update(membersCol.doc(callerUid), {
      role: 'member',
    });
    batch.update(membersCol.doc(newCreatorUid), {
      role: 'creator',
    });

    batch.update(db.collection('conversations').doc(spaceId), {
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return { success: true };
  },
);

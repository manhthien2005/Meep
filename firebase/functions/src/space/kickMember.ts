import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

const kickMemberSchema = z
  .object({
    spaceId: z.string().min(1),
    targetUid: z.string().min(1),
  })
  .strict();

/**
 * Creator kick một member khỏi Space.
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Load Space + verify caller là creator + KHÔNG kick chính creator
 *    + target hiện là member.
 * 3. Atomic batch:
 *    a. Xóa /space_members/{spaceId}/members/{targetUid}
 *    b. Update /spaces/{spaceId}.memberIds: arrayRemove(targetUid)
 *       + memberCount: decrement(1)
 *    c. Update /conversations/{spaceId}.participantIds: arrayRemove(targetUid)
 *
 * Note: target nhận FCM "Bạn đã bị kick khỏi [SpaceName]" qua T8 trigger
 * onSpaceMemberRemoved (PR sau).
 */
export const kickMember = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = kickMemberSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { spaceId, targetUid } = parsed.data;
    const callerUid = request.auth.uid;

    if (callerUid === targetUid) {
      throw new HttpsError(
        'invalid-argument',
        'Creator không thể kick chính mình — dùng deleteSpace hoặc transferOwnership',
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
      throw new HttpsError('permission-denied', 'Only creator can kick member');
    }

    const memberIds = Array.isArray(spaceData.memberIds)
      ? (spaceData.memberIds as string[])
      : [];
    if (!memberIds.includes(targetUid)) {
      throw new HttpsError('not-found', 'Target is not a member of this Space');
    }

    const batch = db.batch();

    batch.delete(
      db
        .collection('space_members')
        .doc(spaceId)
        .collection('members')
        .doc(targetUid),
    );

    batch.update(spaceRef, {
      memberIds: FieldValue.arrayRemove(targetUid),
      memberCount: FieldValue.increment(-1),
    });

    batch.update(db.collection('conversations').doc(spaceId), {
      participantIds: FieldValue.arrayRemove(targetUid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return { success: true };
  },
);

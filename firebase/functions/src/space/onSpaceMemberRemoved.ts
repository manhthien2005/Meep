import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * Trigger khi /space_members/{spaceId}/members/{uid} doc DELETE
 * (leaveSpace, kickMember, onSpaceDeleted cleanup).
 *
 * Decrement /users/{uid}.spaceCount. Mirror onSpaceMemberAdded — KHÔNG
 * touch /spaces/{spaceId}.memberCount vì CF đã update trong batch.
 *
 * Idempotent caveat: same as Added — at-least-once delivery. MVP accepted.
 */
export const onSpaceMemberRemoved = onDocumentDeleted(
  {
    document: 'space_members/{spaceId}/members/{uid}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const { spaceId, uid } = event.params;

    try {
      await getFirestore()
        .doc(`users/${uid}`)
        .set(
          { spaceCount: FieldValue.increment(-1) },
          { merge: true },
        );
      logger.info(`spaceCount-- for ${uid} (left ${spaceId})`);
    } catch (e) {
      logger.error(`onSpaceMemberRemoved failed for ${uid}/${spaceId}`, e);
    }
  },
);

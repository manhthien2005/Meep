import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * Trigger khi /space_members/{spaceId}/members/{uid} doc CREATE.
 *
 * Increment /users/{uid}.spaceCount cho member mới. KHÔNG touch
 * /spaces/{spaceId}.memberCount vì CF (`createSpace`, future addMember)
 * đã update trong batch — tránh double-count.
 *
 * Idempotent: dùng `set(merge)` với `FieldValue.increment(1)`. Firestore
 * trigger v2 mặc định at-least-once → cùng event re-fire sẽ
 * double-increment. Trade-off accepted cho MVP (spaceCount user-visible
 * minor, hiếm khi re-fire). Future: dùng deterministic doc id
 * /users/{uid}/space_count_events/{spaceId} + transaction để strict
 * idempotent.
 */
export const onSpaceMemberAdded = onDocumentCreated(
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
          { spaceCount: FieldValue.increment(1) },
          { merge: true },
        );
      logger.info(`spaceCount++ for ${uid} (joined ${spaceId})`);
    } catch (e) {
      logger.error(`onSpaceMemberAdded failed for ${uid}/${spaceId}`, e);
    }
  },
);

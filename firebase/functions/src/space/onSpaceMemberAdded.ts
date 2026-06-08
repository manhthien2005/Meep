import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * Idempotency guard: chỉ increment khi marker CHƯA tồn tại (event đầu tiên).
 * Pure để unit test không cần emulator.
 */
export function shouldCountJoin(markerExists: boolean): boolean {
  return !markerExists;
}

/**
 * Trigger khi /space_members/{spaceId}/members/{uid} doc CREATE.
 *
 * Increment /users/{uid}.spaceCount cho member mới. KHÔNG touch
 * /spaces/{spaceId}.memberCount vì CF (`createSpace`, future addMember)
 * đã update trong batch — tránh double-count.
 *
 * Idempotent (FUNC-SEC-002): Firestore trigger v2 at-least-once → cùng event
 * có thể re-fire. Marker doc /users/{uid}/space_count_events/{spaceId}
 * (deterministic ID) trong transaction đảm bảo increment đúng 1 lần: re-fire
 * thấy marker đã tồn tại → skip. onSpaceMemberRemoved xóa marker khi member
 * rời → cặp Added/Removed cân nhau. Marker dọn trong deleteAccount cascade.
 */
export const onSpaceMemberAdded = onDocumentCreated(
  {
    document: 'space_members/{spaceId}/members/{uid}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const { spaceId, uid } = event.params;
    const db = getFirestore();
    const userRef = db.doc(`users/${uid}`);
    const markerRef = db.doc(`users/${uid}/space_count_events/${spaceId}`);

    try {
      await db.runTransaction(async (tx) => {
        const marker = await tx.get(markerRef);
        if (!shouldCountJoin(marker.exists)) return;
        tx.set(
          userRef,
          { spaceCount: FieldValue.increment(1) },
          { merge: true },
        );
        tx.set(markerRef, { joinedAt: FieldValue.serverTimestamp() });
      });
      logger.info(`spaceCount++ for ${uid} (joined ${spaceId})`);
    } catch (e) {
      logger.error(`onSpaceMemberAdded failed for ${uid}/${spaceId}`, e);
    }
  },
);

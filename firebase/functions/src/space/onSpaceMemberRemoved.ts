import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * Idempotency guard: chỉ decrement khi marker CÒN tồn tại (chưa xử lý leave).
 * Pure để unit test không cần emulator. Mirror shouldCountJoin nghịch đảo.
 */
export function shouldCountLeave(markerExists: boolean): boolean {
  return markerExists;
}

/**
 * Trigger khi /space_members/{spaceId}/members/{uid} doc DELETE
 * (leaveSpace, kickMember, onSpaceDeleted cleanup).
 *
 * Decrement /users/{uid}.spaceCount. Mirror onSpaceMemberAdded — KHÔNG
 * touch /spaces/{spaceId}.memberCount vì CF đã update trong batch.
 *
 * Idempotent (FUNC-SEC-002): transaction xóa marker
 * /users/{uid}/space_count_events/{spaceId} + decrement đúng 1 lần. Re-fire
 * thấy marker đã mất → skip. Cặp với onSpaceMemberAdded (set marker) nên
 * spaceCount luôn khớp số space thực tế.
 */
export const onSpaceMemberRemoved = onDocumentDeleted(
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
        if (!shouldCountLeave(marker.exists)) return;
        tx.set(
          userRef,
          { spaceCount: FieldValue.increment(-1) },
          { merge: true },
        );
        tx.delete(markerRef);
      });
      logger.info(`spaceCount-- for ${uid} (left ${spaceId})`);
    } catch (e) {
      logger.error(`onSpaceMemberRemoved failed for ${uid}/${spaceId}`, e);
    }
  },
);

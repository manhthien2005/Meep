import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * Trigger khi /spaces/{spaceId}.deletedAt từ null → timestamp (soft delete).
 *
 * Cleanup:
 * 1. Xóa tất cả /space_members/{spaceId}/members/* (triggers
 *    onSpaceMemberRemoved cho mỗi member → decrement spaceCount)
 * 2. Update /conversations/{spaceId}.status = 'deleted'
 *
 * Posts KHÔNG xóa — quyết định product (parity Locket): post đã share
 * thì lưu vĩnh viễn trong feed members. isMember() Firestore rule sẽ
 * fail cho non-members → post tự ẩn cho người không còn quyền.
 *
 * Idempotent: chỉ trigger khi transition null → non-null. Trigger lại
 * (re-update deletedAt) sẽ no-op vì batch delete trên empty subcollection.
 */
export const onSpaceDeleted = onDocumentUpdated(
  { document: 'spaces/{spaceId}', region: 'asia-southeast1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Chỉ chạy khi transition null → non-null deletedAt.
    if (before.deletedAt != null || after.deletedAt == null) return;

    const { spaceId } = event.params;
    const db = getFirestore();

    try {
      // Step 1: Xóa /space_members/{spaceId}/members/*
      const membersSnap = await db
        .collection('space_members')
        .doc(spaceId)
        .collection('members')
        .get();

      if (membersSnap.size > 0) {
        // Batch 499 — Space max 10 members nên 1 batch luôn đủ, nhưng
        // giữ pattern an toàn cho future scale.
        const batches: FirebaseFirestore.WriteBatch[] = [];
        let batch = db.batch();
        let opCount = 0;

        for (const doc of membersSnap.docs) {
          batch.delete(doc.ref);
          opCount++;
          if (opCount === 499) {
            batches.push(batch);
            batch = db.batch();
            opCount = 0;
          }
        }
        if (opCount > 0) batches.push(batch);
        await Promise.all(batches.map((b) => b.commit()));
      }

      // Step 2: Mark conversation as deleted.
      await db.collection('conversations').doc(spaceId).set(
        {
          status: 'deleted',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      logger.info(
        `onSpaceDeleted: cleaned ${membersSnap.size} members + conversation for ${spaceId}`,
      );
    } catch (e) {
      logger.error(`onSpaceDeleted failed for ${spaceId}`, e);
    }
  },
);

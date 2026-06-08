import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

/**
 * Clean up friend-related data when a friendship is deleted.
 *
 * Steps:
 * 1. Decrement friendCount for uid1 and uid2 using FieldValue.increment(-1)
 * 2. Update /conversations/{pairId}.status = 'unfriended' if conversation exists
 * 3. Batch delete cross-feed entries:
 *    - Delete /users/{uid1}/feed/{postId} WHERE authorId == uid2 AND spaceIds == []
 *    - Delete /users/{uid2}/feed/{postId} WHERE authorId == uid1 AND spaceIds == []
 * 4. Preserve Space posts (spaceIds non-empty)
 *
 * Note: This CF owns feed cleanup (Home/Camera/Feed module concern).
 * CF is idempotent: re-running after partial failure produces same final state.
 */
export const onFriendshipDeleted = onDocumentDeleted(
  { document: "friendships/{pairId}", region: "asia-southeast1" },
  async (event) => {
    const pairId = event.params.pairId;
    const friendshipData = event.data?.data();

    if (!friendshipData) {
      logger.warn(`onFriendshipDeleted: no data for ${pairId}`);
      return;
    }

    const uid1 = String(friendshipData.uid1);
    const uid2 = String(friendshipData.uid2);
    const db = getFirestore();

    // Step 1: Decrement friendCount for both users (idempotent with FieldValue.increment)
    // Note: FieldValue.increment(-1) is atomic and idempotent per-document.
    // Using Promise.all for parallel execution is safe here because each update
    // operates on a different document. No transaction needed.
    await Promise.all([
      db
        .collection("users")
        .doc(uid1)
        .update({
          friendCount: FieldValue.increment(-1),
        }),
      db
        .collection("users")
        .doc(uid2)
        .update({
          friendCount: FieldValue.increment(-1),
        }),
    ]);

    // Step 2: Update conversation status to 'unfriended' (if exists)
    const conversationRef = db.collection("conversations").doc(pairId);
    const conversationDoc = await conversationRef.get();

    if (conversationDoc.exists) {
      await conversationRef.update({
        status: "unfriended",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Step 3: Batch delete cross-feed entries (preserve Space posts)
    // Delete uid1's feed entries authored by uid2 (non-Space only)
    const uid1FeedQuery = db
      .collection("users")
      .doc(uid1)
      .collection("feed")
      .where("authorId", "==", uid2)
      .where("spaceIds", "==", []);

    // Delete uid2's feed entries authored by uid1 (non-Space only)
    const uid2FeedQuery = db
      .collection("users")
      .doc(uid2)
      .collection("feed")
      .where("authorId", "==", uid1)
      .where("spaceIds", "==", []);

    const [uid1FeedSnapshot, uid2FeedSnapshot] = await Promise.all([
      uid1FeedQuery.get(),
      uid2FeedQuery.get(),
    ]);

    // Batch delete feed entries
    const batch = db.batch();
    let deleteCount = 0;

    uid1FeedSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deleteCount++;
    });

    uid2FeedSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deleteCount++;
    });

    if (deleteCount > 0) {
      await batch.commit();
    }
  },
);

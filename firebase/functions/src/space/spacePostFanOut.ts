import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';

interface SpacePost {
  postId: string;
  authorId: string;
  authorName: string;
  spaceId: string;
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Helper: fan-out 1 Space post sang feed của tất cả Space members + FCM.
 *
 * Option A: KhoaLND import từ feed/onPostCreated.ts và gọi
 * `await spacePostFanOut(post)` khi `post.spaceId != null` — KHÔNG có
 * Firestore trigger riêng cho Space post (single source of truth).
 *
 * Steps:
 * 1. Đọc /space_members/{spaceId}/members/* → memberUids
 * 2. Verify Space exists + chưa soft-delete. Nếu đã deleted → log + return
 *    (không throw — post đã ghi rồi, không revert được).
 * 3. Batch fan-out /users/{uid}/feed/{postId} cho TẤT CẢ members (kể cả
 *    author — author vẫn thấy post của mình trên Space feed).
 * 4. FCM cho members trừ author.
 *
 * Note: post.spaceId trùng /spaces doc — không phải pairId. spaceId là
 * key consistent với conversationId của group chat.
 */
export async function spacePostFanOut(post: SpacePost): Promise<void> {
  const db = getFirestore();
  const { postId, authorId, authorName, spaceId } = post;

  // Step 1: Verify Space tồn tại + chưa deleted.
  const spaceDoc = await db.collection('spaces').doc(spaceId).get();
  if (!spaceDoc.exists) {
    logger.warn(`spacePostFanOut: Space ${spaceId} not found for post ${postId}`);
    return;
  }
  const spaceData = spaceDoc.data();
  if (spaceData?.deletedAt != null) {
    logger.warn(`spacePostFanOut: Space ${spaceId} already deleted`);
    return;
  }

  // Step 2: Load members từ subcollection. Authoritative source —
  // memberIds array trên /spaces có thể stale 1-2s sau leaveSpace batch.
  const membersSnap = await db
    .collection('space_members')
    .doc(spaceId)
    .collection('members')
    .get();

  const memberUids: string[] = [];
  for (const doc of membersSnap.docs) {
    const uid: unknown = doc.data().uid;
    if (typeof uid === 'string' && uid.length > 0) {
      memberUids.push(uid);
    }
  }

  if (memberUids.length === 0) {
    logger.warn(`spacePostFanOut: Space ${spaceId} has 0 members for post ${postId}`);
    return;
  }

  // Step 3: Fan-out feed docs. Batch 499 (giữ lề 1 op an toàn dưới 500
  // limit Firestore). Worst case: 10 members → 1 batch đủ.
  const feedDoc = {
    postId,
    authorId,
    spaceId,
    createdAt: post.createdAt,
  };

  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let opCount = 0;

  for (const uid of memberUids) {
    batch.set(db.doc(`users/${uid}/feed/${postId}`), feedDoc);
    opCount++;
    if (opCount === 499) {
      batches.push(batch);
      batch = db.batch();
      opCount = 0;
    }
  }
  if (opCount > 0) batches.push(batch);
  await Promise.all(batches.map((b) => b.commit()));

  // Step 4: FCM cho members TRỪ author.
  const recipientUids = memberUids.filter((uid) => uid !== authorId);
  if (recipientUids.length === 0) return;

  await sendFcmToSpaceMembers(
    db,
    recipientUids,
    authorId,
    authorName,
    postId,
    spaceId,
    typeof spaceData?.name === 'string' ? spaceData.name : 'Space',
  );
}

async function sendFcmToSpaceMembers(
  db: FirebaseFirestore.Firestore,
  recipientUids: string[],
  authorId: string,
  authorName: string,
  postId: string,
  spaceId: string,
  spaceName: string,
): Promise<void> {
  const tokenDocs = await Promise.all(
    recipientUids.map((uid) =>
      db.collection(`users/${uid}/private`).doc('fcm').get(),
    ),
  );

  const tokens: string[] = [];
  for (const doc of tokenDocs) {
    if (!doc.exists) continue;
    const t: unknown = doc.data()?.token;
    if (typeof t === 'string' && t.length > 0) tokens.push(t);
  }
  if (tokens.length === 0) return;

  try {
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `${authorName} → ${spaceName}`,
        body: 'Vừa chia sẻ ảnh mới trong Space',
      },
      data: {
        type: 'new_space_post',
        postId,
        authorId,
        spaceId,
      },
      android: {
        notification: { channelId: 'posts' },
      },
    });
  } catch (e) {
    logger.error('spacePostFanOut FCM failed', e);
  }
}

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getAuth } from 'firebase-admin/auth';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

/**
 * Schema validation for deleteAccount CF input.
 *
 * Không có input nào cần — uid lấy từ `request.auth.uid`. Schema chỉ để
 * tuân thủ CLAUDE.md rule "every callable starts with safeParse" và reject
 * gracefully nếu client gửi junk.
 */
const deleteAccountSchema = z.unknown();

/**
 * Firestore batch limit: 500 writes/batch (admin SDK). Dùng 499 để chừa 1 slot
 * an toàn cho race case (mặc dù trong cascade này không có race nhưng giữ
 * consistent với pattern onSpaceDeleted).
 */
const BATCH_LIMIT = 499;

/**
 * Delete tất cả documents matching `query` trong nhiều batch.
 *
 * Repeat get(limit) → batch.delete() → commit cho đến khi snap.empty.
 * Idempotent: lần 2 gọi sẽ thấy empty ngay → no-op.
 *
 * Trả về tổng số docs đã xóa (chỉ dùng để log, không ảnh hưởng flow).
 */
async function deleteCollectionInBatches(
  query: FirebaseFirestore.Query,
  description: string,
): Promise<number> {
  let totalDeleted = 0;
  while (true) {
    const snap = await query.limit(BATCH_LIMIT).get();
    if (snap.empty) break;

    const batch = getFirestore().batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    totalDeleted += snap.size;

    // snap.size < BATCH_LIMIT → đã hết, không cần round nữa.
    if (snap.size < BATCH_LIMIT) break;
  }
  if (totalDeleted > 0) {
    logger.info({ deleted: totalDeleted }, `deleteAccount: cleared ${description}`);
  }
  return totalDeleted;
}

/**
 * Soft-delete conversations user đang là participant: set status='deleted'.
 *
 * KHÔNG xóa conversation doc — partner còn cần đọc lịch sử (parity Locket).
 * Khi cả 2 participants đều deleted → conversation effectively orphaned, có
 * thể GC sau (chưa scope MVP).
 */
async function softDeleteConversations(uid: string): Promise<number> {
  const db = getFirestore();
  const now = FieldValue.serverTimestamp();
  let totalUpdated = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  while (true) {
    let query: FirebaseFirestore.Query = db
      .collection('conversations')
      .where('participantIds', 'array-contains', uid)
      .limit(BATCH_LIMIT);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, { status: 'deleted', updatedAt: now });
    }
    await batch.commit();
    totalUpdated += snap.size;

    if (snap.size < BATCH_LIMIT) break;
    lastDoc = snap.docs[snap.docs.length - 1];
  }
  if (totalUpdated > 0) {
    logger.info(
      { updated: totalUpdated },
      'deleteAccount: soft-deleted conversations',
    );
  }
  return totalUpdated;
}

/**
 * Cascade-delete user account: Storage → Firestore → Auth.
 *
 * Thứ tự BẮT BUỘC (acceptance T7 #119):
 *   1. Storage prefixes: posts/{uid}/, avatars/{uid}/, diary/{uid}/
 *   2. Firestore subcollections của /users/{uid}: feed, notifications,
 *      fcmTokens, private (xóa trước parent doc — Firestore không cascade)
 *   3. Cross-collection queries:
 *      a. diary where authorUid == uid
 *      b. posts where authorId == uid (triggers onPostDeleted cho mỗi post
 *         → cross-feed cleanup tự động)
 *      c. friendships where members array-contains uid (triggers
 *         onFriendshipDeleted → cross-feed cleanup + friendCount decrement
 *         cho friend còn lại)
 *      d. friend_requests where senderId == uid (parallel)
 *         friend_requests where receiverId == uid (parallel)
 *      e. blocks where blockerUid == uid (parallel)
 *         blocks where blockedUid == uid (parallel)
 *   4. Conversations soft-delete (status='deleted', không hard delete)
 *   5. Username reverse-lookup: read /users/{uid}.username → delete
 *      /usernames/{username}
 *   6. /users/{uid} document
 *   7. admin.auth().deleteUser(uid) — CUỐI CÙNG
 *
 * Idempotent guarantees:
 * - Storage bucket.deleteFiles(prefix) no-op nếu prefix empty
 * - Firestore deleteCollectionInBatches no-op nếu query empty
 * - Username + user doc check existence trước delete
 * - Auth deleteUser catch 'auth/user-not-found' → skip (retry case)
 *
 * Failure safety: nếu CF crash giữa chừng, Auth account còn → user có thể
 * login retry. Order Auth LAST đảm bảo Storage/Firestore cleanup không bị
 * mất quyền truy cập (Auth gone = không re-auth được).
 *
 * Pre-condition: client (DeleteAccountDialog) phải reauthenticate trước
 * khi gọi CF này (Firebase Auth requires-recent-login policy). CF chỉ check
 * `request.auth` exists, không enforce recent-login (Firebase SDK enforce).
 */
export const deleteAccount = onCall(
  {
    region: 'asia-southeast1',
    // Cascade có thể tốn 1-2 phút với user nhiều posts. 540s = max v2 hard
    // limit. Memory bump cho Storage list+delete (mỗi page 1000 files).
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = deleteAccountSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const uid = request.auth.uid;
    const db = getFirestore();
    const bucket = getStorage().bucket();

    logger.info({ uid }, 'deleteAccount: cascade starting');

    // Step 1: Storage cleanup (parallel — 3 prefixes độc lập).
    // bucket.deleteFiles({ prefix }) idempotent: empty prefix = no-op, no throw.
    await Promise.all([
      bucket.deleteFiles({ prefix: `posts/${uid}/` }),
      bucket.deleteFiles({ prefix: `avatars/${uid}/` }),
      bucket.deleteFiles({ prefix: `diary/${uid}/` }),
    ]);
    logger.info({ uid }, 'deleteAccount: storage cleared');

    // Step 2: Subcollections của /users/{uid} (parallel — independent).
    const userRef = db.collection('users').doc(uid);
    await Promise.all([
      deleteCollectionInBatches(userRef.collection('feed'), 'users/feed'),
      deleteCollectionInBatches(
        userRef.collection('notifications'),
        'users/notifications',
      ),
      deleteCollectionInBatches(
        userRef.collection('fcmTokens'),
        'users/fcmTokens',
      ),
      deleteCollectionInBatches(userRef.collection('private'), 'users/private'),
    ]);

    // Step 3a-3c: Cross-collection queries có Firestore trigger downstream
    // → sequential để trigger fire trong predictable order (giúp debug nếu
    // trigger fail).
    await deleteCollectionInBatches(
      db.collection('diary').where('authorUid', '==', uid),
      'diary entries',
    );
    await deleteCollectionInBatches(
      db.collection('posts').where('authorId', '==', uid),
      'posts',
    );
    await deleteCollectionInBatches(
      db.collection('friendships').where('members', 'array-contains', uid),
      'friendships',
    );

    // Step 3d-3e: friend_requests + blocks không có trigger downstream →
    // parallel an toàn. Mỗi collection 2 query (sender/receiver,
    // blocker/blocked) vì Firestore chỉ hỗ trợ OR qua `in` (max 10 values)
    // — query separately đơn giản hơn.
    await Promise.all([
      deleteCollectionInBatches(
        db.collection('friend_requests').where('senderId', '==', uid),
        'friend_requests as sender',
      ),
      deleteCollectionInBatches(
        db.collection('friend_requests').where('receiverId', '==', uid),
        'friend_requests as receiver',
      ),
      deleteCollectionInBatches(
        db.collection('blocks').where('blockerUid', '==', uid),
        'blocks as blocker',
      ),
      deleteCollectionInBatches(
        db.collection('blocks').where('blockedUid', '==', uid),
        'blocks as blocked',
      ),
    ]);

    // Step 4: Soft-delete conversations.
    await softDeleteConversations(uid);

    // Step 5: Username reverse-lookup + delete.
    // Read user doc TRƯỚC khi delete (step 6) để biết username field.
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      const data = userSnap.data() as Record<string, unknown> | undefined;
      const usernameField = data?.username;
      if (typeof usernameField === 'string' && usernameField.length > 0) {
        const usernameRef = db.collection('usernames').doc(usernameField);
        const usernameSnap = await usernameRef.get();
        if (usernameSnap.exists) {
          await usernameRef.delete();
          logger.info(
            { uid, username: usernameField },
            'deleteAccount: username released',
          );
        }
      }
    }

    // Step 6: /users/{uid} document.
    if (userSnap.exists) {
      await userRef.delete();
    }

    // Step 7: Auth account (LAST — idempotent qua catch user-not-found).
    try {
      await getAuth().deleteUser(uid);
      logger.info({ uid }, 'deleteAccount: auth account deleted');
    } catch (e: unknown) {
      const code =
        e !== null && typeof e === 'object' && 'code' in e
          ? String(e.code)
          : '';
      if (code === 'auth/user-not-found') {
        // Retry case: auth already deleted, các step trước cũng đã xong.
        logger.info({ uid }, 'deleteAccount: auth user not found, retry skip');
      } else {
        throw e;
      }
    }

    return { success: true };
  },
);

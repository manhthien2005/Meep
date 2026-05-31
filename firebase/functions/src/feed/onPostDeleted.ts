import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

/**
 * When a post is deleted:
 * 1. Batch-delete all /users/{uid}/feed/{postId} docs (all recipients)
 * 2. Decrement postCount on /users/{authorId}
 * 3. Delete Storage image at posts/{uid}/{postId}/photo.jpg
 * 4. Delete reactions subcollection /posts/{postId}/reactions/*
 */
export const onPostDeleted = onDocumentDeleted(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  async (event) => {
    const post = event.data?.data();
    if (!post) return;

    const db = getFirestore();
    const { postId } = event.params;
    const authorId = post.authorId as string;

    await Promise.all([
      _deleteFeedDocs(db, postId),
      _decrementPostCount(db, authorId),
      _deleteStorageFile(authorId, postId),
      _deleteReactions(db, postId),
    ]);
  },
);

async function _deleteFeedDocs(
  db: FirebaseFirestore.Firestore,
  postId: string,
): Promise<void> {
  // Collectiongroup query across all /users/*/feed/{postId}
  const snaps = await db
    .collectionGroup('feed')
    .where('postId', '==', postId)
    .get();

  if (snaps.empty) return;

  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of snaps.docs) {
    batch.delete(doc.ref);
    count++;
    if (count === 499) {
      batches.push(batch);
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(batch);
  await Promise.all(batches.map((b) => b.commit()));
}

async function _decrementPostCount(
  db: FirebaseFirestore.Firestore,
  authorId: string,
): Promise<void> {
  await db.doc(`users/${authorId}`).update({
    postCount: FieldValue.increment(-1),
  });
}

async function _deleteStorageFile(
  authorId: string,
  postId: string,
): Promise<void> {
  try {
    const bucket = getStorage().bucket();
    await bucket.file(`posts/${authorId}/${postId}/photo.jpg`).delete();
  } catch (e: unknown) {
    // Not-found is acceptable (may have been deleted already)
    const code = (e as { code?: number }).code;
    if (code !== 404) logger.error('Storage delete failed', e);
  }
}

async function _deleteReactions(
  db: FirebaseFirestore.Firestore,
  postId: string,
): Promise<void> {
  const snap = await db.collection(`posts/${postId}/reactions`).get();
  if (snap.empty) return;

  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

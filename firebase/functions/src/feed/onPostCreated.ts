import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { spacePostFanOut } from '../space/spacePostFanOut.js';

interface PostData {
  postId: string;
  authorId: string;
  authorName: string;
  authorAvatarUrl?: string;
  // Single camera: imageUrl set. Dual camera: backImageUrl/frontImageUrl set.
  imageUrl?: string;
  backImageUrl?: string;
  frontImageUrl?: string;
  isDualCamera?: boolean;
  caption?: string;
  captionType?: string;
  audienceType: 'all' | 'select';
  audienceUids: string[];
  spaceId?: string;
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Fan-out feed + increment postCount + FCM notification.
 * Single function — do not create a separate one in notification.md (H10).
 *
 * Guard: if post.spaceId != null → skip friend fan-out + FCM
 *   (Space CF onSpacePostCreated handles Space posts).
 *   Still increments postCount for all post types.
 */
export const onPostCreated = onDocumentCreated(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  async (event) => {
    const post = event.data?.data() as PostData | undefined;
    if (!post) return;

    const db = getFirestore();
    const { postId } = event.params;
    const { authorId, audienceType, audienceUids, spaceId } = post;

    // 1. Always increment postCount on author (set merge — safe if field missing)
    await db.doc(`users/${authorId}`).set(
      { postCount: FieldValue.increment(1) },
      { merge: true },
    );

    // 2. Space post — delegate sang spacePostFanOut helper (Option A) thay
    // vì fan-out tới friends. Helper đọc /space_members để xác định members.
    if (spaceId != null && spaceId !== '') {
      await spacePostFanOut({
        postId,
        authorId,
        authorName: post.authorName,
        spaceId,
        createdAt: post.createdAt,
      });
      return;
    }

    // 3. Determine recipients — friends/selected audience PLUS the author
    //    themselves, so the author always sees their own post in their feed.
    const friendUids = audienceType === 'select'
      ? audienceUids
      : await _getFriendUids(db, authorId);

    // Dedupe in case the author already appears in the audience list.
    const recipientUids = [...new Set([authorId, ...friendUids])];

    if (recipientUids.length === 0) return;

    // 4. Fan-out feed docs in batches of 500
    const feedDoc = {
      postId,
      authorId,
      spaceId: spaceId ?? null,
      createdAt: post.createdAt,
    };

    const batches: FirebaseFirestore.WriteBatch[] = [];
    let batch = db.batch();
    let opCount = 0;

    for (const uid of recipientUids) {
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

    // 5. FCM fan-out — push to friends only (never notify the author about
    //    their own post). The author is in recipientUids for the feed, not here.
    await _sendFcmToRecipients(db, friendUids, authorId, post.authorName, postId);
  },
);

async function _getFriendUids(
  db: FirebaseFirestore.Firestore,
  authorId: string,
): Promise<string[]> {
  const snap = await db
    .collection('friendships')
    .where('members', 'array-contains', authorId)
    .get();

  return snap.docs.flatMap((doc) => {
    const data = doc.data();
    return (data.members as string[]).filter((uid: string) => uid !== authorId);
  });
}

async function _sendFcmToRecipients(
  db: FirebaseFirestore.Firestore,
  recipientUids: string[],
  authorId: string,
  authorName: string,
  postId: string,
): Promise<void> {
  // Batch load FCM tokens
  const tokenPromises = recipientUids.map((uid) =>
    db.collection(`users/${uid}/private`).doc('fcm').get(),
  );
  const tokenDocs = await Promise.all(tokenPromises);

  const tokens: string[] = [];
  for (const doc of tokenDocs) {
    if (!doc.exists) continue;
    const t = doc.data()?.token as string | undefined;
    if (t != null && t !== '') tokens.push(t);
  }

  if (tokens.length === 0) return;

  try {
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: authorName,
        body: 'Vừa đăng một ảnh mới',
      },
      data: {
        type: 'new_post',
        postId,
        authorId,
      },
      android: {
        notification: { channelId: 'posts' },
      },
    });
  } catch (e) {
    logger.error('FCM multicast failed', e);
  }
}

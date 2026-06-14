import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { sendFcmToUser } from '../notification/_fcm.js';
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
  /// Multi-Space (Branch 2+). Empty = post All-friends. Mỗi entry trong
  /// array fan-out riêng qua spacePostFanOut.
  spaceIds?: string[];
  createdAt: FirebaseFirestore.Timestamp;
}

export function postNotificationRecipients(
  authorId: string,
  recipientUids: string[],
): string[] {
  const seen = new Set<string>();
  const sanitized: string[] = [];

  for (const uid of recipientUids) {
    const trimmed = uid.trim();
    if (trimmed.length === 0 || trimmed === authorId || seen.has(trimmed)) {
      continue;
    }
    seen.add(trimmed);
    sanitized.push(trimmed);
  }

  return sanitized;
}

export function postFeedRecipients(
  authorId: string,
  recipientUids: string[],
): string[] {
  return [authorId, ...postNotificationRecipients(authorId, recipientUids)];
}

/**
 * Fan-out feed + increment postCount + FCM notification.
 *
 * Post Space (spaceIds non-empty): loop từng Space → spacePostFanOut riêng
 * cho từng spaceId. Mỗi spaceId fan-out feed entry + FCM cho member của
 * Space đó. Post KHÔNG đi vào friend feed (Space post tách rời, dù author
 * có thể là friend của user khác).
 *
 * Post all-friends (spaceIds rỗng/missing): fan-out feed cho author +
 * audienceUids (select) hoặc tất cả friends (all). FCM push cho friends.
 */
export const onPostCreated = onDocumentCreated(
  { document: 'posts/{postId}', region: 'asia-southeast1' },
  async (event) => {
    const post = event.data?.data() as PostData | undefined;
    if (!post) return;

    const db = getFirestore();
    const { postId } = event.params;
    const { authorId, audienceType, audienceUids } = post;
    const spaceIds = post.spaceIds ?? [];

    // 1. Always increment postCount on author (set merge — safe if field missing)
    await db.doc(`users/${authorId}`).set(
      { postCount: FieldValue.increment(1) },
      { merge: true },
    );

    // 2. Space post — delegate sang spacePostFanOut helper cho TỪNG Space
    // trong spaceIds. Mỗi Space fan-out riêng (member của Space A ≠ Space B).
    if (spaceIds.length > 0) {
      await Promise.all(
        spaceIds.map((spaceId) =>
          spacePostFanOut({
            postId,
            authorId,
            authorName: post.authorName,
            spaceId,
            createdAt: post.createdAt,
          }),
        ),
      );
      return;
    }

    // 3. Determine recipients — friends/selected audience PLUS the author
    //    themselves, so the author always sees their own post in their feed.
    const candidateFriendUids = audienceType === 'select'
      ? audienceUids
      : await _getFriendUids(db, authorId);
    const friendUids = postNotificationRecipients(
      authorId,
      candidateFriendUids,
    );

    // Feed includes the author for own-feed visibility; FCM never does.
    const recipientUids = postFeedRecipients(authorId, friendUids);

    if (recipientUids.length === 0) return;

    // 4. Fan-out feed docs in batches of 500
    const feedDoc = {
      postId,
      authorId,
      spaceIds: [] as string[],
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

/**
 * Delegate per-recipient FCM dispatch sang `sendFcmToUser`, vốn đọc token từ
 * `/users/{uid}/fcmTokens` — đúng path mobile save vào
 * (firebase_notification_repository.dart:saveFcmToken). Trước đây hàm này tự
 * đọc `/users/{uid}/private/fcm` → token luôn rỗng → post notification không
 * bao giờ tới friend. Để 1 helper duy nhất quản lý token lookup + prune token
 * chết, tránh path bị lệch khi mobile đổi format trong tương lai.
 */
async function _sendFcmToRecipients(
  db: FirebaseFirestore.Firestore,
  recipientUids: string[],
  authorId: string,
  authorName: string,
  postId: string,
): Promise<void> {
  if (recipientUids.length === 0) return;
  const payload = {
    title: authorName,
    body: 'Vừa đăng một ảnh mới',
    data: {
      type: 'new_post',
      postId,
      authorId,
    },
    channelId: 'posts',
  };
  await Promise.all(
    recipientUids.map((uid) => sendFcmToUser(db, uid, payload)),
  );
}

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendFcmToUser } from './_fcm.js';
import { isAlreadyExists, readDisplayName } from './_helpers.js';

interface ReactionData {
  reactorName?: unknown;
  emoji?: unknown;
}

interface PostData {
  authorId?: unknown;
}

/**
 * Notify the post author when someone reacts to their photo.
 *
 * Triggers on /posts/{postId}/reactions/{reactorUid} create. We never notify
 * the author of their own reaction — short-circuit when reactorId equals the
 * post's authorId.
 *
 * `reactorUid` comes from the path param, not the doc body — firestore.rules:154
 * guarantees `request.auth.uid == reactorUid == doc.id`, so the path param
 * is the canonical id.
 *
 * Reaction docs denormalize `reactorName` (firestore.rules:158 whitelists
 * it as updatable), but we fall back to /users/{reactorUid}.displayName when
 * absent — older docs written before denormalization may not have it.
 *
 * Idempotent doc id: `reaction_{postId}_{reactorUid}`. Twice-fired triggers
 * collide on `.create()` and exit without re-pushing.
 */
export const onReactionCreated = onDocumentCreated(
  {
    document: 'posts/{postId}/reactions/{reactorUid}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const raw = event.data?.data() as ReactionData | undefined;
    if (!raw) {
      logger.warn('[REACTION-DEBUG] Trigger nổ nhưng event.data rỗng → bỏ qua');
      return;
    }

    const { postId, reactorUid: reactorId } = event.params;
    logger.info(
      { postId, reactorId },
      '[REACTION-DEBUG] Trigger onReactionCreated bắt đầu chạy',
    );

    const emoji = typeof raw.emoji === 'string' ? raw.emoji : '';
    if (!emoji) {
      logger.warn('[REACTION-DEBUG] Reaction thiếu emoji → bỏ qua', { postId, reactorId });
      return;
    }

    const db = getFirestore();
    const postSnap = await db.doc(`posts/${postId}`).get();
    if (!postSnap.exists) {
      logger.warn(
        { postId, reactorId },
        '[REACTION-DEBUG] Post không tồn tại (có thể đã xóa) → bỏ qua notification',
      );
      return;
    }
    const post = postSnap.data() as PostData | undefined;
    const authorId = typeof post?.authorId === 'string' ? post.authorId : '';
    if (!authorId) {
      logger.warn('[REACTION-DEBUG] Post không có authorId → bỏ qua', { postId });
      return;
    }

    if (isSelfReaction(reactorId, authorId)) {
      logger.info(
        { postId, reactorId },
        '[REACTION-DEBUG] User react vào post của chính mình → không gửi thông báo',
      );
      return;
    }

    // Denormalized name preferred; fall back to a fresh /users read.
    let reactorName =
      typeof raw.reactorName === 'string' && raw.reactorName.length > 0
        ? raw.reactorName
        : '';
    if (!reactorName) {
      const reactorSnap = await db.doc(`users/${reactorId}`).get();
      reactorName = readDisplayName(reactorSnap.data());
    }

    const title = `${reactorName} đã react vào ảnh của bạn`;
    const body = emoji;
    const data: Record<string, string> = {
      type: 'reaction',
      postId,
      reactorId,
    };

    const notifRef = db.doc(
      `users/${authorId}/notifications/reaction_${postId}_${reactorId}`,
    );
    try {
      await notifRef.create({
        type: 'reaction',
        title,
        body,
        data,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      logger.info(
        { authorId, postId, reactorId },
        '[REACTION-DEBUG] Đã tạo notification doc trong Firestore, chuẩn bị gửi FCM',
      );
    } catch (e) {
      if (isAlreadyExists(e)) {
        logger.info('[REACTION-DEBUG] Notification đã tồn tại (trigger fire 2 lần) → bỏ qua', {
          postId,
          reactorId,
        });
        return;
      }
      logger.error('[REACTION-DEBUG] Lỗi khi tạo notification doc', { postId, reactorId, error: e });
      throw e;
    }

    await sendFcmToUser(db, authorId, {
      title,
      body,
      data,
      channelId: 'reaction',
    });
    logger.info(
      { authorId, postId, reactorId },
      '[REACTION-DEBUG] Đã gọi xong sendFcmToUser',
    );
  },
);

/**
 * The author shouldn't get pinged when they react to their own post. This
 * is the only guard on the trigger — other reaction-permission checks live
 * in firestore.rules:152 (only authenticated user matching reactorUid can
 * create the doc) and don't need to be re-validated here.
 *
 * Exported for unit tests.
 */
export function isSelfReaction(reactorId: string, authorId: string): boolean {
  return reactorId === authorId;
}

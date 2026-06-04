import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendFcmToUser } from './_fcm.js';
import { isAlreadyExists, readDisplayName } from './_helpers.js';

interface FriendRequestSnapshot {
  senderId?: unknown;
  receiverId?: unknown;
  status?: unknown;
}

/**
 * Notify the original sender once the receiver accepts the request.
 *
 * Triggers on every update to /friend_requests/{requestId}, then guards on
 * the status transition pending→accepted so we don't fire on declined,
 * cancelled, or no-op writes (createdAt touch, etc.).
 *
 * Receiver displayName comes from /users/{receiverId} because
 * friend_requests does not denormalize the name (see firestore.rules:181).
 *
 * Same idempotent doc-id strategy as onFriendRequestCreated — keyed on
 * requestId, .create() collides cleanly if the trigger double-fires.
 */
export const onFriendRequestAccepted = onDocumentUpdated(
  { document: 'friend_requests/{requestId}', region: 'asia-southeast1' },
  async (event) => {
    const before = event.data?.before.data() as FriendRequestSnapshot | undefined;
    const after = event.data?.after.data() as FriendRequestSnapshot | undefined;
    if (!before || !after) {
      logger.warn('[FRIEND-ACCEPT-DEBUG] Trigger nổ nhưng before/after rỗng → bỏ qua');
      return;
    }

    const { requestId } = event.params;
    logger.info(
      { requestId, beforeStatus: before.status, afterStatus: after.status },
      '[FRIEND-ACCEPT-DEBUG] Trigger onFriendRequestAccepted bắt đầu, kiểm tra transition',
    );

    if (!isAcceptedTransition(before.status, after.status)) {
      logger.info(
        { requestId, beforeStatus: before.status, afterStatus: after.status },
        '[FRIEND-ACCEPT-DEBUG] Không phải transition pending→accepted → bỏ qua',
      );
      return;
    }

    const senderId = typeof after.senderId === 'string' ? after.senderId : '';
    const receiverId = typeof after.receiverId === 'string' ? after.receiverId : '';
    if (!senderId || !receiverId) {
      logger.warn('[FRIEND-ACCEPT-DEBUG] Thiếu senderId hoặc receiverId → bỏ qua', {
        requestId,
        hasSender: !!senderId,
        hasReceiver: !!receiverId,
      });
      return;
    }

    const db = getFirestore();

    const receiverSnap = await db.doc(`users/${receiverId}`).get();
    const receiverName = readDisplayName(receiverSnap.data());
    logger.info(
      { requestId, senderId, receiverId, receiverName },
      '[FRIEND-ACCEPT-DEBUG] Đọc xong receiver, chuẩn bị notify sender',
    );

    const title = `${receiverName} đã chấp nhận lời mời kết bạn`;
    const body = 'Các bạn giờ là bạn bè trên Meep!';
    const data: Record<string, string> = {
      type: 'friend_accepted',
      friendUid: receiverId,
    };

    const notifRef = db.doc(
      `users/${senderId}/notifications/friend_accepted_${requestId}`,
    );
    try {
      await notifRef.create({
        type: 'friendAccepted',
        title,
        body,
        data,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      logger.info(
        { senderId, requestId },
        '[FRIEND-ACCEPT-DEBUG] Đã tạo notification doc, chuẩn bị gửi FCM cho sender',
      );
    } catch (e) {
      if (isAlreadyExists(e)) {
        logger.info('[FRIEND-ACCEPT-DEBUG] Notification đã tồn tại (trigger fire 2 lần) → bỏ qua', {
          requestId,
          senderId,
        });
        return;
      }
      logger.error('[FRIEND-ACCEPT-DEBUG] Lỗi khi tạo notification doc', { requestId, error: e });
      throw e;
    }

    await sendFcmToUser(db, senderId, {
      title,
      body,
      data,
      channelId: 'friend',
    });
    logger.info(
      { senderId, requestId },
      '[FRIEND-ACCEPT-DEBUG] Đã gọi xong sendFcmToUser',
    );
  },
);

/**
 * Only fire when `status` flips from non-accepted to accepted. Catches:
 *  - pending → accepted (the real case)
 *  - declined → accepted (shouldn't happen, but safe if it does)
 *
 * Rejects:
 *  - already-accepted → accepted (no-op update, e.g. updatedAt touch)
 *  - pending → declined
 *  - any non-string status (treat as no-op)
 *
 * Exported for unit tests.
 */
export function isAcceptedTransition(
  beforeStatus: unknown,
  afterStatus: unknown,
): boolean {
  if (typeof afterStatus !== 'string' || afterStatus !== 'accepted') return false;
  return beforeStatus !== 'accepted';
}

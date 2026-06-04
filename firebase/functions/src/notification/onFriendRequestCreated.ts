import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendFcmToUser } from './_fcm.js';
import { isAlreadyExists, readDisplayName } from './_helpers.js';

interface FriendRequestData {
  senderId: string;
  receiverId: string;
  status: string;
}

/**
 * Notify receiver when a new friend request is created.
 *
 * Flow:
 *  1. Read senderId/receiverId from the request doc.
 *  2. Read sender displayName from /users/{senderId} — friend_requests does
 *     not denormalize the name (firestore.rules:181 only requires the four
 *     id/status/timestamp fields).
 *  3. Idempotent write of /users/{receiverId}/notifications/friend_request_{requestId}
 *     via `.create()` — re-invocation of the trigger collides on the doc id
 *     and we exit cleanly without re-sending FCM.
 *  4. Multicast FCM via the shared helper; stale tokens get pruned in there.
 *
 * Receiver with zero fcm tokens → FCM step is a no-op (logout state). The
 * notification doc still lands so the in-app list shows it on next open.
 */
export const onFriendRequestCreated = onDocumentCreated(
  { document: 'friend_requests/{requestId}', region: 'asia-southeast1' },
  async (event) => {
    const raw = event.data?.data();
    if (!raw) {
      logger.warn('[FRIEND-REQ-DEBUG] Trigger nổ nhưng event.data rỗng → bỏ qua');
      return;
    }

    const { requestId } = event.params;
    logger.info(
      { requestId },
      '[FRIEND-REQ-DEBUG] Trigger onFriendRequestCreated bắt đầu chạy',
    );

    const data = raw as Partial<FriendRequestData>;
    const senderId = typeof data.senderId === 'string' ? data.senderId : '';
    const receiverId = typeof data.receiverId === 'string' ? data.receiverId : '';
    if (!senderId || !receiverId) {
      logger.warn('[FRIEND-REQ-DEBUG] Thiếu senderId hoặc receiverId → bỏ qua', {
        requestId,
        hasSender: !!senderId,
        hasReceiver: !!receiverId,
      });
      return;
    }

    const db = getFirestore();

    const senderSnap = await db.doc(`users/${senderId}`).get();
    const senderName = readDisplayName(senderSnap.data());
    logger.info(
      { requestId, senderId, receiverId, senderName },
      '[FRIEND-REQ-DEBUG] Đọc xong sender, chuẩn bị build payload',
    );

    const payload = buildFriendRequestPayload(senderName, requestId, senderId);

    const notifRef = db.doc(
      `users/${receiverId}/notifications/friend_request_${requestId}`,
    );
    try {
      await notifRef.create({
        type: 'friendRequest',
        title: payload.title,
        body: payload.body,
        data: payload.data,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      logger.info(
        { receiverId, requestId },
        '[FRIEND-REQ-DEBUG] Đã tạo notification doc, chuẩn bị gửi FCM',
      );
    } catch (e) {
      if (isAlreadyExists(e)) {
        logger.info('[FRIEND-REQ-DEBUG] Notification đã tồn tại (trigger fire 2 lần) → bỏ qua', {
          requestId,
          receiverId,
        });
        return;
      }
      logger.error('[FRIEND-REQ-DEBUG] Lỗi khi tạo notification doc', { requestId, error: e });
      throw e;
    }

    await sendFcmToUser(db, receiverId, {
      title: payload.title,
      body: payload.body,
      data: payload.data,
      channelId: 'friend',
    });
    logger.info(
      { receiverId, requestId },
      '[FRIEND-REQ-DEBUG] Đã gọi xong sendFcmToUser',
    );
  },
);

interface FriendRequestPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

/**
 * Pure builder — exported only for unit tests. Body copy is fixed and
 * title interpolates the sender's displayName. The FCM `data` payload
 * uses snake_case `type` so the Flutter deep-link router (T4) can route
 * without a translation layer.
 */
export function buildFriendRequestPayload(
  senderName: string,
  requestId: string,
  senderId: string,
): FriendRequestPayload {
  return {
    title: `${senderName} muốn kết bạn với bạn`,
    body: 'Tap để xem và chấp nhận',
    data: {
      type: 'friend_request',
      requestId,
      senderId,
    },
  };
}

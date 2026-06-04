import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendFcmToUser } from '../notification/_fcm.js';
import { isAlreadyExists, readDisplayName } from '../notification/_helpers.js';

interface MessageData {
  senderId?: unknown;
  text?: unknown;
  senderDisplayName?: unknown;
}

interface ConversationData {
  participantIds?: unknown;
}

/**
 * Notify mọi participant khác của conversation khi có message mới.
 *
 * Triggers on /conversations/{conversationId}/messages/{messageId} create.
 * Tier 1 Meep chỉ chat 1-1 nên thường chỉ 1 receiver, nhưng code path xử lý
 * `participantIds` tổng quát để khi mở group chat sau này không phải sửa lại.
 *
 * Idempotent: notification doc keyed `chat_{conversationId}_{messageId}` —
 * trigger fire 2 lần (Firestore guarantee at-least-once) collide trên
 * `.create()` và exit clean. FCM bị skip ở lần 2.
 *
 * `senderDisplayName` đã được mobile denormalize vào message doc
 * (firestore.rules:309 whitelist nó), fallback đọc /users/{senderId} cho
 * message cũ trước denormalize.
 */
export const onMessageCreated = onDocumentCreated(
  {
    document: 'conversations/{conversationId}/messages/{messageId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const raw = event.data?.data() as MessageData | undefined;
    if (!raw) {
      logger.warn('[CHAT-DEBUG] event.data rỗng → bỏ qua');
      return;
    }

    const { conversationId, messageId } = event.params;
    const senderId = typeof raw.senderId === 'string' ? raw.senderId : '';
    const text = typeof raw.text === 'string' ? raw.text : '';

    logger.info(
      { conversationId, messageId, senderId, textLength: text.length },
      '[CHAT-DEBUG] Trigger onMessageCreated bắt đầu chạy',
    );

    if (!senderId) {
      logger.warn('[CHAT-DEBUG] Message thiếu senderId → bỏ qua', {
        conversationId,
        messageId,
      });
      return;
    }

    const db = getFirestore();
    const convSnap = await db.doc(`conversations/${conversationId}`).get();
    if (!convSnap.exists) {
      logger.warn('[CHAT-DEBUG] Conversation không tồn tại → bỏ qua', {
        conversationId,
      });
      return;
    }

    const conv = convSnap.data() as ConversationData | undefined;
    const recipientUids = receiversOf(conv?.participantIds, senderId);
    if (recipientUids.length === 0) {
      logger.info(
        { conversationId, senderId },
        '[CHAT-DEBUG] Không còn participant nào khác sender → không cần gửi',
      );
      return;
    }

    let senderName =
      typeof raw.senderDisplayName === 'string' &&
      raw.senderDisplayName.length > 0
        ? raw.senderDisplayName
        : '';
    if (!senderName) {
      const senderSnap = await db.doc(`users/${senderId}`).get();
      senderName = readDisplayName(senderSnap.data());
    }

    const payload = {
      title: senderName,
      body: bodyPreview(text),
      data: {
        type: 'chat_message',
        conversationId,
        senderId,
        messageId,
      } as Record<string, string>,
      channelId: 'chat',
    };

    await Promise.all(
      recipientUids.map(async (receiverUid) => {
        const notifRef = db.doc(
          `users/${receiverUid}/notifications/chat_${conversationId}_${messageId}`,
        );
        try {
          await notifRef.create({
            type: 'chatMessage',
            title: payload.title,
            body: payload.body,
            data: payload.data,
            read: false,
            createdAt: FieldValue.serverTimestamp(),
          });
          logger.info(
            { receiverUid, conversationId, messageId },
            '[CHAT-DEBUG] Đã tạo notification doc cho receiver',
          );
        } catch (e) {
          if (isAlreadyExists(e)) {
            logger.info(
              '[CHAT-DEBUG] Notification đã tồn tại (trigger fire 2 lần) → bỏ qua FCM',
              { receiverUid, messageId },
            );
            return;
          }
          logger.error('[CHAT-DEBUG] Lỗi tạo notification doc cho receiver', {
            receiverUid,
            messageId,
            error: e,
          });
          throw e;
        }

        await sendFcmToUser(db, receiverUid, payload);
        logger.info(
          { receiverUid, messageId },
          '[CHAT-DEBUG] Đã gọi xong sendFcmToUser cho receiver',
        );
      }),
    );
  },
);

/**
 * Lọc participants chỉ giữ những uid khác sender — dùng cho fan-out FCM +
 * notif doc. Defensive: accept `unknown` rồi narrow vì Firestore data type
 * lúc runtime không enforce shape.
 *
 * Exported cho unit test.
 */
export function receiversOf(
  participantIds: unknown,
  senderId: string,
): string[] {
  if (!Array.isArray(participantIds)) return [];
  return participantIds.filter(
    (uid): uid is string => typeof uid === 'string' && uid !== senderId,
  );
}

/**
 * Cắt nội dung tin nhắn thành đoạn preview ngắn cho notification body.
 * FCM android cho ≈ 240 char nhưng UI Android system tray hiển thị ≈ 2
 * dòng — 100 char là ngưỡng an toàn cho text Việt có dấu (UTF-16 nhân đôi
 * dài hơn dấu ASCII).
 *
 * Exported cho unit test.
 */
export function bodyPreview(text: string): string {
  if (text.length === 0) return 'Đã gửi tin nhắn mới';
  if (text.length <= 100) return text;
  return `${text.substring(0, 97)}...`;
}

import { logger } from 'firebase-functions/v2';

export interface FcmPayload {
  title: string;
  body: string;
  /// FCM data payload — keys MUST mirror what the Flutter deep-link router
  /// reads (`type`, `requestId`, `postId`...). Values are stringified by FCM.
  data: Record<string, string>;
  /// Android notification channel — must exist client-side. Channels declared
  /// in Flutter NotificationController.initFCM().
  channelId: string;
}

/**
 * Send one FCM notification to every token under `/users/{uid}/fcmTokens`,
 * then prune tokens that FCM flags as permanently invalid.
 *
 * Skips gracefully (no throw) when:
 *  - the recipient has no `fcmTokens` docs (logged out, never logged in)
 *  - every token doc is missing/empty the `token` field
 *
 * The 1-token/user policy is enforced client-side
 * ([apps/mobile/lib/features/notification/data/firebase_notification_repository.dart](../../../../apps/mobile/lib/features/notification/data/firebase_notification_repository.dart)),
 * but this helper still iterates the collection in case of a transient
 * multi-device race — the multicast is safe either way.
 *
 * Errors thrown by FCM (network, quota) are caught and logged. We do NOT
 * rethrow because the notification doc has already been written; letting the
 * trigger retry would duplicate the doc on the next invocation.
 */
export async function sendFcmToUser(
  db: FirebaseFirestore.Firestore,
  uid: string,
  payload: FcmPayload,
): Promise<void> {
  const tokenSnap = await db.collection(`users/${uid}/fcmTokens`).get();
  if (tokenSnap.empty) return;

  const tokens: string[] = [];
  const tokenRefs: FirebaseFirestore.DocumentReference[] = [];
  for (const doc of tokenSnap.docs) {
    const raw: unknown = doc.data().token;
    if (typeof raw === 'string' && raw !== '') {
      tokens.push(raw);
      tokenRefs.push(doc.ref);
    }
  }
  if (tokens.length === 0) return;

  // Lazy-import to keep cold-start light (firebase/functions/CLAUDE.md).
  const { getMessaging } = await import('firebase-admin/messaging');

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      android: { notification: { channelId: payload.channelId } },
    });

    const invalidRefs: FirebaseFirestore.DocumentReference[] = [];
    response.responses.forEach((r, i) => {
      if (r.success) return;
      if (isPermanentTokenError(r.error?.code)) {
        const ref = tokenRefs[i];
        if (ref) invalidRefs.push(ref);
      }
    });

    if (invalidRefs.length > 0) {
      const batch = db.batch();
      invalidRefs.forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
  } catch (e) {
    logger.error('FCM multicast failed', { uid, error: e });
  }
}

/**
 * FCM error codes that mean the token is permanently dead — the device
 * either uninstalled the app, disabled notifications, or rotated tokens.
 * Retrying these will never succeed; the only correct action is to delete
 * the token doc so the next push attempt skips it.
 *
 * Transient codes (quota, internal, unavailable) are NOT in this list — we
 * keep those tokens and let the next event try again.
 */
export function isPermanentTokenError(code: string | undefined): boolean {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/invalid-argument'
  );
}

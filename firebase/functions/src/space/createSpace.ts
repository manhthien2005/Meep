import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

/**
 * Schema validation for createSpace CF input.
 *
 * Server source of truth: client gọi `FirebaseSpaceRepository.createSpace`
 * truyền name/iconEmoji/colorHex/friendUids. Server validate lại đầy đủ —
 * KHÔNG tin client.
 */
const createSpaceSchema = z.object({
  name: z.string().trim().min(1).max(30),
  // ZWJ emoji sequences (👨‍👩‍👧‍👦) có JS length 11 vì code units + ZWJ joiners.
  // Cap 32 đủ rộng cho mọi single emoji + flag + ZWJ family, vẫn chặn abuse.
  iconEmoji: z.string().min(1).max(32),
  // 7-char hex `#RRGGBB`. Reject malformed để Camera UI parser luôn an toàn.
  colorHex: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'colorHex must be #RRGGBB'),
  // friendUids: invited friends; creator auto-added → tổng ≤ 10 (max 9 friends).
  // min(2) = Space cần ≥ 3 thành viên (creator + 2 friends) — match client
  // guard (SpaceController.createSpace) + UI button "Tiếp tục" disabled khi
  // < 2 friend chọn.
  friendUids: z.array(z.string().min(1).max(128)).min(2).max(9),
});

/**
 * Create a Space + group conversation in 1 atomic batch.
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Verify creator có friendship với mọi friendUid — chống invite stranger.
 *    (Client `FriendSelectStep` chỉ show friends, nhưng server vẫn check.)
 * 3. Atomic batch (Admin SDK):
 *    a. /spaces/{spaceId} — Space doc với memberIds denormalized + memberCount
 *    b. /space_members/{spaceId}/members/{uid} — creator + invitees (subcollection)
 *    c. /conversations/{spaceId} — group chat đính kèm, type=space, participantIds=memberIds
 * 4. Return { success: true, spaceId }
 *
 * Note về memberCount:
 * - Set trong batch để client `Space.memberCount` đúng ngay khi watchMySpaces emit.
 * - `onSpaceMemberAdded` trigger (T8) sẽ KHÔNG increment cho members tạo cùng
 *   batch (đã set sẵn). Trigger chỉ chạy cho add-after-create (chưa scope MVP).
 *
 * Note về memberIds:
 * - Denormalized array trên /spaces để client query `arrayContains` cho
 *   watchMySpaces. Sync với subcollection /space_members trong cùng batch.
 *
 * Idempotent: KHÔNG. Mỗi lần gọi tạo Space mới (spaceId = auto Firestore ID).
 * Race race-tap-double-create → client SpaceController.isLoading guard.
 */
export const createSpace = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = createSpaceSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { name, iconEmoji, colorHex, friendUids } = parsed.data;
    const creatorId = request.auth.uid;

    if (friendUids.includes(creatorId)) {
      throw new HttpsError(
        'invalid-argument',
        'friendUids must not contain creator',
      );
    }

    // Dedup friendUids — UI có thể gửi duplicate khi double-tap checkbox.
    const uniqueFriendUids = Array.from(new Set(friendUids));

    const db = getFirestore();

    // Step 2: Verify creator có friendship với mọi friendUid.
    // pairId sorted (uid lex thấp trước) — match FirebaseFriendRepository convention.
    if (uniqueFriendUids.length > 0) {
      const friendshipChecks = await Promise.all(
        uniqueFriendUids.map((friendUid) => {
          const pairId =
            creatorId < friendUid
              ? `${creatorId}_${friendUid}`
              : `${friendUid}_${creatorId}`;
          return db.collection('friendships').doc(pairId).get();
        }),
      );

      const notFriends = friendshipChecks
        .map((doc, i) => (doc.exists ? null : uniqueFriendUids[i]))
        .filter((uid): uid is string => uid !== null);

      if (notFriends.length > 0) {
        throw new HttpsError(
          'failed-precondition',
          `Not friends with: ${notFriends.join(', ')}`,
        );
      }
    }

    // Step 3: Atomic batch write.
    const memberIds = [creatorId, ...uniqueFriendUids];
    const memberCount = memberIds.length;
    const spaceRef = db.collection('spaces').doc();
    const spaceId = spaceRef.id;
    const now = FieldValue.serverTimestamp();

    const batch = db.batch();

    // 3a. /spaces/{spaceId}
    batch.set(spaceRef, {
      spaceId,
      name,
      iconEmoji,
      colorHex,
      creatorId,
      memberCount,
      memberIds,
      createdAt: now,
    });

    // 3b. /space_members/{spaceId}/members/{uid} subcollection.
    // Creator role = 'creator', còn lại = 'member'.
    for (const uid of memberIds) {
      const memberRef = db
        .collection('space_members')
        .doc(spaceId)
        .collection('members')
        .doc(uid);
      batch.set(memberRef, {
        uid,
        role: uid === creatorId ? 'creator' : 'member',
        joinedAt: now,
      });
    }

    // 3c. /conversations/{spaceId} — group chat. conversationId === spaceId
    // để Chat module lookup conversation từ Space context không cần extra
    // mapping. participantIds đồng bộ memberIds.
    batch.set(db.collection('conversations').doc(spaceId), {
      conversationId: spaceId,
      type: 'space',
      participantIds: memberIds,
      spaceId,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    });

    await batch.commit();

    return { success: true, spaceId };
  },
);

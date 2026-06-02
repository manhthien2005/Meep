import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

/**
 * Schema validation for updateSpace CF input.
 *
 * Partial update — chỉ field nào được pass mới update. Refine reject empty
 * patch (cả 3 field cosmetic đều undefined) để tránh CF call vô ích sinh
 * audit noise.
 *
 * 3 field cosmetic: name (1-30), iconEmoji (1-32), colorHex (#RRGGBB).
 * KHÔNG cho phép edit memberIds/memberCount/creatorId qua đây — các thao
 * tác đó có CF riêng (kickMember, transferOwnership).
 */
const updateSpaceSchema = z
  .object({
    spaceId: z.string().min(1).max(128),
    name: z.string().trim().min(1).max(30).optional(),
    iconEmoji: z.string().min(1).max(32).optional(),
    colorHex: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/, 'colorHex must be #RRGGBB')
      .optional(),
  })
  .refine(
    (d) =>
      d.name !== undefined ||
      d.iconEmoji !== undefined ||
      d.colorHex !== undefined,
    {
      message:
        'At least one field (name/iconEmoji/colorHex) must be provided',
    },
  );

/**
 * Creator cập nhật metadata Space — tên, icon, màu.
 *
 * Steps:
 * 1. Auth + schema validate.
 * 2. Load Space + verify:
 *    - Space tồn tại + chưa bị soft-delete (deletedAt == null)
 *    - caller là creator hiện tại
 * 3. Partial update chỉ field được pass + serverTimestamp updatedAt.
 *
 * Defense in depth: client `SpaceController.updateSpace` đã guard
 * creator-only fail-fast, UI `SettingsSheet` ẩn nút edit cho non-creator.
 * CF là server boundary; Firestore rule là final safety net với
 * field-level whitelist (chỉ allow update name/iconEmoji/colorHex/
 * deletedAt/updatedAt).
 *
 * Note về conversation name sync:
 * - `/conversations/{spaceId}` schema KHÔNG có field `name` (xem
 *   createSpace.ts:142-150) → KHÔNG cần update conversation khi Space
 *   được rename. Group chat title đọc trực tiếp từ `/spaces/{id}.name`
 *   mỗi lần render.
 * - Nếu sau này Chat module denormalize `conversation.name` cho group
 *   title, cần thêm batch update `/conversations/{spaceId}.name` ở đây.
 *
 * Idempotent: YES nếu input giống nhau (Firestore `update` idempotent).
 */
export const updateSpace = onCall(
  { region: 'asia-southeast1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = updateSpaceSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const { spaceId, name, iconEmoji, colorHex } = parsed.data;
    const callerUid = request.auth.uid;

    const db = getFirestore();
    const spaceRef = db.collection('spaces').doc(spaceId);
    const spaceDoc = await spaceRef.get();
    if (!spaceDoc.exists) {
      throw new HttpsError('not-found', 'Space not found');
    }

    const spaceData = spaceDoc.data();
    if (!spaceData) {
      throw new HttpsError('not-found', 'Space data missing');
    }

    if (spaceData.deletedAt != null) {
      throw new HttpsError('failed-precondition', 'Space already deleted');
    }

    if (spaceData.creatorId !== callerUid) {
      throw new HttpsError(
        'permission-denied',
        'Only creator can update Space',
      );
    }

    const updates: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (name !== undefined) updates.name = name;
    if (iconEmoji !== undefined) updates.iconEmoji = iconEmoji;
    if (colorHex !== undefined) updates.colorHex = colorHex;

    await spaceRef.update(updates);

    logger.info(
      {
        spaceId,
        callerUid,
        fields: Object.keys(updates).filter((k) => k !== 'updatedAt'),
      },
      'space updated',
    );

    return { success: true };
  },
);

// Backfill /conversations/{spaceId} docs thiếu lastMessageAt / lastMessage /
// lastSenderId. Bug fix #142: CF createSpace cũ KHÔNG init 3 field này → Inbox
// query orderBy('lastMessageAt') loại trừ docs → group chat invisible.
//
// CHẠY (staging):
//   1. Tải service account JSON từ Firebase Console → Project Settings →
//      Service accounts → Generate new private key
//   2. cd firebase/functions
//   3. GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/sa.json \
//      node scripts/backfill-space-conversations.mjs --dry-run
//   4. Verify danh sách doc, sau đó bỏ --dry-run để apply
//
// CHẠY (prod) — KHÔNG TỰ Ý CHẠY, ping leader trước:
//   FIREBASE_PROJECT=meep-product \
//   GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/prod-sa.json \
//   node scripts/backfill-space-conversations.mjs
//
// An toàn:
// - Admin SDK bypass rules — bắt buộc service account JSON.
// - Dry-run trước khi commit: pass --dry-run flag để in ra danh sách doc cần backfill
//   mà KHÔNG ghi gì.
// - Idempotent: chỉ backfill doc THIẾU field (skip doc đã có).

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const PROJECT_ID = process.env.FIREBASE_PROJECT || 'meep-staging';
const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    'Missing GOOGLE_APPLICATION_CREDENTIALS env var. Tải service account JSON ' +
    'từ Firebase Console rồi export GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/sa.json',
  );
  process.exit(1);
}

const app = initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});
const db = getFirestore(app);

async function main() {
  console.log(`Backfill /conversations missing fields trong project ${PROJECT_ID}`);
  console.log(DRY_RUN ? '  [DRY-RUN] không ghi gì\n' : '  [LIVE] sẽ ghi vào Firestore\n');

  // Query tất cả conversations type='space' — bug chỉ ảnh hưởng group chat.
  const snap = await db
    .collection('conversations')
    .where('type', '==', 'space')
    .get();

  console.log(`Tìm thấy ${snap.size} group conversations.\n`);

  let backfilled = 0;
  let alreadyOk = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const missing = {};

    if (data.lastMessageAt == null) {
      // Fallback dùng createdAt nếu có, nếu không thì serverTimestamp().
      missing.lastMessageAt = data.createdAt ?? Timestamp.now();
    }
    if (typeof data.lastMessage !== 'string') missing.lastMessage = '';
    if (typeof data.lastSenderId !== 'string') missing.lastSenderId = '';

    if (Object.keys(missing).length === 0) {
      alreadyOk++;
      continue;
    }

    console.log(`  - ${doc.id}: missing ${Object.keys(missing).join(', ')}`);
    if (!DRY_RUN) {
      await doc.ref.update(missing);
    }
    backfilled++;
  }

  console.log(`\nDone. Backfilled: ${backfilled}. Đã OK sẵn: ${alreadyOk}.`);
  if (DRY_RUN && backfilled > 0) {
    console.log('Re-run KHÔNG có --dry-run để apply.');
  }
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});

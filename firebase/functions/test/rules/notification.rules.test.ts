/**
 * Firestore security rules tests — Notification module.
 *
 * Covers:
 *   /users/{uid}/notifications/{notifId}
 *   /users/{uid}/fcmTokens/{tokenId}
 *
 * Issue #107 — T8 Notification rules tests.
 *
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Pattern mirrors reaction.rules.test.ts.
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';

// ===== Setup =====

let testEnv: RulesTestEnvironment;

const RULES_PATH = resolve(__dirname, '../../../firestore.rules');

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'meep-test-notification',
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9999,
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

// ===== Helpers =====

const uid = (n: string) => `user-${n}`;

function authed(userId: string) {
  return testEnv.authenticatedContext(userId);
}

function unauthed() {
  return testEnv.unauthenticatedContext();
}

const alice = uid('alice');
const bob = uid('bob');
const stranger = uid('stranger');
const notifId = 'notif-1';
const tokenId = 'token-sha256-abc';

function notificationDoc(overrides: Record<string, unknown> = {}) {
  return {
    type: 'reaction',
    title: 'Bob đã react vào ảnh của bạn',
    body: '🤣',
    data: { type: 'reaction', postId: 'post-1', reactorId: bob },
    read: false,
    createdAt: new Date('2026-06-04'),
    ...overrides,
  };
}

function fcmTokenDoc(overrides: Record<string, unknown> = {}) {
  return {
    token: 'fcm-token-abcdef-12345',
    platform: 'android',
    updatedAt: new Date('2026-06-04'),
    ...overrides,
  };
}

/**
 * Seed a notification doc bypassing rules — CF Admin SDK path.
 */
async function seedNotification(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .doc(`users/${alice}/notifications/${notifId}`)
      .set(notificationDoc());
  });
}

/**
 * Seed an fcmTokens doc bypassing rules.
 */
async function seedFcmToken(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .doc(`users/${alice}/fcmTokens/${tokenId}`)
      .set(fcmTokenDoc());
  });
}

// ===== /users/{uid}/notifications/{notifId} =====

describe('/users/{uid}/notifications/{notifId}', () => {
  // ── read ──────────────────────────────────────────────────────
  test('read by owner (alice) → ALLOW', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/notifications/${notifId}`).get(),
    );
  });

  test('read by stranger → DENY', async () => {
    await seedNotification();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).get(),
    );
  });

  test('read by unauthenticated → DENY', async () => {
    await seedNotification();
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).get(),
    );
  });

  // ── create by client (always DENY — CF Admin SDK only) ────────
  test('create by owner → DENY (server-side only)', async () => {
    const db = authed(alice).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).set(notificationDoc()),
    );
  });

  test('create by stranger → DENY', async () => {
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).set(notificationDoc()),
    );
  });

  test('create by unauthenticated → DENY', async () => {
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).set(notificationDoc()),
    );
  });

  // ── update field `read` ───────────────────────────────────────
  test('update field `read` by owner (mark-as-read) → ALLOW', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/notifications/${notifId}`).update({ read: true }),
    );
  });

  test('update field `read` by stranger → DENY', async () => {
    await seedNotification();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).update({ read: true }),
    );
  });

  test('update field `read` by unauthenticated → DENY', async () => {
    await seedNotification();
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).update({ read: true }),
    );
  });

  test('update field `read` true → false by owner (mark-as-unread) → ALLOW', async () => {
    // Seed với read=true để verify flow reverse — rule không phân biệt
    // hướng, chỉ enforce diff + type. Mobile hiện không có UI mark-unread
    // nhưng rule cho phép → test xác nhận behavior để dev tương lai
    // không tưởng nhầm rule chặn.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${alice}/notifications/${notifId}`)
        .set(notificationDoc({ read: true }));
    });
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/notifications/${notifId}`).update({ read: false }),
    );
  });

  test('update non-whitelisted field (title) by owner → DENY', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertFails(
      db
        .doc(`users/${alice}/notifications/${notifId}`)
        .update({ title: 'tampered' }),
    );
  });

  test('update field `body` by owner → DENY', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertFails(
      db
        .doc(`users/${alice}/notifications/${notifId}`)
        .update({ body: 'tampered' }),
    );
  });

  test('update `read` + extra field (title) by owner → DENY', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertFails(
      db
        .doc(`users/${alice}/notifications/${notifId}`)
        .update({ read: true, title: 'tampered' }),
    );
  });

  test('update `read` to non-bool by owner → DENY', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertFails(
      db
        .doc(`users/${alice}/notifications/${notifId}`)
        .update({ read: 'yes' }),
    );
  });

  // ── delete (always DENY — server-side only) ───────────────────
  test('delete by owner → DENY', async () => {
    await seedNotification();
    const db = authed(alice).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).delete(),
    );
  });

  test('delete by stranger → DENY', async () => {
    await seedNotification();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).delete(),
    );
  });

  test('delete by unauthenticated → DENY', async () => {
    await seedNotification();
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/notifications/${notifId}`).delete(),
    );
  });
});

// ===== /users/{uid}/fcmTokens/{tokenId} =====

describe('/users/{uid}/fcmTokens/{tokenId}', () => {
  // ── read ──────────────────────────────────────────────────────
  test('read by owner (alice) → ALLOW', async () => {
    await seedFcmToken();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).get(),
    );
  });

  test('read by stranger → DENY', async () => {
    await seedFcmToken();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).get(),
    );
  });

  test('read by unauthenticated → DENY', async () => {
    await seedFcmToken();
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).get(),
    );
  });

  // ── write (create) ────────────────────────────────────────────
  test('create by owner → ALLOW', async () => {
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).set(fcmTokenDoc()),
    );
  });

  test('create by stranger → DENY', async () => {
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).set(fcmTokenDoc()),
    );
  });

  test('create by unauthenticated → DENY', async () => {
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).set(fcmTokenDoc()),
    );
  });

  // ── write (update) — refresh token rotation ───────────────────
  test('update by owner (token rotate) → ALLOW', async () => {
    await seedFcmToken();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db
        .doc(`users/${alice}/fcmTokens/${tokenId}`)
        .set(fcmTokenDoc({ token: 'fcm-token-rotated-xyz' })),
    );
  });

  test('update by stranger → DENY', async () => {
    await seedFcmToken();
    const db = authed(stranger).firestore();
    await assertFails(
      db
        .doc(`users/${alice}/fcmTokens/${tokenId}`)
        .set(fcmTokenDoc({ token: 'hijacked' })),
    );
  });

  // ── write (delete) — logout cleanup ───────────────────────────
  test('delete by owner (logout cleanup) → ALLOW', async () => {
    await seedFcmToken();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).delete(),
    );
  });

  test('delete by stranger → DENY', async () => {
    await seedFcmToken();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`users/${alice}/fcmTokens/${tokenId}`).delete(),
    );
  });
});

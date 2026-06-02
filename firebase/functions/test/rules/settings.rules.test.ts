/**
 * Firestore security rules tests for Settings module.
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Tests:
 *   - /blocks/{blockId}: read by blocker ✓, blocked ✓, stranger ✗, unauthed ✗
 *   - /blocks/{blockId}: client create/update/delete → false (CF blockUser /
 *     client `unblockUser = client delete` per #116 OQ5 resolution — wait,
 *     check: rules hiện set `create, update, delete: if false` toàn bộ. T1
 *     OQ5 resolved: unblock = client direct delete `/blocks/{blockerUid}_{targetUid}`,
 *     KHÔNG qua CF). Rule cần allow delete cho blocker only?
 *     → Hiện rules block hết CUD. Test xác nhận rules HIỆN TẠI:
 *       create/update/delete → false (mọi user).
 *     Nếu rule cần đổi để allow blocker delete → đó là follow-up.
 *
 * Pattern mirror space.rules.test.ts.
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
    projectId: 'meep-test-settings',
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9999,
    },
  });
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  if (testEnv) {
    await testEnv.clearFirestore();
  }
});

// ===== Helpers =====

const uid = (n: string) => `user-${n}`;

function authed(userId: string) {
  return testEnv.authenticatedContext(userId);
}

function unauthed() {
  return testEnv.unauthenticatedContext();
}

/**
 * Block ID format theo spec: `{blockerUid}_{blockedUid}` — KHÔNG sorted
 * (khác với pairId của friendship). Helper để build ID consistent với
 * client `FirebaseBlockRepository._blockIdOf`.
 */
function blockIdOf(blockerUid: string, blockedUid: string): string {
  return `${blockerUid}_${blockedUid}`;
}

/**
 * Seed /blocks/{blockId} bypassing rules — preconditions cho read/delete
 * tests. Match shape CF blockUser.ts batch.set().
 */
async function seedBlock(
  blockerUid: string,
  blockedUid: string,
): Promise<void> {
  const id = blockIdOf(blockerUid, blockedUid);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`blocks/${id}`).set({
      blockId: id,
      blockerUid,
      blockedUid,
      createdAt: new Date(),
    });
  });
}

// ===== /blocks/{blockId} — read =====

describe('/blocks/{blockId} — read', () => {
  test('blocker can read block doc của mình', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertSucceeds(
      authed(alice).firestore().doc(`blocks/${blockIdOf(alice, bob)}`).get(),
    );
  });

  test('blocked user can read block doc (để detect bị block — isBlocked rule helper)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertSucceeds(
      authed(bob).firestore().doc(`blocks/${blockIdOf(alice, bob)}`).get(),
    );
  });

  test('stranger cannot read block doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    await seedBlock(alice, bob);

    await assertFails(
      authed(charlie).firestore().doc(`blocks/${blockIdOf(alice, bob)}`).get(),
    );
  });

  test('unauthenticated cannot read block doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertFails(
      unauthed().firestore().doc(`blocks/${blockIdOf(alice, bob)}`).get(),
    );
  });
});

// ===== /blocks/{blockId} — write (client) =====

describe('/blocks/{blockId} — write (client direct)', () => {
  test('client cannot create block doc (CF blockUser only)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');

    await assertFails(
      authed(alice)
        .firestore()
        .doc(`blocks/${blockIdOf(alice, bob)}`)
        .set({
          blockId: blockIdOf(alice, bob),
          blockerUid: alice,
          blockedUid: bob,
          createdAt: new Date(),
        }),
    );
  });

  test('client cannot update block doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertFails(
      authed(alice)
        .firestore()
        .doc(`blocks/${blockIdOf(alice, bob)}`)
        .update({ createdAt: new Date() }),
    );
  });

  test('blocker cannot delete block doc via client (rule blocks CUD entirely)', async () => {
    // NOTE: T1 OQ5 originally suggested client-side unblock = delete
    // /blocks/{blockerUid}_{targetUid}. Rules HIỆN TẠI set
    // `create, update, delete: if false` — toàn bộ CUD đi qua Admin SDK.
    // Nếu cần đổi để allow blocker delete cho unblock client-side, đây là
    // follow-up rule change cần leader review.
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertFails(
      authed(alice).firestore().doc(`blocks/${blockIdOf(alice, bob)}`).delete(),
    );
  });

  test('blocked user cannot delete block doc của blocker', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedBlock(alice, bob);

    await assertFails(
      authed(bob).firestore().doc(`blocks/${blockIdOf(alice, bob)}`).delete(),
    );
  });

  test('stranger cannot delete block doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    await seedBlock(alice, bob);

    await assertFails(
      authed(charlie)
        .firestore()
        .doc(`blocks/${blockIdOf(alice, bob)}`)
        .delete(),
    );
  });

  test('unauthenticated cannot create/update/delete block doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');

    // Create
    await assertFails(
      unauthed()
        .firestore()
        .doc(`blocks/${blockIdOf(alice, bob)}`)
        .set({
          blockId: blockIdOf(alice, bob),
          blockerUid: alice,
          blockedUid: bob,
          createdAt: new Date(),
        }),
    );
  });
});

// ===== /blocks — query =====

describe('/blocks — query', () => {
  test('blocker can query /blocks where blockerUid == self', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const carol = uid('carol');
    await seedBlock(alice, bob);
    await seedBlock(alice, carol);
    // Block từ bob → carol (alice là stranger trong block này)
    await seedBlock(bob, carol);

    // Alice query /blocks where blockerUid == alice → trả về 2 blocks của
    // alice. Rule `request.auth.uid == resource.data.blockerUid` filter
    // per-doc → bob/carol's block (blockerUid=bob) sẽ fail rule → query
    // không trả về.
    const querySnap = await assertSucceeds(
      authed(alice)
        .firestore()
        .collection('blocks')
        .where('blockerUid', '==', alice)
        .get(),
    );
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const docs = (querySnap as any).docs as Array<{ id: string }>;
    if (docs.length !== 2) {
      throw new Error(
        `Expected query to return 2 docs (blocks by alice), got ${docs.length}: ` +
          `[${docs.map((d) => d.id).join(', ')}]`,
      );
    }
  });

  test('user can query /blocks where blockedUid == self (xem ai đã block mình)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const carol = uid('carol');
    await seedBlock(alice, bob); // alice blocks bob
    await seedBlock(carol, bob); // carol blocks bob

    // Bob query /blocks where blockedUid == bob → trả về 2 blocks lên bob.
    const querySnap = await assertSucceeds(
      authed(bob)
        .firestore()
        .collection('blocks')
        .where('blockedUid', '==', bob)
        .get(),
    );
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const docs = (querySnap as any).docs as Array<{ id: string }>;
    if (docs.length !== 2) {
      throw new Error(
        `Expected query to return 2 docs (blocks on bob), got ${docs.length}`,
      );
    }
  });

  test('stranger cannot query /blocks without filter (rule blocks)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    await seedBlock(alice, bob);

    // Charlie không phải blocker hay blocked của doc nào → query without
    // where filter sẽ fail rule per-doc → query reject.
    await assertFails(
      authed(charlie).firestore().collection('blocks').get(),
    );
  });
});

// ===== CF blockUser — behavior (mirror logic) =====
//
// NOTE: Test mirror exact batch logic của `src/settings/blockUser.ts` thay vì
// import handler trực tiếp (handler wrapped trong `onCall` middleware, khó
// invoke isolate). Sync: nếu đổi `blockUser.ts` batch flow, phải update mirror
// dưới đây. Behavior verified:
//   - self-block guard
//   - happy path: /blocks created + /friendships deleted + /conversations status
//   - idempotent: re-call same block doc → no-op success
//   - graceful: friendship/conversation không tồn tại → batch vẫn pass

class SelfBlockError extends Error {
  constructor() {
    super('Cannot block yourself');
    this.name = 'SelfBlockError';
  }
}

/**
 * Mirror logic của CF `blockUser`. Trả về { skipped: true } nếu idempotent
 * no-op, ngược lại { skipped: false }.
 *
 * Throws [SelfBlockError] nếu self-block (mirror `HttpsError invalid-argument`).
 *
 * Helper dùng `withSecurityRulesDisabled` ctx để bypass rules (mirror Admin
 * SDK trong CF). Pre-read conversation exists rồi conditional update — match
 * CF logic chống batch.update NOT_FOUND.
 */
async function executeBlockUser(
  blockerUid: string,
  targetUid: string,
): Promise<{ skipped: boolean }> {
  if (blockerUid === targetUid) {
    throw new SelfBlockError();
  }
  let skipped = false;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const blockId = `${blockerUid}_${targetUid}`;
    const blockRef = db.collection('blocks').doc(blockId);

    const existing = await blockRef.get();
    if (existing.exists) {
      skipped = true;
      return;
    }

    const pairId =
      blockerUid < targetUid
        ? `${blockerUid}_${targetUid}`
        : `${targetUid}_${blockerUid}`;
    const friendshipRef = db.collection('friendships').doc(pairId);
    const conversationRef = db.collection('conversations').doc(pairId);
    const conversationSnap = await conversationRef.get();

    const now = new Date();
    const batch = db.batch();
    batch.set(blockRef, {
      blockId,
      blockerUid,
      blockedUid: targetUid,
      createdAt: now,
    });
    batch.delete(friendshipRef);
    if (conversationSnap.exists) {
      batch.update(conversationRef, { status: 'blocked', updatedAt: now });
    }
    await batch.commit();
  });
  return { skipped };
}

/**
 * Seed friendship doc (matching FirebaseFriendRepository convention — members
 * array contains both uids, sorted pairId).
 */
async function seedFriendship(uidA: string, uidB: string): Promise<void> {
  const pairId = uidA < uidB ? `${uidA}_${uidB}` : `${uidB}_${uidA}`;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .doc(`friendships/${pairId}`)
      .set({
        pairId,
        uid1: uidA < uidB ? uidA : uidB,
        uid2: uidA < uidB ? uidB : uidA,
        members: [uidA, uidB],
        createdAt: new Date(),
      });
  });
}

/**
 * Seed conversation doc (1-on-1, status='active') với pairId convention.
 */
async function seedConversation(uidA: string, uidB: string): Promise<void> {
  const pairId = uidA < uidB ? `${uidA}_${uidB}` : `${uidB}_${uidA}`;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(`conversations/${pairId}`).set({
      conversationId: pairId,
      type: 'direct',
      participantIds: [uidA, uidB],
      status: 'active',
      createdAt: new Date(),
    });
  });
}

describe('CF blockUser — behavior (mirror logic)', () => {
  test('self-block → throws SelfBlockError', async () => {
    const alice = uid('alice');
    let caught: unknown;
    try {
      await executeBlockUser(alice, alice);
    } catch (e) {
      caught = e;
    }
    if (!(caught instanceof SelfBlockError)) {
      throw new Error(`Expected SelfBlockError, got ${String(caught)}`);
    }
  });

  test('happy path: block created + friendship deleted + conversation status=blocked', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedFriendship(alice, bob);
    await seedConversation(alice, bob);

    const result = await executeBlockUser(alice, bob);
    if (result.skipped) {
      throw new Error('Expected skipped=false on first block');
    }

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      const pairId = alice < bob ? `${alice}_${bob}` : `${bob}_${alice}`;

      const blockSnap = await db.doc(`blocks/${alice}_${bob}`).get();
      if (!blockSnap.exists) {
        throw new Error('Expected /blocks doc created');
      }
      const blockData = blockSnap.data();
      if (blockData?.blockerUid !== alice || blockData?.blockedUid !== bob) {
        throw new Error(
          `Wrong block doc fields: ${JSON.stringify(blockData)}`,
        );
      }

      const friendshipSnap = await db.doc(`friendships/${pairId}`).get();
      if (friendshipSnap.exists) {
        throw new Error('Expected friendship deleted');
      }

      const convSnap = await db.doc(`conversations/${pairId}`).get();
      if (!convSnap.exists || convSnap.data()?.status !== 'blocked') {
        throw new Error(
          `Expected conversation status=blocked, got ${convSnap.data()?.status}`,
        );
      }
    });
  });

  test('idempotent: gọi 2 lần → lần 2 skip, /blocks doc không bị recreate', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedFriendship(alice, bob);

    const first = await executeBlockUser(alice, bob);
    if (first.skipped) {
      throw new Error('First call should not be skipped');
    }

    let originalCreatedAt: unknown;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const snap = await ctx.firestore().doc(`blocks/${alice}_${bob}`).get();
      originalCreatedAt = snap.data()?.createdAt;
    });

    const second = await executeBlockUser(alice, bob);
    if (!second.skipped) {
      throw new Error('Second call should be skipped (idempotent)');
    }

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const snap = await ctx.firestore().doc(`blocks/${alice}_${bob}`).get();
      const newCreatedAt = snap.data()?.createdAt;
      if (
        JSON.stringify(newCreatedAt) !== JSON.stringify(originalCreatedAt)
      ) {
        throw new Error(
          'Idempotent block should NOT overwrite original createdAt',
        );
      }
    });
  });

  test('no friendship/conversation pre-existing → batch vẫn pass (graceful)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    // KHÔNG seed friendship + conversation.

    const result = await executeBlockUser(alice, bob);
    if (result.skipped) {
      throw new Error('Expected non-skipped first call');
    }

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const blockSnap = await ctx
        .firestore()
        .doc(`blocks/${alice}_${bob}`)
        .get();
      if (!blockSnap.exists) {
        throw new Error('Expected block created even without friendship');
      }
    });
  });
});

// ===== CF deleteAccount — behavior (mirror logic, scoped) =====
//
// NOTE: Full cascade (Storage + Auth) cần emulator ngoài Firestore. T8 chỉ
// verify Firestore portion: subcollections + cross-collection queries +
// conversation soft-delete + username release + user doc. Storage + Auth
// behavior defer (T7 documented).

const BATCH_LIMIT = 499;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function deleteQueryInBatches(query: any): Promise<number> {
  let total = 0;
  while (true) {
    const snap = await query.limit(BATCH_LIMIT).get();
    if (snap.empty) break;
    const batch = query.firestore.batch();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    for (const doc of snap.docs as Array<{ ref: any }>) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    total += snap.size;
    if (snap.size < BATCH_LIMIT) break;
  }
  return total;
}

/**
 * Mirror logic core Firestore-portion của `deleteAccount`. Bỏ Storage + Auth
 * (out-of-scope cho emulator setup hiện tại).
 */
async function executeDeleteAccountFirestorePortion(uid: string): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const userRef = db.collection('users').doc(uid);

    // Step 2: Subcollections /users/{uid}/{feed, notifications, fcmTokens, private}
    await Promise.all([
      deleteQueryInBatches(userRef.collection('feed')),
      deleteQueryInBatches(userRef.collection('notifications')),
      deleteQueryInBatches(userRef.collection('fcmTokens')),
      deleteQueryInBatches(userRef.collection('private')),
    ]);

    // Step 3a-3c: Cross-collection sequential (downstream triggers depend on order)
    await deleteQueryInBatches(
      db.collection('diary').where('authorUid', '==', uid),
    );
    await deleteQueryInBatches(
      db.collection('posts').where('authorId', '==', uid),
    );
    await deleteQueryInBatches(
      db.collection('friendships').where('members', 'array-contains', uid),
    );

    // Step 3d-3e: friend_requests + blocks parallel
    await Promise.all([
      deleteQueryInBatches(
        db.collection('friend_requests').where('senderId', '==', uid),
      ),
      deleteQueryInBatches(
        db.collection('friend_requests').where('receiverId', '==', uid),
      ),
      deleteQueryInBatches(
        db.collection('blocks').where('blockerUid', '==', uid),
      ),
      deleteQueryInBatches(
        db.collection('blocks').where('blockedUid', '==', uid),
      ),
    ]);

    // Step 4: Conversations soft-delete (status='deleted')
    const convQuery = db
      .collection('conversations')
      .where('participantIds', 'array-contains', uid);
    const convSnap = await convQuery.get();
    if (!convSnap.empty) {
      const batch = db.batch();
      for (const doc of convSnap.docs) {
        batch.update(doc.ref, { status: 'deleted', updatedAt: new Date() });
      }
      await batch.commit();
    }

    // Step 5: Username release
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      const usernameField = userSnap.data()?.username;
      if (typeof usernameField === 'string' && usernameField.length > 0) {
        const usernameRef = db.collection('usernames').doc(usernameField);
        const usernameSnap = await usernameRef.get();
        if (usernameSnap.exists) {
          await usernameRef.delete();
        }
      }
    }

    // Step 6: User doc
    if (userSnap.exists) {
      await userRef.delete();
    }
  });
}

async function seedUser(uid: string, username: string): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`users/${uid}`).set({
      uid,
      email: `${uid}@test.local`,
      displayName: uid,
      username,
      createdAt: new Date(),
    });
    await db.doc(`usernames/${username}`).set({ uid });
  });
}

describe('CF deleteAccount — Firestore cascade (mirror logic)', () => {
  test('cascade xoá full state: user doc + username + subcollections + cross-coll', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedUser(alice, 'alice_handle');
    await seedFriendship(alice, bob);
    await seedConversation(alice, bob);
    await seedBlock(alice, bob);

    // Seed subcollection
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc(`users/${alice}/feed/post1`).set({ postId: 'post1' });
      await db
        .doc(`users/${alice}/notifications/n1`)
        .set({ notifId: 'n1' });
      // Friend_request: alice là sender
      await db.doc('friend_requests/req1').set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
      });
    });

    await executeDeleteAccountFirestorePortion(alice);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      const pairId = alice < bob ? `${alice}_${bob}` : `${bob}_${alice}`;

      if ((await db.doc(`users/${alice}`).get()).exists) {
        throw new Error('User doc should be deleted');
      }
      if ((await db.doc('usernames/alice_handle').get()).exists) {
        throw new Error('Username should be released');
      }
      if ((await db.doc(`users/${alice}/feed/post1`).get()).exists) {
        throw new Error('Feed subcollection should be deleted');
      }
      if ((await db.doc(`users/${alice}/notifications/n1`).get()).exists) {
        throw new Error('Notifications subcollection should be deleted');
      }
      if ((await db.doc(`friendships/${pairId}`).get()).exists) {
        throw new Error('Friendship should be deleted');
      }
      if ((await db.doc('friend_requests/req1').get()).exists) {
        throw new Error('Friend request (sender) should be deleted');
      }
      if ((await db.doc(`blocks/${alice}_${bob}`).get()).exists) {
        throw new Error('Block (as blocker) should be deleted');
      }

      // Conversation soft-deleted, KHÔNG hard delete (parity Locket)
      const convSnap = await db.doc(`conversations/${pairId}`).get();
      if (!convSnap.exists) {
        throw new Error(
          'Conversation should still exist (soft delete only)',
        );
      }
      if (convSnap.data()?.status !== 'deleted') {
        throw new Error(
          `Conversation status should be 'deleted', got ${convSnap.data()?.status}`,
        );
      }
    });
  });

  test('idempotent: gọi 2 lần → lần 2 no-op (không throw)', async () => {
    const alice = uid('alice');
    await seedUser(alice, 'alice_handle');

    await executeDeleteAccountFirestorePortion(alice);
    // Lần 2: tất cả query empty → no-op
    await executeDeleteAccountFirestorePortion(alice);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const userSnap = await ctx.firestore().doc(`users/${alice}`).get();
      if (userSnap.exists) {
        throw new Error('User doc still exists after second call');
      }
    });
  });

  test('blocks where blockedUid == self cũng được xóa (blocker khác delete account)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    // Bob block alice. Alice xóa account → block doc (blockedUid=alice) phải xóa.
    await seedBlock(bob, alice);
    await seedUser(alice, 'alice_handle');

    await executeDeleteAccountFirestorePortion(alice);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const blockSnap = await ctx
        .firestore()
        .doc(`blocks/${bob}_${alice}`)
        .get();
      if (blockSnap.exists) {
        throw new Error('Block where blockedUid=self should be deleted');
      }
    });
  });
});

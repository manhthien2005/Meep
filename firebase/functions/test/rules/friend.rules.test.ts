/**
 * Firestore security rules tests for Friend module.
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Tests /friendships and /friend_requests collections.
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
  try {
    testEnv = await initializeTestEnvironment({
      projectId: 'meep-test-friend',
      firestore: {
        rules: readFileSync(RULES_PATH, 'utf8'),
        host: '127.0.0.1',
        port: 9998,
      },
    });
  } catch (error) {
    // Emulator not running — skip tests gracefully
    console.warn('⚠️  Firestore emulator not running. Skipping friend.rules.test.ts');
    console.warn('   Run via: firebase emulators:exec --only firestore "npm run test:rules"');
  }
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

function pairId(a: string, b: string): string {
  return a < b ? `${a}_${b}` : `${b}_${a}`;
}

// ===== /friendships/{pairId} =====

describe.skipIf(!testEnv)('/friendships/{pairId}', () => {
  test('uid1 can read friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertSucceeds(authed(alice).firestore().doc(`friendships/${pid}`).get());
  });

  test('uid2 can read friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertSucceeds(authed(bob).firestore().doc(`friendships/${pid}`).get());
  });

  test('stranger cannot read friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertFails(authed(charlie).firestore().doc(`friendships/${pid}`).get());
  });

  test('unauthenticated cannot read friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertFails(unauthed().firestore().doc(`friendships/${pid}`).get());
  });

  test('client cannot create friendship (CF only)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);

    await assertFails(
      authed(alice).firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      }),
    );
  });

  test('uid1 can delete friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertSucceeds(authed(alice).firestore().doc(`friendships/${pid}`).delete());
  });

  test('stranger cannot delete friendship', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    const pid = pairId(alice, bob);

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${pid}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });

    await assertFails(authed(charlie).firestore().doc(`friendships/${pid}`).delete());
  });
});

// ===== /friend_requests/{requestId} =====

describe.skipIf(!testEnv)('/friend_requests/{requestId}', () => {
  test('sender can create request with senderId != receiverId', async () => {
    const alice = uid('alice');
    const bob = uid('bob');

    await assertSucceeds(
      authed(alice).firestore().collection('friend_requests').add({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('cannot create self-request (senderId == receiverId)', async () => {
    const alice = uid('alice');

    await assertFails(
      authed(alice).firestore().collection('friend_requests').add({
        senderId: alice,
        receiverId: alice,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('receiver can update pending → accepted', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const requestId = 'req123';

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friend_requests/${requestId}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertSucceeds(
      authed(bob).firestore().doc(`friend_requests/${requestId}`).update({
        status: 'accepted',
        updatedAt: new Date(),
      }),
    );
  });

  test('receiver cannot update pending → cancelled (only sender can cancel)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const requestId = 'req123';

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friend_requests/${requestId}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertFails(
      authed(bob).firestore().doc(`friend_requests/${requestId}`).update({
        status: 'cancelled',
        updatedAt: new Date(),
      }),
    );
  });

  test('sender can update pending → cancelled', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const requestId = 'req123';

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friend_requests/${requestId}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertSucceeds(
      authed(alice).firestore().doc(`friend_requests/${requestId}`).update({
        status: 'cancelled',
        updatedAt: new Date(),
      }),
    );
  });

  test('sender cannot update pending → accepted (only receiver can accept)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const requestId = 'req123';

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friend_requests/${requestId}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    await assertFails(
      authed(alice).firestore().doc(`friend_requests/${requestId}`).update({
        status: 'accepted',
        updatedAt: new Date(),
      }),
    );
  });
});

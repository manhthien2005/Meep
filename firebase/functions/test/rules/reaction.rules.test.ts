/**
 * Firestore security rules tests — Reaction module.
 *
 * Covers: /posts/{postId}/reactions/{reactorUid}
 *
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Pattern mirrors space.rules.test.ts.
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
    projectId: 'meep-test-reaction',
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

const postId = 'post-reaction-test';
const alice = uid('alice');
const bob = uid('bob');
const stranger = uid('stranger');

/**
 * Seed preconditions bypassing rules:
 * - A post doc owned by alice
 * - A feed entry for bob (so bob can read the post = can also read reactions)
 */
async function seedPost(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // Post doc — alice is author
    await db.doc(`posts/${postId}`).set({
      postId,
      authorId: alice,
      authorName: 'Alice',
      imageUrl: 'https://example.com/photo.jpg',
      audienceType: 'all',
      createdAt: new Date('2026-06-01'),
    });
    // Feed doc for bob → bob can read reactions via exists(feed/{postId})
    await db.doc(`users/${bob}/feed/${postId}`).set({
      postId,
      authorId: alice,
      createdAt: new Date('2026-06-01'),
    });
  });
}

function reactionDoc(overrides: Record<string, unknown> = {}) {
  return {
    reactorUid: alice,
    reactorName: 'Alice',
    emoji: '🤣',
    createdAt: new Date('2026-06-03'),
    ...overrides,
  };
}

// ===== /posts/{postId}/reactions/{reactorUid} =====

describe('/posts/{postId}/reactions/{reactorUid}', () => {
  test('create by post author (alice) → ALLOW', async () => {
    await seedPost();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${alice}`).set(reactionDoc()),
    );
  });

  test('create by user with feed doc (bob) → ALLOW', async () => {
    await seedPost();
    const db = authed(bob).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${bob}`).set(
        reactionDoc({ reactorUid: bob, reactorName: 'Bob' }),
      ),
    );
  });

  test('create by stranger (no feed doc) → DENY', async () => {
    await seedPost();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${stranger}`).set(
        reactionDoc({ reactorUid: stranger, reactorName: 'Stranger' }),
      ),
    );
  });

  test('create with reactorUid != auth.uid → DENY', async () => {
    await seedPost();
    const db = authed(bob).firestore();
    // bob tries to create a reaction doc WITH docId=bob BUT reactorUid field = alice
    await assertFails(
      db.doc(`posts/${postId}/reactions/${bob}`).set(
        reactionDoc({ reactorUid: alice, reactorName: 'impostor' }),
      ),
    );
  });

  test('create with empty emoji → DENY', async () => {
    await seedPost();
    const db = authed(alice).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ emoji: '' }),
      ),
    );
  });

  test('update emoji + createdAt by owner → ALLOW', async () => {
    await seedPost();
    // Seed reaction first
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ emoji: '🤣' }),
      );
    });
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ emoji: '🥰' }),
      ),
    );
  });

  test('update reactorUid field by owner → DENY', async () => {
    await seedPost();
    // Seed reaction first
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ reactorUid: alice }),
      );
    });
    // Try to change reactorUid (identity field — must be immutable after create)
    const db = authed(alice).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ reactorUid: bob }),
      ),
    );
  });

  test('delete by owner (alice) → ALLOW', async () => {
    await seedPost();
    // Seed reaction
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc(),
      );
    });
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${alice}`).delete(),
    );
  });

  test('delete by stranger → DENY', async () => {
    await seedPost();
    // Seed alice's reaction
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc(),
      );
    });
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).delete(),
    );
  });

  test('read by post author (alice) → ALLOW', async () => {
    await seedPost();
    const db = authed(alice).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${alice}`).get(),
    );
  });

  test('read by feed member (bob) → ALLOW', async () => {
    await seedPost();
    const db = authed(bob).firestore();
    await assertSucceeds(
      db.doc(`posts/${postId}/reactions/${alice}`).get(),
    );
  });

  test('read by non-audience (no feed doc, not author) → DENY', async () => {
    await seedPost();
    const db = authed(stranger).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).get(),
    );
  });

  test('read by unauthenticated → DENY', async () => {
    await seedPost();
    const db = unauthed().firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).get(),
    );
  });

  test('update by stranger (not owner of reaction) → DENY', async () => {
    await seedPost();
    // Seed alice's reaction
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ emoji: '🤣' }),
      );
    });
    // bob tries to update alice's reaction
    const db = authed(bob).firestore();
    await assertFails(
      db.doc(`posts/${postId}/reactions/${alice}`).set(
        reactionDoc({ reactorUid: alice, emoji: '👿' }),
      ),
    );
  });
});

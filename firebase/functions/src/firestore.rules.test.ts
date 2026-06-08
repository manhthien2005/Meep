/**
 * Firestore security rules unit tests.
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Covers: owner / friend / stranger / unauthenticated for each collection.
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';

// ===== Setup =====

let testEnv: RulesTestEnvironment;

const RULES_PATH = resolve(__dirname, '../../firestore.rules');

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'meep-test',
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9999,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
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

// ===== /users/{uid} =====

describe('/users/{uid}', () => {
  test('owner can read own doc', async () => {
    const alice = uid('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
    });
    await assertSucceeds(authed(alice).firestore().doc(`users/${alice}`).get());
  });

  test('friend can read full user doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const pid = pairId(alice, bob);
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
      await ctx.firestore().doc(`friendships/${pid}`).set({
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
    await assertSucceeds(authed(bob).firestore().doc(`users/${alice}`).get());
  });

  test('stranger cannot read full user doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
    });
    await assertFails(authed(bob).firestore().doc(`users/${alice}`).get());
  });

  test('unauthenticated cannot read', async () => {
    const alice = uid('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
    });
    await assertFails(unauthed().firestore().doc(`users/${alice}`).get());
  });

  test('owner can create own doc', async () => {
    const alice = uid('alice');
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).set({
        uid: alice,
        email: 'alice@example.com',
        displayName: 'Alice',
        username: 'alice',
        createdAt: new Date(),
      }),
    );
  });

  test('cannot create doc for another user', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await assertFails(
      authed(bob).firestore().doc(`users/${alice}`).set({ displayName: 'Alice' }),
    );
  });

  test('/users/{uid}/feed — owner can read', async () => {
    const alice = uid('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}/feed/post1`).set({ postId: 'post1' });
    });
    await assertSucceeds(authed(alice).firestore().doc(`users/${alice}/feed/post1`).get());
  });

  test('/users/{uid}/feed — owner cannot write', async () => {
    const alice = uid('alice');
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}/feed/post1`).set({ postId: 'post1' }),
    );
  });

  test('/users/{uid}/public/profile — authed stranger can read', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}/public/profile`).set({
        uid: alice,
        displayName: 'Alice',
        username: 'alice',
        avatarUrl: null,
        bio: null,
        isSearchable: true,
        updatedAt: new Date(),
      });
    });
    await assertSucceeds(
      authed(bob).firestore().doc(`users/${alice}/public/profile`).get(),
    );
  });

  test('/users/{uid}/public/profile — unauthenticated cannot read', async () => {
    const alice = uid('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}/public/profile`).set({
        uid: alice,
        displayName: 'Alice',
        username: 'alice',
        isSearchable: true,
        updatedAt: new Date(),
      });
    });
    await assertFails(
      unauthed().firestore().doc(`users/${alice}/public/profile`).get(),
    );
  });

  test('/users/{uid}/public/profile — client cannot write', async () => {
    const alice = uid('alice');
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}/public/profile`).set({
        uid: alice,
        displayName: 'Alice',
        username: 'alice',
        isSearchable: true,
        updatedAt: new Date(),
      }),
    );
  });
});

// ===== collectionGroup('public') =====

describe("collectionGroup('public')", () => {
  const alice = uid('alice');
  const bob = uid('bob');

  async function seedPublicProfiles() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}/public/profile`).set({
        uid: alice,
        displayName: 'Alice',
        username: 'alice',
        avatarUrl: null,
        bio: null,
        isSearchable: true,
        updatedAt: new Date(),
      });
      await ctx.firestore().doc(`users/${bob}/public/profile`).set({
        uid: bob,
        displayName: 'Bob',
        username: 'bob',
        avatarUrl: null,
        bio: null,
        isSearchable: true,
        updatedAt: new Date(),
      });
    });
  }

  test('authed username + isSearchable query succeeds', async () => {
    await seedPublicProfiles();
    const snap = await assertSucceeds(
      authed(alice)
        .firestore()
        .collectionGroup('public')
        .where('username', '==', 'alice')
        .where('isSearchable', '==', true)
        .get(),
    );
    expect(snap.docs.map((doc) => doc.data().uid)).toEqual([alice]);
  });

  test('authed uid in query succeeds', async () => {
    await seedPublicProfiles();
    const snap = await assertSucceeds(
      authed(alice)
        .firestore()
        .collectionGroup('public')
        .where('uid', 'in', [alice, bob])
        .get(),
    );
    expect(snap.docs.map((doc) => doc.data().uid).sort()).toEqual(
      [alice, bob].sort(),
    );
  });

  test('unauthenticated collection group query fails', async () => {
    await seedPublicProfiles();
    await assertFails(
      unauthed()
        .firestore()
        .collectionGroup('public')
        .where('username', '==', 'alice')
        .where('isSearchable', '==', true)
        .get(),
    );
  });
});

// ===== /users/{uid} — field validation (T5) =====

describe('/users/{uid} — field validation', () => {
  const alice = uid('alice');
  const validProfile = {
    uid: uid('alice'),
    email: 'alice@example.com',
    displayName: 'Alice Nguyen',
    username: 'alice',
    createdAt: new Date(),
    updatedAt: new Date(),
    postCount: 0,
    friendCount: 0,
    spaceCount: 0,
  };

  test('owner can create with valid fields', async () => {
    await assertSucceeds(authed(alice).firestore().doc(`users/${alice}`).set(validProfile));
  });

  test('missing required field — rejected', async () => {
    // omit displayName to test required field check
    const { displayName: _, ...missingDisplayName } = validProfile;
    void _;
    await assertFails(authed(alice).firestore().doc(`users/${alice}`).set(missingDisplayName));
  });

  test('username too short (< 3) — rejected', async () => {
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).set({ ...validProfile, username: 'ab' }),
    );
  });

  test('username too long (> 20) — rejected', async () => {
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .set({ ...validProfile, username: 'a'.repeat(21) }),
    );
  });

  test('username with uppercase — rejected (must be lowercase)', async () => {
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .set({ ...validProfile, username: 'Alice' }),
    );
  });

  test('owner can update non-immutable field', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ displayName: 'Alice Updated' }),
    );
  });

  // T9 — Profile spec allowlist fields có thể update qua client.
  // Firestore rule dùng blocklist (`!hasAny([immutable])`), nên Profile fields
  // tự động pass nếu không nằm trong blocklist.

  test('owner can update bio (Profile T1 allowlist)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ bio: 'New bio' }),
    );
  });

  test('owner can update dateOfBirth (Profile T1 allowlist)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ dateOfBirth: '01/01/2000' }),
    );
  });

  test('owner can update phoneNumber (Profile T1 allowlist)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ phoneNumber: '0912345678' }),
    );
  });

  test('owner can update gender (Profile T1 allowlist)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ gender: 'female' }),
    );
  });

  test('owner can update avatarUrl (Profile T1 allowlist)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .update({ avatarUrl: 'https://cdn/avatar.jpg' }),
    );
  });

  test('owner can set avatarUrl = null (removeAvatar path)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({
        ...validProfile,
        avatarUrl: 'https://cdn/old.jpg',
      });
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`users/${alice}`).update({ avatarUrl: null }),
    );
  });

  test('other authed user cannot update owner profile', async () => {
    const bob = uid('bob');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(bob)
        .firestore()
        .doc(`users/${alice}`)
        .update({ displayName: 'Hacked' }),
    );
  });

  test('owner cannot update uid — immutable', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).update({ uid: 'different-uid' }),
    );
  });

  test('owner cannot update email — immutable', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .update({ email: 'newemail@example.com' }),
    );
  });

  test('owner cannot update username — immutable once set', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).update({ username: 'newname' }),
    );
  });

  test('owner cannot update postCount — server-only counter', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).update({ postCount: 999 }),
    );
  });

  test('owner cannot update friendCount — server-only counter', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).update({ friendCount: 999 }),
    );
  });

  test('owner cannot update spaceCount — server-only counter', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice).firestore().doc(`users/${alice}`).update({ spaceCount: 999 }),
    );
  });

  test('owner cannot set displayName > 50 chars', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .update({ displayName: 'A'.repeat(51) }),
    );
  });

  test('owner cannot set avatarUrl > 500 chars', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .update({ avatarUrl: 'a'.repeat(501) }),
    );
  });

  test('owner cannot set bio > 300 chars', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`users/${alice}`)
        .update({ bio: 'b'.repeat(301) }),
    );
  });

  test('delete always denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set(validProfile);
    });
    await assertFails(authed(alice).firestore().doc(`users/${alice}`).delete());
  });
});

// ===== /usernames/{username} (T5) =====

describe('/usernames/{username}', () => {
  const alice = uid('alice');
  const bob = uid('bob');

  test('authed user can read any username doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('usernames/alice').set({ uid: alice });
    });
    await assertSucceeds(authed(bob).firestore().doc('usernames/alice').get());
  });

  // allow read: if true — unauthenticated có thể check username availability
  // trước khi signup (email flow chưa có Firebase Auth session khi đến bước này).
  test('unauthenticated CAN read — needed for pre-auth username check', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('usernames/alice').set({ uid: alice });
    });
    await assertSucceeds(unauthed().firestore().doc('usernames/alice').get());
  });

  test('owner can create username doc with matching uid', async () => {
    await assertSucceeds(
      authed(alice).firestore().doc('usernames/alice').set({ uid: alice }),
    );
  });

  test('cannot create username doc with different uid', async () => {
    await assertFails(
      authed(bob).firestore().doc('usernames/alice').set({ uid: alice }),
    );
  });

  test('owner can delete own username doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('usernames/alice').set({ uid: alice });
    });
    await assertSucceeds(authed(alice).firestore().doc('usernames/alice').delete());
  });

  test('non-owner cannot delete', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('usernames/alice').set({ uid: alice });
    });
    await assertFails(authed(bob).firestore().doc('usernames/alice').delete());
  });

  test('update always denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('usernames/alice').set({ uid: alice });
    });
    await assertFails(authed(alice).firestore().doc('usernames/alice').update({ uid: bob }));
  });
});

// ===== /posts/{postId} =====

describe('/posts/{postId}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const POST_ID = 'post-abc';

  async function seedPost() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${POST_ID}`).set({
        authorId: alice,
        authorName: 'Alice',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: 'all',
        createdAt: new Date(),
      });
      // Fan-out: bob has this post in his feed
      await ctx.firestore().doc(`users/${bob}/feed/${POST_ID}`).set({ postId: POST_ID });
    });
  }

  test('author can read own post', async () => {
    await seedPost();
    await assertSucceeds(authed(alice).firestore().doc(`posts/${POST_ID}`).get());
  });

  test('user with feed doc can read', async () => {
    await seedPost();
    await assertSucceeds(authed(bob).firestore().doc(`posts/${POST_ID}`).get());
  });

  test('stranger without feed doc cannot read', async () => {
    await seedPost();
    await assertFails(authed(stranger).firestore().doc(`posts/${POST_ID}`).get());
  });

  test('unauthenticated cannot read', async () => {
    await seedPost();
    await assertFails(unauthed().firestore().doc(`posts/${POST_ID}`).get());
  });

  test('author can delete own post', async () => {
    await seedPost();
    await assertSucceeds(authed(alice).firestore().doc(`posts/${POST_ID}`).delete());
  });

  test('non-author cannot delete', async () => {
    await seedPost();
    await assertFails(authed(bob).firestore().doc(`posts/${POST_ID}`).delete());
  });
});

// ===== /friend_requests/{requestId} =====

describe('/friend_requests/{requestId}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const REQ_ID = 'req-1';

  async function seedRequest() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friend_requests/${REQ_ID}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
  }

  test('sender can read', async () => {
    await seedRequest();
    await assertSucceeds(authed(alice).firestore().doc(`friend_requests/${REQ_ID}`).get());
  });

  test('receiver can read', async () => {
    await seedRequest();
    await assertSucceeds(authed(bob).firestore().doc(`friend_requests/${REQ_ID}`).get());
  });

  test('stranger cannot read', async () => {
    await seedRequest();
    await assertFails(authed(stranger).firestore().doc(`friend_requests/${REQ_ID}`).get());
  });

  test('sender can create own request', async () => {
    await assertSucceeds(
      authed(alice).firestore().doc(`friend_requests/${REQ_ID}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('cannot create request as another user', async () => {
    await assertFails(
      authed(bob).firestore().doc(`friend_requests/${REQ_ID}`).set({
        senderId: alice,
        receiverId: bob,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('nobody can delete (server-side only)', async () => {
    await seedRequest();
    await assertFails(
      authed(bob).firestore().doc(`friend_requests/${REQ_ID}`).delete(),
    );
  });
});

// ===== /blocks/{blockId} =====

describe('/blocks/{blockId}', () => {
  const blocker = uid('blocker');
  const blocked = uid('blocked');
  const stranger = uid('stranger');
  const BLOCK_ID = `${blocker}_${blocked}`;

  async function seedBlock() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`blocks/${BLOCK_ID}`).set({
        blockerUid: blocker,
        blockedUid: blocked,
        blockId: BLOCK_ID,
        createdAt: new Date(),
      });
    });
  }

  test('blocker can read', async () => {
    await seedBlock();
    await assertSucceeds(authed(blocker).firestore().doc(`blocks/${BLOCK_ID}`).get());
  });

  test('blocked user can read', async () => {
    await seedBlock();
    await assertSucceeds(authed(blocked).firestore().doc(`blocks/${BLOCK_ID}`).get());
  });

  test('stranger cannot read', async () => {
    await seedBlock();
    await assertFails(authed(stranger).firestore().doc(`blocks/${BLOCK_ID}`).get());
  });

  test('nobody can write (server-side only)', async () => {
    await assertFails(
      authed(blocker).firestore().doc(`blocks/${BLOCK_ID}`).set({
        blockerUid: blocker,
        blockedUid: blocked,
        blockId: BLOCK_ID,
        createdAt: new Date(),
      }),
    );
  });
});

// ===== /diary/{entryId} =====

describe('/diary/{entryId}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const ENTRY_ID = 'entry-1';

  async function seedEntry(privacy: 'private' | 'public') {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy,
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Happy day',
        content: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      // Make bob a friend of alice
      const pairId = [alice, bob].sort().join('_');
      await ctx.firestore().doc(`friendships/${pairId}`).set({
        uid1: alice,
        uid2: bob,
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
  }

  test('owner can read private entry', async () => {
    await seedEntry('private');
    await assertSucceeds(authed(alice).firestore().doc(`diary/${ENTRY_ID}`).get());
  });

  test('friend can read public entry', async () => {
    await seedEntry('public');
    await assertSucceeds(authed(bob).firestore().doc(`diary/${ENTRY_ID}`).get());
  });

  test('friend cannot read private entry', async () => {
    await seedEntry('private');
    await assertFails(authed(bob).firestore().doc(`diary/${ENTRY_ID}`).get());
  });

  test('stranger cannot read', async () => {
    await seedEntry('public');
    await assertFails(authed(stranger).firestore().doc(`diary/${ENTRY_ID}`).get());
  });

  test('unauthenticated cannot read', async () => {
    await seedEntry('public');
    await assertFails(unauthed().firestore().doc(`diary/${ENTRY_ID}`).get());
  });

  test('owner can create entry', async () => {
    await assertSucceeds(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Happy day',
        content: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('moodCaption > 50 chars rejected', async () => {
    await assertFails(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'A'.repeat(51),
        content: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('owner can delete own entry', async () => {
    await seedEntry('private');
    await assertSucceeds(authed(alice).firestore().doc(`diary/${ENTRY_ID}`).delete());
  });

  test('stranger cannot delete', async () => {
    await seedEntry('private');
    await assertFails(authed(stranger).firestore().doc(`diary/${ENTRY_ID}`).delete());
  });

  test('content > 20 blocks rejected', async () => {
    // Spec §Data model: max 20 content blocks per entry.
    // Rule firestore.rules `/diary/{id}` enforce: request.resource.data.content.size() <= 20.
    const twentyOneBlocks = Array.from({ length: 21 }, (_, i) => ({
      type: 'text',
      value: `block ${i}`,
    }));
    await assertFails(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Lots of blocks',
        content: twentyOneBlocks,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('content == 20 blocks accepted (boundary inclusive)', async () => {
    // Rule cap là `<= 20` (inclusive). Bảo vệ off-by-one nếu rule drift sang `< 20`.
    const twentyBlocks = Array.from({ length: 20 }, (_, i) => ({
      type: 'text',
      value: `block ${i}`,
    }));
    await assertSucceeds(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Max blocks',
        content: twentyBlocks,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('owner can update own entry (caption + content)', async () => {
    await seedEntry('private');
    await assertSucceeds(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Updated title',
        content: [{ type: 'text', value: 'Updated body' }],
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('update cannot change authorUid (author hijack)', async () => {
    // Rule: request.resource.data.authorUid == resource.data.authorUid
    // → bob (logged in as bob) cannot reassign alice's entry to himself,
    //   nor can alice flip authorUid to someone else.
    await seedEntry('private');
    await assertFails(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: bob, // hijack attempt
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Hijacked',
        content: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });
});

// ===== /conversations/{conversationId} =====

describe('/conversations/{conversationId}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const CONV_ID = [alice, bob].sort().join('_');

  async function seedConversation() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${CONV_ID}`).set({
        conversationId: CONV_ID,
        type: 'direct',
        participantIds: [alice, bob],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      });
    });
  }

  test('participant can read', async () => {
    await seedConversation();
    await assertSucceeds(authed(alice).firestore().doc(`conversations/${CONV_ID}`).get());
  });

  test('non-participant cannot read', async () => {
    await seedConversation();
    await assertFails(authed(stranger).firestore().doc(`conversations/${CONV_ID}`).get());
  });

  test('unauthenticated cannot read', async () => {
    await seedConversation();
    await assertFails(unauthed().firestore().doc(`conversations/${CONV_ID}`).get());
  });

  test('participant can send message when active', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-1`)
        .set({
          messageId: 'msg-1',
          senderId: alice,
          text: 'Hello!',
          createdAt: new Date(),
        }),
    );
  });

  test('non-participant cannot send message', async () => {
    await seedConversation();
    await assertFails(
      authed(stranger)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-1`)
        .set({
          messageId: 'msg-1',
          senderId: stranger,
          text: 'Hello!',
          createdAt: new Date(),
        }),
    );
  });

  test('message text > 500 chars rejected', async () => {
    await seedConversation();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-1`)
        .set({
          messageId: 'msg-1',
          senderId: alice,
          text: 'A'.repeat(501),
          createdAt: new Date(),
        }),
    );
  });

  // --- Query / list operations (regression: hasAll bug on list eval) ---

  test('participant can query conversations by participantIds', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .collection('conversations')
        .where('participantIds', 'array-contains', alice)
        .get(),
    );
  });

  test('non-participant query returns empty (rule filter)', async () => {
    await seedConversation();
    const snap = await assertSucceeds(
      authed(stranger)
        .firestore()
        .collection('conversations')
        .where('participantIds', 'array-contains', stranger)
        .get(),
    );
    // Firestore rules silently filter out docs the user can't read
    expect(snap.empty).toBe(true);
  });

  test('participant can query messages subcollection', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .collection(`conversations/${CONV_ID}/messages`)
        .orderBy('createdAt')
        .get(),
    );
  });

  test('participant cannot send message when conversation is blocked', async () => {
    await seedConversation();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${CONV_ID}`).update({
        status: 'blocked',
      });
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-blocked`)
        .set({
          messageId: 'msg-blocked',
          senderId: alice,
          text: 'Should be blocked',
          createdAt: new Date(),
        }),
    );
  });

  test('message edit is denied', async () => {
    await seedConversation();
    // First create a message (as alice)
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-edit`)
        .set({
          messageId: 'msg-edit',
          senderId: alice,
          text: 'Original',
          createdAt: new Date(),
        });
    });
    // Now try to update it with rules enabled
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-edit`)
        .update({ text: 'Edited' }),
    );
  });

  test('message delete is denied', async () => {
    await seedConversation();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-del`)
        .set({
          messageId: 'msg-del',
          senderId: alice,
          text: 'To delete',
          createdAt: new Date(),
        });
    });
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-del`)
        .delete(),
    );
  });
});

// ===== /posts — update field whitelist + caption cap (POST-SEC-001) =====

describe('/posts/{postId} — update', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const POST_ID = 'post-upd';

  async function seedPost() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${POST_ID}`).set({
        authorId: alice,
        authorName: 'Alice',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: 'all',
        caption: 'ok',
        createdAt: new Date(),
      });
    });
  }

  test('author can edit caption (within cap)', async () => {
    await seedPost();
    await assertSucceeds(
      authed(alice).firestore().doc(`posts/${POST_ID}`).update({ caption: 'updated' }),
    );
  });

  test('author cannot set caption > 200 chars', async () => {
    await seedPost();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`posts/${POST_ID}`)
        .update({ caption: 'a'.repeat(201) }),
    );
  });

  test('author cannot mutate imageUrl (not in whitelist)', async () => {
    await seedPost();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`posts/${POST_ID}`)
        .update({ imageUrl: 'https://evil.com/x.jpg' }),
    );
  });

  test('author cannot mutate authorId', async () => {
    await seedPost();
    await assertFails(
      authed(alice).firestore().doc(`posts/${POST_ID}`).update({ authorId: bob }),
    );
  });

  test('non-author cannot update', async () => {
    await seedPost();
    await assertFails(
      authed(bob).firestore().doc(`posts/${POST_ID}`).update({ caption: 'hijack' }),
    );
  });
});

// ===== /posts/{postId}/reactions — field validation (REACTION-SEC-001) =====

describe('/posts/{postId}/reactions/{reactorUid}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const POST_ID = 'post-react';

  async function seedPostAndFeed() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${POST_ID}`).set({
        authorId: alice,
        authorName: 'Alice',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: 'all',
        createdAt: new Date(),
      });
      // bob nhận post qua feed fan-out → được react.
      await ctx.firestore().doc(`users/${bob}/feed/${POST_ID}`).set({ postId: POST_ID });
    });
  }

  test('reactor can create valid reaction', async () => {
    await seedPostAndFeed();
    await assertSucceeds(
      authed(bob).firestore().doc(`posts/${POST_ID}/reactions/${bob}`).set({
        reactorUid: bob,
        reactorName: 'Bob',
        emoji: '❤️',
        createdAt: new Date(),
      }),
    );
  });

  test('reactorName > 50 chars rejected on create', async () => {
    await seedPostAndFeed();
    await assertFails(
      authed(bob).firestore().doc(`posts/${POST_ID}/reactions/${bob}`).set({
        reactorUid: bob,
        reactorName: 'B'.repeat(51),
        emoji: '❤️',
        createdAt: new Date(),
      }),
    );
  });

  test('emoji > 32 chars rejected on create', async () => {
    await seedPostAndFeed();
    await assertFails(
      authed(bob).firestore().doc(`posts/${POST_ID}/reactions/${bob}`).set({
        reactorUid: bob,
        reactorName: 'Bob',
        emoji: '😀'.repeat(20),
        createdAt: new Date(),
      }),
    );
  });

  test('reactor cannot tamper reactorName > 50 on update', async () => {
    await seedPostAndFeed();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`posts/${POST_ID}/reactions/${bob}`).set({
        reactorUid: bob,
        reactorName: 'Bob',
        emoji: '❤️',
        createdAt: new Date(),
      });
    });
    await assertFails(
      authed(bob)
        .firestore()
        .doc(`posts/${POST_ID}/reactions/${bob}`)
        .update({ reactorName: 'X'.repeat(51) }),
    );
  });
});

// ===== /conversations — create gate + update tamper (CHAT-SEC-001/002) =====

describe('/conversations — create friend/space gate', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');

  test('friend can create direct conversation', async () => {
    const convId = [alice, bob].sort().join('_');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${convId}`).set({
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`conversations/${convId}`).set({
        conversationId: convId,
        type: 'direct',
        participantIds: [alice, bob],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      }),
    );
  });

  test('stranger (no friendship) cannot create direct conversation', async () => {
    const convId = [alice, stranger].sort().join('_');
    await assertFails(
      authed(alice).firestore().doc(`conversations/${convId}`).set({
        conversationId: convId,
        type: 'direct',
        participantIds: [alice, stranger],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      }),
    );
  });

  test('cannot forge conversationId to a friend pairId while DM-ing a non-friend', async () => {
    // alice friend bob (friendships/alice_bob exists). alice tries to create
    // doc at id=alice_bob but with participantIds=[alice, stranger] → must DENY
    // (conversationId không khớp pairId của participantIds).
    const bobPair = [alice, bob].sort().join('_');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${bobPair}`).set({
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
    await assertFails(
      authed(alice).firestore().doc(`conversations/${bobPair}`).set({
        conversationId: bobPair,
        type: 'direct',
        participantIds: [alice, stranger],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      }),
    );
  });

  test('space member can create space conversation', async () => {
    const SPACE_ID = 'space-conv-1';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`spaces/${SPACE_ID}`).set({
        creatorId: alice,
        memberIds: [alice, bob],
        name: 'Space',
        createdAt: new Date(),
      });
    });
    await assertSucceeds(
      authed(alice).firestore().doc(`conversations/${SPACE_ID}`).set({
        conversationId: SPACE_ID,
        type: 'space',
        participantIds: [alice, bob],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      }),
    );
  });
});

describe('/conversations — update tamper guards', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const CONV_ID = [alice, bob].sort().join('_');

  async function seedConversation() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${CONV_ID}`).set({
        conversationId: CONV_ID,
        type: 'direct',
        participantIds: [alice, bob],
        status: 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      });
    });
  }

  test('participant can update with valid lastMessage + own lastSenderId', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice).firestore().doc(`conversations/${CONV_ID}`).update({
        lastMessage: 'Hi',
        lastMessageAt: new Date(),
        lastSenderId: alice,
      }),
    );
  });

  test('cannot forge lastSenderId to another user', async () => {
    await seedConversation();
    await assertFails(
      authed(alice).firestore().doc(`conversations/${CONV_ID}`).update({
        lastMessage: 'fake from bob',
        lastSenderId: bob,
      }),
    );
  });

  test('cannot set lastMessage > 500 chars', async () => {
    await seedConversation();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .update({ lastMessage: 'a'.repeat(501), lastSenderId: alice }),
    );
  });

  test('markAsRead dot-notation lastReadAt still allowed', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .update({ [`lastReadAt.${alice}`]: new Date() }),
    );
  });
});

// ===== /diary — update privacy enum + type guard (DIARY-SEC-001) =====

describe('/diary/{entryId} — update validation', () => {
  const alice = uid('alice');
  const ENTRY_ID = 'entry-upd';

  async function seedEntry() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`diary/${ENTRY_ID}`).set({
        authorUid: alice,
        privacy: 'private',
        moodTemplate: 'happy',
        coverImageUrl: 'https://example.com/cover.jpg',
        moodCaption: 'Title',
        content: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
  }

  test('owner can update with valid privacy', async () => {
    await seedEntry();
    await assertSucceeds(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).update({
        moodCaption: 'New title',
        updatedAt: new Date(),
      }),
    );
  });

  test('invalid privacy enum rejected on update', async () => {
    await seedEntry();
    await assertFails(
      authed(alice).firestore().doc(`diary/${ENTRY_ID}`).update({ privacy: 'leaked' }),
    );
  });
});

// ===== /friendships/{pid} (TESTING-SEC-001 coverage) =====

describe('/friendships/{pid}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const PID = [alice, bob].sort().join('_');

  async function seedFriendship() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${PID}`).set({
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
  }

  test('member can read', async () => {
    await seedFriendship();
    await assertSucceeds(authed(alice).firestore().doc(`friendships/${PID}`).get());
  });

  test('non-member cannot read', async () => {
    await seedFriendship();
    await assertFails(authed(stranger).firestore().doc(`friendships/${PID}`).get());
  });

  test('member cannot read friendship with mismatched pairId', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('friendships/not-the-pair-id').set({
        members: [alice, bob],
        createdAt: new Date(),
      });
    });
    await assertFails(
      authed(alice).firestore().doc('friendships/not-the-pair-id').get(),
    );
  });

  test('client cannot create (server-side only)', async () => {
    await assertFails(
      authed(alice).firestore().doc(`friendships/${PID}`).set({
        members: [alice, bob],
        createdAt: new Date(),
      }),
    );
  });

  test('member can delete (unfriend)', async () => {
    await seedFriendship();
    await assertSucceeds(authed(alice).firestore().doc(`friendships/${PID}`).delete());
  });

  test('non-member cannot delete', async () => {
    await seedFriendship();
    await assertFails(authed(stranger).firestore().doc(`friendships/${PID}`).delete());
  });
});

// ===== No open rules guard =====

describe('security invariants', () => {
  test('unauthenticated cannot access any root collection', async () => {
    await assertFails(unauthed().firestore().collection('posts').get());
    await assertFails(unauthed().firestore().collection('users').get());
    await assertFails(unauthed().firestore().collection('diary').get());
  });
});

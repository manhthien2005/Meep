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
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';

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

// ===== /users/{uid} =====

describe('/users/{uid}', () => {
  test('owner can read own doc', async () => {
    const alice = uid('alice');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
    });
    await assertSucceeds(authed(alice).firestore().doc(`users/${alice}`).get());
  });

  test('other authed user can read', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${alice}`).set({ displayName: 'Alice' });
    });
    await assertSucceeds(authed(bob).firestore().doc(`users/${alice}`).get());
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

// ===== No open rules guard =====

describe('security invariants', () => {
  test('unauthenticated cannot access any root collection', async () => {
    await assertFails(unauthed().firestore().collection('posts').get());
    await assertFails(unauthed().firestore().collection('users').get());
    await assertFails(unauthed().firestore().collection('diary').get());
  });
});

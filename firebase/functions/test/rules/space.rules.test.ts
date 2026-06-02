/**
 * Firestore security rules tests for Space module.
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * Tests:
 *   - /spaces/{spaceId}: read (isMember), create/delete (false), update (isCreator)
 *   - /space_members/{spaceId}/members/{uid}: read (isMember), CRUD (false → CF only)
 *   - /posts/{postId} with spaceId: Space member read ✓ (via /users/{uid}/feed/{postId})
 *
 * Pattern mirror friend.rules.test.ts.
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
    projectId: 'meep-test-space',
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
 * Seed Space + members subcollection bypassing rules — preconditions cho
 * test cases. Mirror pattern client/CF tạo Space.
 */
async function seedSpace(
  spaceId: string,
  creatorId: string,
  memberIds: string[],
): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`spaces/${spaceId}`).set({
      spaceId,
      name: 'Test Space',
      iconEmoji: '👥',
      colorHex: '#00DEEE',
      creatorId,
      memberCount: memberIds.length,
      memberIds,
      createdAt: new Date(),
    });
    for (const memberUid of memberIds) {
      await db
        .doc(`space_members/${spaceId}/members/${memberUid}`)
        .set({
          uid: memberUid,
          role: memberUid === creatorId ? 'creator' : 'member',
          joinedAt: new Date(),
        });
    }
  });
}

// ===== /spaces/{spaceId} — read =====

describe('/spaces/{spaceId} — read', () => {
  test('member can read Space', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertSucceeds(authed(bob).firestore().doc('spaces/s1').get());
  });

  test('creator can read Space', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(authed(alice).firestore().doc('spaces/s1').get());
  });

  test('non-member cannot read Space', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    const charlie = uid('charlie');
    await seedSpace('s1', alice, [alice, bob]);

    await assertFails(authed(charlie).firestore().doc('spaces/s1').get());
  });

  test('unauthenticated cannot read Space', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(unauthed().firestore().doc('spaces/s1').get());
  });

  // QUERY tests — quan trọng vì `watchMySpaces` dùng collection query với
  // arrayContains, không phải single doc get. Pattern rule check subcol
  // qua exists() KHÔNG work cho query — đây là gap đã gây PERMISSION_DENIED
  // trong prod trước khi đổi sang `resource.data.memberIds in` pattern.

  test('member can query spaces where memberIds arrayContains uid', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);
    await seedSpace('s2', alice, [alice]); // bob KHÔNG trong s2

    // Bob query collection /spaces where memberIds arrayContains bob.
    // Rule `request.auth.uid in resource.data.memberIds` filter per-doc:
    // s1 pass (bob trong memberIds), s2 không match query (bob không
    // trong memberIds) → query trả về s1 only.
    const querySnap = await assertSucceeds(
      authed(bob)
        .firestore()
        .collection('spaces')
        .where('memberIds', 'array-contains', bob)
        .get(),
    );
    // querySnap is QuerySnapshot returned by assertSucceeds.
    // Verify chỉ trả về Space mà bob là member.
    // (rules-unit-testing assertSucceeds trả về raw promise result.)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const docs = (querySnap as any).docs as Array<{ id: string }>;
    if (docs.length !== 1 || docs[0]?.id !== 's1') {
      throw new Error(
        `Expected query to return [s1], got [${docs.map((d) => d.id).join(', ')}]`,
      );
    }
  });

  test('non-member query without filter fails (rule blocks)', async () => {
    const alice = uid('alice');
    const charlie = uid('charlie');
    await seedSpace('s1', alice, [alice]);

    // Charlie không trong bất kỳ memberIds nào — query without where filter
    // sẽ trả về tất cả docs nhưng mỗi doc fail rule → query reject.
    await assertFails(
      authed(charlie).firestore().collection('spaces').get(),
    );
  });
});

// ===== /spaces/{spaceId} — write =====

describe('/spaces/{spaceId} — write', () => {
  test('client cannot create Space (CF only)', async () => {
    const alice = uid('alice');
    await assertFails(
      authed(alice).firestore().doc('spaces/s1').set({
        spaceId: 's1',
        name: 'New Space',
        iconEmoji: '👥',
        colorHex: '#00DEEE',
        creatorId: alice,
        memberCount: 1,
        memberIds: [alice],
        createdAt: new Date(),
      }),
    );
  });

  test('creator can update Space (e.g. soft delete via deletedAt)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ deletedAt: new Date() }),
    );
  });

  test('non-creator member cannot update Space', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertFails(
      authed(bob)
        .firestore()
        .doc('spaces/s1')
        .update({ name: 'Renamed' }),
    );
  });

  test('non-member cannot update Space', async () => {
    const alice = uid('alice');
    const charlie = uid('charlie');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(charlie)
        .firestore()
        .doc('spaces/s1')
        .update({ name: 'Renamed' }),
    );
  });

  test('non-creator member cannot soft-delete (set deletedAt)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    // Soft delete = update deletedAt. Chỉ creator được phép (rule
    // isCreator). Test này quan trọng: member KHÔNG được destroy Space
    // của creator qua soft-delete trick.
    await assertFails(
      authed(bob)
        .firestore()
        .doc('spaces/s1')
        .update({ deletedAt: new Date() }),
    );
  });

  test('client cannot delete Space (soft-delete via update only)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(authed(alice).firestore().doc('spaces/s1').delete());
  });
});

// ===== /spaces/{spaceId} — update field whitelist + type validation =====
//
// Sau khi siết rule update với:
//   - affectedKeys().hasOnly([name, iconEmoji, colorHex, deletedAt, updatedAt])
//   - type/size check cho name (1-30), iconEmoji (1-32), colorHex (#RRGGBB)
// 12 cases: 4 happy + 4 forbidden field + 3 type validation + 1 combined.

describe('/spaces/{spaceId} — update whitelist', () => {
  test('creator can update name to valid string (1-30 chars)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ name: 'Renamed Space' }),
    );
  });

  test('creator can update iconEmoji', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ iconEmoji: '🎉' }),
    );
  });

  test('creator can update colorHex with valid hex', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ colorHex: '#FF6B6B' }),
    );
  });

  test('creator can update name + iconEmoji + colorHex combined', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertSucceeds(
      authed(alice).firestore().doc('spaces/s1').update({
        name: 'Renamed',
        iconEmoji: '🌟',
        colorHex: '#22D3EE',
      }),
    );
  });

  test('creator CANNOT update creatorId (whitelist block)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ creatorId: bob }),
    );
  });

  test('creator CANNOT update memberIds (whitelist block)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ memberIds: [alice, uid('hacker')] }),
    );
  });

  test('creator CANNOT update memberCount (whitelist block)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice).firestore().doc('spaces/s1').update({ memberCount: 99 }),
    );
  });

  test('creator CANNOT update createdAt (whitelist block)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ createdAt: new Date(0) }),
    );
  });

  test('creator CANNOT update name to empty string (size < 1)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice).firestore().doc('spaces/s1').update({ name: '' }),
    );
  });

  test('creator CANNOT update name to > 30 chars', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ name: 'a'.repeat(31) }),
    );
  });

  test('creator CANNOT update colorHex with invalid format', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({ colorHex: 'red' }),
    );
  });

  test('creator CANNOT update name + memberIds combined (whitelist block toàn bộ)', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    // Tampering trick: try update field allowed (name) cùng field cấm
    // (memberIds) trong cùng update. hasOnly() block toàn bộ — đảm bảo
    // client không bypass whitelist bằng cách piggy-back.
    await assertFails(
      authed(alice)
        .firestore()
        .doc('spaces/s1')
        .update({
          name: 'Renamed',
          memberIds: [alice, uid('hacker')],
        }),
    );
  });
});

// ===== /space_members/{spaceId}/members/{uid} =====

describe('/space_members/{spaceId}/members/{uid}', () => {
  test('member can read own member doc', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertSucceeds(
      authed(bob).firestore().doc(`space_members/s1/members/${bob}`).get(),
    );
  });

  test('member can read other members docs', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertSucceeds(
      authed(bob).firestore().doc(`space_members/s1/members/${alice}`).get(),
    );
  });

  test('non-member cannot read member docs', async () => {
    const alice = uid('alice');
    const charlie = uid('charlie');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(charlie)
        .firestore()
        .doc(`space_members/s1/members/${alice}`)
        .get(),
    );
  });

  test('unauthenticated cannot read member docs', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      unauthed().firestore().doc(`space_members/s1/members/${alice}`).get(),
    );
  });

  test('client cannot create member doc (CF only)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice]);

    await assertFails(
      authed(alice).firestore().doc(`space_members/s1/members/${bob}`).set({
        uid: bob,
        role: 'member',
        joinedAt: new Date(),
      }),
    );
  });

  test('client cannot delete member doc (CF leaveSpace/kickMember only)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertFails(
      authed(bob).firestore().doc(`space_members/s1/members/${bob}`).delete(),
    );
  });

  test('client cannot update member role (e.g. promote self to creator)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);

    await assertFails(
      authed(bob)
        .firestore()
        .doc(`space_members/s1/members/${bob}`)
        .update({ role: 'creator' }),
    );
  });
});

// ===== /posts/{postId} with spaceId — read =====
//
// Posts dùng allow read rule combined cho 3 cases (author / friend /
// /users/{uid}/feed/{postId} exists). Space member read post Space qua
// nhánh thứ 3 — CF spacePostFanOut ghi /users/{uid}/feed/{postId} cho
// mọi member khi Space post create.

describe('/posts/{postId} with spaceId', () => {
  async function seedSpacePost(
    postId: string,
    authorId: string,
    spaceId: string,
    memberUids: string[],
  ): Promise<void> {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.doc(`posts/${postId}`).set({
        postId,
        authorId,
        authorName: 'Author',
        imageUrl: 'https://example.com/photo.jpg',
        audienceType: 'all',
        audienceUids: [],
        spaceId,
        createdAt: new Date(),
      });
      // Mirror spacePostFanOut: ghi /users/{uid}/feed/{postId} cho mọi
      // Space member (kể cả author).
      for (const memberUid of memberUids) {
        await db.doc(`users/${memberUid}/feed/${postId}`).set({
          postId,
          authorId,
          spaceId,
          createdAt: new Date(),
        });
      }
    });
  }

  test('Space member can read Space post (via /users/{uid}/feed entry)', async () => {
    const alice = uid('alice');
    const bob = uid('bob');
    await seedSpace('s1', alice, [alice, bob]);
    await seedSpacePost('p1', alice, 's1', [alice, bob]);

    await assertSucceeds(authed(bob).firestore().doc('posts/p1').get());
  });

  test('Space author can read own Space post', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);
    await seedSpacePost('p1', alice, 's1', [alice]);

    await assertSucceeds(authed(alice).firestore().doc('posts/p1').get());
  });

  test('non-member without feed entry cannot read Space post', async () => {
    const alice = uid('alice');
    const charlie = uid('charlie');
    await seedSpace('s1', alice, [alice]);
    // Note: charlie không có /users/charlie/feed/p1 entry vì không phải
    // Space member. Cũng không phải author + không phải friend của author
    // → 3 nhánh allow read đều fail.
    await seedSpacePost('p1', alice, 's1', [alice]);

    await assertFails(authed(charlie).firestore().doc('posts/p1').get());
  });

  test('unauthenticated cannot read Space post', async () => {
    const alice = uid('alice');
    await seedSpace('s1', alice, [alice]);
    await seedSpacePost('p1', alice, 's1', [alice]);

    await assertFails(unauthed().firestore().doc('posts/p1').get());
  });
});

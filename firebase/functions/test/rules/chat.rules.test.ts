/**
 * Firestore security rules tests — Chat module.
 *
 * Covers: /conversations/{conversationId} +
 *         /conversations/{conversationId}/messages/{messageId}
 *
 * Run via: firebase emulators:exec --only firestore "npm run test:rules"
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, test, expect } from 'vitest';

// ===== Setup =====

let testEnv: RulesTestEnvironment;

const RULES_PATH = resolve(__dirname, '../../../firestore.rules');

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'meep-test-chat',
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

// ===== /conversations/{conversationId} =====

describe('/conversations/{conversationId}', () => {
  const alice = uid('alice');
  const bob = uid('bob');
  const stranger = uid('stranger');
  const CONV_ID = [alice, bob].sort().join('_');

  /**
   * Seed an active 1-1 conversation between alice and bob.
   * Fields match the Conversation freezed model (JSON camelCase).
   */
  async function seedConversation(overrides?: { status?: string }) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`conversations/${CONV_ID}`).set({
        conversationId: CONV_ID,
        type: 'direct',
        participantIds: [alice, bob],
        status: overrides?.status ?? 'active',
        lastMessage: '',
        lastMessageAt: new Date(),
        lastSenderId: '',
        createdAt: new Date(),
      });
    });
  }

  // --- Read -----------------------------------------------------------------

  test('participant can read conversation', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice).firestore().doc(`conversations/${CONV_ID}`).get(),
    );
  });

  test('non-participant cannot read conversation', async () => {
    await seedConversation();
    await assertFails(
      authed(stranger)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .get(),
    );
  });

  test('unauthenticated cannot read conversation', async () => {
    await seedConversation();
    await assertFails(
      unauthed().firestore().doc(`conversations/${CONV_ID}`).get(),
    );
  });

  test('participant can query conversations by participantIds (list)', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .collection('conversations')
        .where('participantIds', 'array-contains', alice)
        .get(),
    );
  });

  test('participant can query conversations với orderBy lastMessageAt (Inbox)',
      async () => {
    // Reproduction case của bug Inbox "Không tải được tin nhắn":
    // rule cũ dùng `isParticipant(conversationId)` qua `get()` → Firestore
    // engine fail list query → PERMISSION_DENIED toàn collection. Fix (commit
    // 103691b reapplied) đổi sang `resource.data.participantIds` direct.
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .collection('conversations')
        .where('participantIds', 'array-contains', alice)
        .orderBy('lastMessageAt', 'desc')
        .get(),
    );
  });

  test('authed user can get non-existent conversation doc (getOrCreate flow)',
      async () => {
    // Reproduction case của bug Reply Post "không gửi được tin nhắn":
    // rule mới `request.auth.uid in resource.data.participantIds` fail khi
    // doc chưa tồn tại → resource null → PERMISSION_DENIED. Fix `resource ==
    // null || ...` cho phép client check exists trước khi create.
    const newConvId = [alice, uid('charlie')].sort().join('_');
    // Doc CHƯA seed — getOrCreate cần get() đầu tiên để check.
    const doc = await assertSucceeds(
      authed(alice).firestore().doc(`conversations/${newConvId}`).get(),
    );
    expect(doc.exists).toBe(false);
  });

  test('non-participant query returns empty via rule filter', async () => {
    await seedConversation();
    const snap = await assertSucceeds(
      authed(stranger)
        .firestore()
        .collection('conversations')
        .where('participantIds', 'array-contains', stranger)
        .get(),
    );
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

  // --- Write: messages ------------------------------------------------------

  test('participant can send message ≤500 chars', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-1`)
        .set({
          messageId: 'msg-1',
          senderId: alice,
          text: 'Xin chào!',
          createdAt: new Date(),
        }),
    );
  });

  test('non-participant cannot send message', async () => {
    await seedConversation();
    await assertFails(
      authed(stranger)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-stranger`)
        .set({
          messageId: 'msg-stranger',
          senderId: stranger,
          text: 'Hello!',
          createdAt: new Date(),
        }),
    );
  });

  test('message text >500 chars rejected', async () => {
    await seedConversation();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-long`)
        .set({
          messageId: 'msg-long',
          senderId: alice,
          text: 'A'.repeat(501),
          createdAt: new Date(),
        }),
    );
  });

  // --- senderDisplayName denormalization (Bug #2) -------------------------

  test('message với senderDisplayName ≤50 chars OK', async () => {
    await seedConversation();
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-name`)
        .set({
          messageId: 'msg-name',
          senderId: alice,
          text: 'Xin chào',
          createdAt: new Date(),
          senderDisplayName: 'Alice Nguyen',
        }),
    );
  });

  test('message với senderDisplayName >50 chars rejected', async () => {
    await seedConversation();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-long-name`)
        .set({
          messageId: 'msg-long-name',
          senderId: alice,
          text: 'hi',
          createdAt: new Date(),
          senderDisplayName: 'A'.repeat(51),
        }),
    );
  });

  test('message với senderDisplayName non-string rejected', async () => {
    await seedConversation();
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}/messages/msg-non-string-name`)
        .set({
          messageId: 'msg-non-string-name',
          senderId: alice,
          text: 'hi',
          createdAt: new Date(),
          senderDisplayName: 42,
        }),
    );
  });

  test('participant cannot send message when conversation is blocked', async () => {
    await seedConversation({ status: 'blocked' });
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
    // Create a message with rules disabled, then try to edit it.
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

  // --- Write: conversations -------------------------------------------------

  test('friend can create direct conversation (CHAT-SEC-001)',
      async () => {
    const charlie = uid('charlie');
    const newConvId = [alice, charlie].sort().join('_');
    // Friendship doc gate create — seed trước (id == sorted pairId).
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`friendships/${newConvId}`).set({
        members: [alice, charlie],
        createdAt: new Date(),
      });
    });
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${newConvId}`)
        .set({
          conversationId: newConvId,
          type: 'direct',
          participantIds: [alice, charlie],
          status: 'active',
          lastMessage: '',
          lastMessageAt: new Date(),
          lastSenderId: '',
          createdAt: new Date(),
        }),
    );
  });

  test('non-friend cannot create direct conversation (CHAT-SEC-001)',
      async () => {
    const newConvId = [alice, stranger].sort().join('_');
    // No friendship doc → create denied (chống stranger spam DM).
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${newConvId}`)
        .set({
          conversationId: newConvId,
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

  // --- markAsRead (lastReadAt field) ----------------------------------------

  test('participant can update lastReadAt for self (markAsRead)', async () => {
    await seedConversation();
    // Dot-notation field update: lastReadAt.{uid} — pattern client dùng.
    await assertSucceeds(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .update({ [`lastReadAt.${alice}`]: new Date() }),
    );
  });

  test('non-participant cannot update lastReadAt', async () => {
    await seedConversation();
    await assertFails(
      authed(stranger)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .update({ [`lastReadAt.${stranger}`]: new Date() }),
    );
  });

  test('participant cannot sneak non-whitelisted field via update', async () => {
    await seedConversation();
    // Update whitelist allow: lastMessage, lastMessageAt, lastSenderId, lastReadAt.
    // Cố tình đổi participantIds → fail.
    await assertFails(
      authed(alice)
        .firestore()
        .doc(`conversations/${CONV_ID}`)
        .update({ participantIds: [alice] }),
    );
  });
});

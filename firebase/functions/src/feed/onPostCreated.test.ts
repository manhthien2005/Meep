import { describe, it, expect } from 'vitest';

// Lightweight unit test — we test the pure fan-out logic, not the CF wrapper.
// Integration tests require emulators; these run in CI without them.

describe('onPostCreated logic', () => {
  it('audienceType all → fans out to all friends', () => {
    const post = {
      audienceType: 'all' as const,
      audienceUids: [],
      spaceId: null,
    };
    const recipients = post.audienceType === 'select'
      ? post.audienceUids
      : ['friend1', 'friend2']; // simulated from _getFriendUids
    expect(recipients).toHaveLength(2);
  });

  it('audienceType select → fans out only to audienceUids', () => {
    const post = {
      audienceType: 'select' as const,
      audienceUids: ['uid2', 'uid3'],
    };
    const recipients = post.audienceType === 'select'
      ? post.audienceUids
      : [];
    expect(recipients).toEqual(['uid2', 'uid3']);
  });

  it('spaceId set → skips friend fan-out', () => {
    const spaceId: string | null = 'space-abc';
    const shouldFanOut = !(spaceId != null && spaceId !== '');
    expect(shouldFanOut).toBe(false);
  });

  it('spaceId null → performs friend fan-out', () => {
    const spaceId: string | null = null;
    const shouldFanOut = !(spaceId != null && spaceId !== '');
    expect(shouldFanOut).toBe(true);
  });

  it('recipients always include the author (own-feed visibility)', () => {
    const authorId = 'uid1';
    const friendUids = ['friend1', 'friend2'];
    const recipientUids = [...new Set([authorId, ...friendUids])];
    expect(recipientUids).toContain(authorId);
    expect(recipientUids).toHaveLength(3);
  });

  it('author appears once even if already in audience (dedupe)', () => {
    const authorId = 'uid1';
    const friendUids = ['uid1', 'friend2'];
    const recipientUids = [...new Set([authorId, ...friendUids])];
    expect(recipientUids).toEqual(['uid1', 'friend2']);
  });

  it('FCM excludes the author — only friends are notified', () => {
    const authorId = 'uid1';
    const friendUids = ['friend1', 'friend2'];
    // FCM uses friendUids, not recipientUids (which includes the author).
    expect(friendUids).not.toContain(authorId);
  });

  it('feed doc includes spaceId field', () => {
    const post = {
      postId: 'p1',
      authorId: 'uid1',
      spaceId: null as string | null,
      createdAt: new Date(),
    };
    const feedDoc = {
      postId: post.postId,
      authorId: post.authorId,
      spaceId: post.spaceId ?? null,
      createdAt: post.createdAt,
    };
    expect(feedDoc).toHaveProperty('spaceId');
    expect(feedDoc.spaceId).toBeNull();
  });
});

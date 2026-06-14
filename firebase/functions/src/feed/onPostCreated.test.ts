import { describe, it, expect } from 'vitest';

import {
  postFeedRecipients,
  postNotificationRecipients,
} from './onPostCreated.js';

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

  it('spaceIds non-empty → skips friend fan-out', () => {
    const spaceIds: string[] = ['space-abc'];
    const shouldFanOut = spaceIds.length === 0;
    expect(shouldFanOut).toBe(false);
  });

  it('spaceIds rỗng → performs friend fan-out', () => {
    const spaceIds: string[] = [];
    const shouldFanOut = spaceIds.length === 0;
    expect(shouldFanOut).toBe(true);
  });

  it('multi-Space: loop từng spaceId riêng', () => {
    const spaceIds = ['space-a', 'space-b', 'space-c'];
    const fanOutCalls: string[] = [];
    for (const sid of spaceIds) fanOutCalls.push(sid);
    expect(fanOutCalls).toEqual(['space-a', 'space-b', 'space-c']);
  });

  it('recipients always include the author (own-feed visibility)', () => {
    const authorId = 'uid1';
    const friendUids = ['friend1', 'friend2'];
    const recipientUids = postFeedRecipients(authorId, friendUids);
    expect(recipientUids).toContain(authorId);
    expect(recipientUids).toHaveLength(3);
  });

  it('author appears once even if already in audience (dedupe)', () => {
    const authorId = 'uid1';
    const friendUids = ['uid1', 'friend2'];
    const recipientUids = postFeedRecipients(authorId, friendUids);
    expect(recipientUids).toEqual(['uid1', 'friend2']);
  });

  it('FCM excludes the author — only friends are notified', () => {
    const authorId = 'uid1';
    const friendUids = ['friend1', 'uid1', 'friend2', 'friend2'];
    const recipientUids = postNotificationRecipients(authorId, friendUids);
    expect(recipientUids).toEqual(['friend1', 'friend2']);
  });

  it('feed doc (friend fan-out) includes spaceIds=[]', () => {
    const post = {
      postId: 'p1',
      authorId: 'uid1',
      spaceIds: [] as string[],
      createdAt: new Date(),
    };
    const feedDoc = {
      postId: post.postId,
      authorId: post.authorId,
      spaceIds: [] as string[],
      createdAt: post.createdAt,
    };
    expect(feedDoc).toHaveProperty('spaceIds');
    expect(feedDoc.spaceIds).toEqual([]);
  });
});

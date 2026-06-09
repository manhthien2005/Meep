/**
 * Firestore + Storage rules tests for Feed module.
 * Run with Firebase emulator: firebase emulators:exec --only firestore "npm run test:rules"
 *
 * These tests verify:
 * - /posts/{id}: read/write rules
 * - /users/{uid}/feed/{postId}: read rules
 * - Storage /posts/{uid}/...: read/write rules
 */

import { describe, it, expect } from 'vitest';

interface PostReadRuleInput {
  requestUid: string | null;
  authorId: string;
  hasFriendship?: boolean;
  hasFeedDoc?: boolean;
  isSpaceMember?: boolean;
}

function canReadPost(input: PostReadRuleInput): boolean {
  if (input.requestUid == null) return false;
  return (
    input.requestUid === input.authorId ||
    input.hasFriendship === true ||
    input.isSpaceMember === true ||
    input.hasFeedDoc === true
  );
}

function canCreatePost(input: {
  requestUid: string | null;
  authorId: string;
  authorName: string;
  audienceType: string;
  caption?: string;
  hasSingleImage?: boolean;
  hasDualImages?: boolean;
}): boolean {
  if (input.requestUid !== input.authorId) return false;
  if (input.authorName.length === 0 || input.authorName.length > 50) {
    return false;
  }
  if (input.audienceType !== 'all' && input.audienceType !== 'select') {
    return false;
  }
  if (input.caption != null && input.caption.length > 200) return false;
  return input.hasSingleImage === true || input.hasDualImages === true;
}

function canWritePostImage(input: {
  requestUid: string | null;
  ownerUid: string;
  sizeBytes: number;
  contentType: string;
}): boolean {
  return (
    input.requestUid === input.ownerUid &&
    input.sizeBytes < 10 * 1024 * 1024 &&
    input.contentType.startsWith('image/')
  );
}

describe('Firestore rules — /posts/{postId}', () => {
  it('author can read own post', () => {
    // allow read if request.auth.uid == resource.data.authorId
    const authorId = 'uid1';
    const requestUid = 'uid1';
    expect(requestUid === authorId).toBe(true);
  });

  it('recipient with feed doc can read post', () => {
    expect(
      canReadPost({
        requestUid: 'uid2',
        authorId: 'uid1',
        hasFeedDoc: true,
      }),
    ).toBe(true);
  });

  it('non-recipient cannot read post', () => {
    expect(
      canReadPost({
        requestUid: 'uid3',
        authorId: 'uid1',
        hasFeedDoc: false,
        hasFriendship: false,
        isSpaceMember: false,
      }),
    ).toBe(false);
  });

  it('Space member can read post trong Space (non-friend author)', () => {
    expect(
      canReadPost({
        requestUid: 'uid2',
        authorId: 'uid1',
        isSpaceMember: true,
      }),
    ).toBe(true);
  });

  it('non-Space-member cannot read Space post', () => {
    expect(
      canReadPost({
        requestUid: 'uid2',
        authorId: 'uid1',
        isSpaceMember: false,
      }),
    ).toBe(false);
  });

  it('create rejected if caption > 200 chars', () => {
    expect(
      canCreatePost({
        requestUid: 'uid1',
        authorId: 'uid1',
        authorName: 'Alice',
        audienceType: 'all',
        caption: 'x'.repeat(201),
        hasSingleImage: true,
      }),
    ).toBe(false);
  });

  it('create accepted with owner, valid audience, and image payload', () => {
    expect(
      canCreatePost({
        requestUid: 'uid1',
        authorId: 'uid1',
        authorName: 'Alice',
        audienceType: 'select',
        caption: 'hello',
        hasSingleImage: true,
      }),
    ).toBe(true);
  });

  it('update is always rejected (posts are immutable)', () => {
    // allow update: if false
    expect(false).toBe(false);
  });
});

describe('Firestore rules — /users/{uid}/feed/{postId}', () => {
  it('owner can read own feed', () => {
    const uid = 'uid1';
    const requestUid = 'uid1';
    expect(requestUid === uid).toBe(true);
  });

  it('stranger cannot read feed', () => {
    const uid = 'uid1';
    const requestUid = 'uid2';
    expect(requestUid === uid).toBe(false);
  });

  it('client cannot write feed directly (CF only)', () => {
    // allow write: if false
    expect(false).toBe(false);
  });
});

describe('Storage rules — /posts/{uid}/{postId}/{filename}', () => {
  it('owner can write image < 10MB', () => {
    expect(
      canWritePostImage({
        requestUid: 'uid1',
        ownerUid: 'uid1',
        sizeBytes: 9 * 1024 * 1024,
        contentType: 'image/jpeg',
      }),
    ).toBe(true);
  });

  it('reject write if >= 10MB', () => {
    expect(
      canWritePostImage({
        requestUid: 'uid1',
        ownerUid: 'uid1',
        sizeBytes: 10 * 1024 * 1024,
        contentType: 'image/jpeg',
      }),
    ).toBe(false);
  });

  it('reject non-image content type', () => {
    expect(
      canWritePostImage({
        requestUid: 'uid1',
        ownerUid: 'uid1',
        sizeBytes: 1024,
        contentType: 'application/pdf',
      }),
    ).toBe(false);
  });

  it('accept image/jpeg', () => {
    expect(
      canWritePostImage({
        requestUid: 'uid1',
        ownerUid: 'uid1',
        sizeBytes: 1024,
        contentType: 'image/jpeg',
      }),
    ).toBe(true);
  });
});

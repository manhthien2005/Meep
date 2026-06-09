import { describe, it, expect } from 'vitest';

import {
  parseDeletedFriendshipUids,
  shouldDeleteCrossFeedEntry,
} from '../../src/friend/onFriendshipDeleted.js';

describe('onFriendshipDeleted helpers', () => {
  it('parses valid deleted friendship payload', () => {
    expect(
      parseDeletedFriendshipUids({ uid1: 'uid-a', uid2: 'uid-b' }),
    ).toEqual({ uid1: 'uid-a', uid2: 'uid-b' });
  });

  it('rejects missing or malformed deleted friendship payload', () => {
    expect(parseDeletedFriendshipUids(undefined)).toBeNull();
    expect(parseDeletedFriendshipUids({ uid1: 'uid-a' })).toBeNull();
    expect(parseDeletedFriendshipUids({ uid1: '', uid2: 'uid-b' })).toBeNull();
    expect(parseDeletedFriendshipUids({ uid1: 'uid-a', uid2: 123 })).toBeNull();
  });

  it('deletes only former-friend non-Space feed entries', () => {
    expect(
      shouldDeleteCrossFeedEntry(
        { authorId: 'uid-b', spaceIds: [] },
        'uid-b',
      ),
    ).toBe(true);
    expect(
      shouldDeleteCrossFeedEntry(
        { authorId: 'uid-b', spaceIds: ['space-1'] },
        'uid-b',
      ),
    ).toBe(false);
    expect(
      shouldDeleteCrossFeedEntry(
        { authorId: 'uid-c', spaceIds: [] },
        'uid-b',
      ),
    ).toBe(false);
  });
});

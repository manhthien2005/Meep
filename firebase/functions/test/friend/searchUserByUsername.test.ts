import { describe, expect, it } from 'vitest';

import {
  buildSearchUserProfile,
  normalizeSearchUsername,
} from '../../src/friend/searchUserByUsername.js';
import { publicProfileSourceSchema } from '../../src/user/publicProfile.js';

describe('searchUserByUsername helpers', () => {
  it('normalizes exact username search', () => {
    expect(normalizeSearchUsername('  ThienPDM  ')).toBe('thienpdm');
    expect(normalizeSearchUsername('ab')).toBeNull();
    expect(normalizeSearchUsername('invalid-name')).toBeNull();
  });

  it('builds a public search profile without private fields', () => {
    const source = publicProfileSourceSchema.parse({
      email: 'alice@example.com',
      displayName: 'Alice Nguyen',
      username: 'alice',
      avatarUrl: null,
      bio: 'Meep user',
      friendCount: 10,
      isSearchable: true,
    });

    const profile = buildSearchUserProfile('uid-alice', source, {
      toMillis: () => 123,
    });

    expect(profile).toEqual({
      uid: 'uid-alice',
      displayName: 'Alice Nguyen',
      username: 'alice',
      avatarUrl: null,
      bio: 'Meep user',
      isSearchable: true,
      updatedAtMillis: 123,
    });
    expect(profile).not.toHaveProperty('email');
    expect(profile).not.toHaveProperty('friendCount');
  });

  it('returns null for users who opted out of username search', () => {
    const source = publicProfileSourceSchema.parse({
      displayName: 'Alice Nguyen',
      username: 'alice',
      isSearchable: false,
    });

    expect(buildSearchUserProfile('uid-alice', source, Date.now())).toBeNull();
  });
});

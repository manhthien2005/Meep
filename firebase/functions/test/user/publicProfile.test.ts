import { describe, expect, it } from 'vitest';

import {
  buildPublicProfileData,
  migratePublicProfilesSchema,
  publicProfileSourceSchema,
} from '../../src/user/publicProfile.js';

describe('public profile projection', () => {
  it('copies only public fields', () => {
    const source = publicProfileSourceSchema.parse({
      email: 'alice@example.com',
      displayName: 'Alice',
      username: 'alice',
      avatarUrl: 'https://cdn.example.com/a.jpg',
      bio: 'Meep user',
      friendCount: 10,
      postCount: 20,
    });

    const publicProfile = buildPublicProfileData('uid-alice', source, 'now');

    expect(publicProfile).toEqual({
      uid: 'uid-alice',
      displayName: 'Alice',
      username: 'alice',
      avatarUrl: 'https://cdn.example.com/a.jpg',
      bio: 'Meep user',
      isSearchable: true,
      updatedAt: 'now',
    });
    expect(publicProfile).not.toHaveProperty('email');
    expect(publicProfile).not.toHaveProperty('friendCount');
    expect(publicProfile).not.toHaveProperty('postCount');
  });

  it('keeps isSearchable=false for privacy opt-out', () => {
    const source = publicProfileSourceSchema.parse({
      displayName: 'Alice',
      username: 'alice',
      isSearchable: false,
    });

    const publicProfile = buildPublicProfileData('uid-alice', source, 'now');

    expect(publicProfile.isSearchable).toBe(false);
  });

  it('rejects public fields over length caps', () => {
    expect(
      publicProfileSourceSchema.safeParse({
        displayName: 'A'.repeat(51),
        username: 'alice',
      }).success,
    ).toBe(false);
    expect(
      publicProfileSourceSchema.safeParse({
        displayName: 'Alice',
        username: 'alice',
        avatarUrl: 'a'.repeat(501),
      }).success,
    ).toBe(false);
    expect(
      publicProfileSourceSchema.safeParse({
        displayName: 'Alice',
        username: 'alice',
        bio: 'b'.repeat(301),
      }).success,
    ).toBe(false);
  });

  it('migration callable input is strict', () => {
    expect(migratePublicProfilesSchema.safeParse({}).success).toBe(true);
    expect(
      migratePublicProfilesSchema.safeParse({ dryRun: true }).success,
    ).toBe(false);
  });
});

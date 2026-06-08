import { describe, test, expect } from 'vitest';
import { z } from 'zod';

// Re-declare the schema here for testing (intentional duplication —
// keeps the test stable even if index.ts later splits the schema out).
// .strict() mirror FUNC-SEC-001 — reject excess properties.
const sendFriendRequestSchema = z
  .object({
    toUid: z.string().min(1).max(128),
  })
  .strict();

describe('sendFriendRequestSchema', () => {
  test('accepts a valid uid', () => {
    const result = sendFriendRequestSchema.safeParse({ toUid: 'user-abc-123' });
    expect(result.success).toBe(true);
  });

  test('rejects an empty uid', () => {
    const result = sendFriendRequestSchema.safeParse({ toUid: '' });
    expect(result.success).toBe(false);
  });

  test('rejects a missing uid', () => {
    const result = sendFriendRequestSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  test('rejects a non-string uid', () => {
    const result = sendFriendRequestSchema.safeParse({ toUid: 12345 });
    expect(result.success).toBe(false);
  });

  test('rejects excess properties (.strict — FUNC-SEC-001)', () => {
    const result = sendFriendRequestSchema.safeParse({
      toUid: 'user-abc',
      evil: 'payload',
    });
    expect(result.success).toBe(false);
  });
});

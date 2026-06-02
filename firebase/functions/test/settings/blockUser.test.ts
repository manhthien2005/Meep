import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// Mirror schema từ src/settings/blockUser.ts để test isolated (không cần
// emulator). Integration test full batch flow (blocks create + friendships
// delete + conversations status update) sẽ ở rules test với emulator (T8 #120).
const blockUserSchema = z.object({
  targetUid: z.string().min(1).max(128),
});

describe('blockUser schema', () => {
  it('accepts valid targetUid', () => {
    const result = blockUserSchema.safeParse({ targetUid: 'user1' });
    expect(result.success).toBe(true);
  });

  it('rejects empty targetUid', () => {
    const result = blockUserSchema.safeParse({ targetUid: '' });
    expect(result.success).toBe(false);
  });

  it('rejects missing targetUid', () => {
    const result = blockUserSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it('rejects non-string targetUid', () => {
    const result = blockUserSchema.safeParse({ targetUid: 123 });
    expect(result.success).toBe(false);
  });

  it('rejects targetUid > 128 chars (Firebase Auth UID hard limit)', () => {
    const result = blockUserSchema.safeParse({ targetUid: 'a'.repeat(129) });
    expect(result.success).toBe(false);
  });

  it('accepts targetUid = 128 chars (boundary)', () => {
    const result = blockUserSchema.safeParse({ targetUid: 'a'.repeat(128) });
    expect(result.success).toBe(true);
  });
});

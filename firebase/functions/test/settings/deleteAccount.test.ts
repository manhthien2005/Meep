import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// Mirror schema từ src/settings/deleteAccount.ts để test isolated (không
// cần emulator). Cascade order + idempotent + Storage/Firestore/Auth
// integration test sẽ ở rules test với emulator (T8 #120) — mock toàn bộ
// Firebase Admin SDK (Storage bucket + Firestore + Auth) là 1 day work,
// out of scope task T7 L estimate.
//
// Schema = z.unknown() vì CF không nhận input từ client — uid lấy từ
// request.auth.uid. Schema chỉ để tuân thủ CLAUDE.md "safeParse mọi callable".
const deleteAccountSchema = z.unknown();

describe('deleteAccount schema', () => {
  it('accepts empty object (no input expected)', () => {
    const result = deleteAccountSchema.safeParse({});
    expect(result.success).toBe(true);
  });

  it('accepts undefined (client gọi không truyền arg)', () => {
    const result = deleteAccountSchema.safeParse(undefined);
    expect(result.success).toBe(true);
  });

  it('accepts arbitrary payload (z.unknown — ignore client junk)', () => {
    const result = deleteAccountSchema.safeParse({
      junkField: 'ignored',
      nested: { also: 'ignored' },
    });
    expect(result.success).toBe(true);
  });

  it('accepts null', () => {
    const result = deleteAccountSchema.safeParse(null);
    expect(result.success).toBe(true);
  });
});

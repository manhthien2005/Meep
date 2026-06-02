import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// Mirror schema từ src/space/updateSpace.ts để test isolated (không cần
// emulator). Handler logic (auth/not-found/permission/deleted) test ở
// rules test với emulator + integration test sau.
const updateSpaceSchema = z
  .object({
    spaceId: z.string().min(1).max(128),
    name: z.string().trim().min(1).max(30).optional(),
    iconEmoji: z.string().min(1).max(32).optional(),
    colorHex: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/, 'colorHex must be #RRGGBB')
      .optional(),
  })
  .refine(
    (d) =>
      d.name !== undefined ||
      d.iconEmoji !== undefined ||
      d.colorHex !== undefined,
    {
      message:
        'At least one field (name/iconEmoji/colorHex) must be provided',
    },
  );

describe('updateSpace schema', () => {
  it('accepts valid input with all 3 cosmetic fields', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: 'Renamed',
      iconEmoji: '👨‍👩‍👧‍👦',
      colorHex: '#BFD5FF',
    });
    expect(result.success).toBe(true);
  });

  it('accepts partial update — name only', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: 'Renamed',
    });
    expect(result.success).toBe(true);
  });

  it('accepts partial update — iconEmoji only', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      iconEmoji: '🎉',
    });
    expect(result.success).toBe(true);
  });

  it('accepts partial update — colorHex only', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#FF6B6B',
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty patch — refine fail (cả 3 field cosmetic undefined)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty spaceId', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: '',
      name: 'X',
    });
    expect(result.success).toBe(false);
  });

  it('rejects spaceId > 128 chars', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 'a'.repeat(129),
      name: 'X',
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty name', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: '',
    });
    expect(result.success).toBe(false);
  });

  it('rejects whitespace-only name (trim → empty)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: '   ',
    });
    expect(result.success).toBe(false);
  });

  it('rejects name > 30 chars', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: 'a'.repeat(31),
    });
    expect(result.success).toBe(false);
  });

  it('trims name leading/trailing whitespace', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: '  Family  ',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.name).toBe('Family');
    }
  });

  it('rejects empty iconEmoji', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      iconEmoji: '',
    });
    expect(result.success).toBe(false);
  });

  it('rejects iconEmoji > 32 chars', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      iconEmoji: '👨'.repeat(20),
    });
    expect(result.success).toBe(false);
  });

  it('accepts colorHex with uppercase hex', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#ABCDEF',
    });
    expect(result.success).toBe(true);
  });

  it('accepts colorHex with lowercase hex', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#abcdef',
    });
    expect(result.success).toBe(true);
  });

  it('rejects malformed colorHex (no #)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: 'FF6B6B',
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (3-char shorthand)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#FFF',
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (8-char with alpha)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#FF6B6BFF',
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (non-hex chars)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      colorHex: '#GGGGGG',
    });
    expect(result.success).toBe(false);
  });

  it('accepts 2 fields combined (name + colorHex)', () => {
    const result = updateSpaceSchema.safeParse({
      spaceId: 's1',
      name: 'Renamed',
      colorHex: '#FFD93D',
    });
    expect(result.success).toBe(true);
  });
});

// TODO(#137/ThienPDM): Integration tests với Firebase emulator + admin
// callable testing:
// - Happy path: creator update name → /spaces doc updated, updatedAt fresh
// - Non-creator member → permission-denied
// - Space deleted (deletedAt set) → failed-precondition
// - Space not found → not-found
// - Partial update: chỉ field passed mới update, các field khác giữ nguyên
//
// Setup: firebase emulators:start --only firestore,functions

import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// Mirror schema từ src/space/createSpace.ts để test isolated (không cần
// emulator). Integration test full batch flow sẽ ở rules test với emulator.
const createSpaceSchema = z.object({
  name: z.string().trim().min(1).max(30),
  iconEmoji: z.string().min(1).max(32),
  colorHex: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'colorHex must be #RRGGBB'),
  friendUids: z.array(z.string().min(1).max(128)).max(9),
});

describe('createSpace schema', () => {
  it('accepts valid input', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '👨‍👩‍👧‍👦',
      colorHex: '#BFD5FF',
      friendUids: ['friend1', 'friend2'],
    });
    expect(result.success).toBe(true);
  });

  it('accepts empty friendUids (solo Space)', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Solo',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty name', () => {
    const result = createSpaceSchema.safeParse({
      name: '',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('rejects whitespace-only name (trim → empty)', () => {
    const result = createSpaceSchema.safeParse({
      name: '   ',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('rejects name > 30 chars', () => {
    const result = createSpaceSchema.safeParse({
      name: 'a'.repeat(31),
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (no #)', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '🎃',
      colorHex: 'FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (3-char shorthand)', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '🎃',
      colorHex: '#FFF',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('rejects malformed colorHex (8-char with alpha)', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '🎃',
      colorHex: '#FEEBCAFF',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });

  it('accepts colorHex with lowercase hex', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '🎃',
      colorHex: '#feebca',
      friendUids: [],
    });
    expect(result.success).toBe(true);
  });

  it('rejects friendUids > 9 items', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Big',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: Array.from({ length: 10 }, (_, i) => `friend${i}`),
    });
    expect(result.success).toBe(false);
  });

  it('accepts exactly 9 friendUids (max)', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Full',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: Array.from({ length: 9 }, (_, i) => `friend${i}`),
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty string in friendUids', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '🎃',
      colorHex: '#FEEBCA',
      friendUids: ['friend1', ''],
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty iconEmoji', () => {
    const result = createSpaceSchema.safeParse({
      name: 'Family',
      iconEmoji: '',
      colorHex: '#FEEBCA',
      friendUids: [],
    });
    expect(result.success).toBe(false);
  });
});

// TODO(#136/ThienPDM): Integration tests với Firebase emulator:
// - Full happy path: tạo Space + 2 friends → /spaces + /space_members + /conversations đều có
// - Friendship check: invite non-friend → throw failed-precondition
// - Creator role: subcollection doc của creatorId có role='creator', còn lại 'member'
// - memberCount + memberIds.length đồng bộ
// - Dedup friendUids: duplicate input → unique trong memberIds
//
// Setup: firebase emulators:start --only firestore,functions

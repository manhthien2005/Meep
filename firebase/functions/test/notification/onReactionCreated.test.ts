import { describe, it, expect } from 'vitest';
import { isSelfReaction } from '../../src/notification/onReactionCreated.js';

describe('isSelfReaction', () => {
  it('returns true when reactor is the post author', () => {
    expect(isSelfReaction('uid-1', 'uid-1')).toBe(true);
  });

  it('returns false when reactor is someone else', () => {
    expect(isSelfReaction('reactor-uid', 'author-uid')).toBe(false);
  });

  it('treats empty strings as equal (both empty → skip)', () => {
    // Defensive: if upstream gave us blank ids we shouldn't notify anyway.
    expect(isSelfReaction('', '')).toBe(true);
  });

  it('uses strict equality (no whitespace tolerance)', () => {
    // FCM/Firestore uids are opaque exact strings — never normalize.
    expect(isSelfReaction('uid ', 'uid')).toBe(false);
  });
});

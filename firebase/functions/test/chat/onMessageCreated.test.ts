import { describe, expect, it } from 'vitest';
import {
  bodyPreview,
  receiversOf,
} from '../../src/chat/onMessageCreated.js';

describe('receiversOf', () => {
  it('returns participants excluding sender', () => {
    expect(receiversOf(['uid-a', 'uid-b'], 'uid-a')).toEqual(['uid-b']);
  });

  it('returns empty when sender is the only participant', () => {
    expect(receiversOf(['uid-a'], 'uid-a')).toEqual([]);
  });

  it('returns empty when participantIds is missing', () => {
    expect(receiversOf(undefined, 'uid-a')).toEqual([]);
  });

  it('returns empty when participantIds is not an array', () => {
    expect(receiversOf('uid-a,uid-b', 'uid-a')).toEqual([]);
  });

  it('skips non-string entries defensively', () => {
    expect(receiversOf(['uid-a', 42, null, 'uid-c'], 'uid-a')).toEqual([
      'uid-c',
    ]);
  });

  it('supports group conversations — all non-sender participants returned', () => {
    expect(
      receiversOf(['uid-a', 'uid-b', 'uid-c', 'uid-d'], 'uid-b'),
    ).toEqual(['uid-a', 'uid-c', 'uid-d']);
  });
});

describe('bodyPreview', () => {
  it('falls back to default copy for empty message', () => {
    expect(bodyPreview('')).toBe('Đã gửi tin nhắn mới');
  });

  it('returns text unchanged when ≤ 100 chars', () => {
    const text = 'Tin nhắn ngắn nè';
    expect(bodyPreview(text)).toBe(text);
  });

  it('truncates to 97 chars + "..." when > 100 chars', () => {
    const text = 'a'.repeat(150);
    const out = bodyPreview(text);
    expect(out.length).toBe(100);
    expect(out.endsWith('...')).toBe(true);
    expect(out.startsWith('a'.repeat(97))).toBe(true);
  });

  it('preserves UTF-8 Vietnamese characters in short text', () => {
    const text = 'Mai mình đi cà phê nhé, có cả Khoa với Hân nữa.';
    expect(bodyPreview(text)).toBe(text);
  });
});

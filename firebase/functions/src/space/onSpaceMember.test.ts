import { describe, test, expect } from 'vitest';
import { shouldCountJoin } from './onSpaceMemberAdded.js';
import { shouldCountLeave } from './onSpaceMemberRemoved.js';

// FUNC-SEC-002 — marker-based idempotency. Transaction reads marker existence
// then decides whether to apply the spaceCount delta.

describe('shouldCountJoin', () => {
  test('first event (no marker) → count the join', () => {
    expect(shouldCountJoin(false)).toBe(true);
  });

  test('re-fire (marker exists) → skip increment', () => {
    expect(shouldCountJoin(true)).toBe(false);
  });
});

describe('shouldCountLeave', () => {
  test('first delete (marker exists) → count the leave', () => {
    expect(shouldCountLeave(true)).toBe(true);
  });

  test('re-fire (marker already gone) → skip decrement', () => {
    expect(shouldCountLeave(false)).toBe(false);
  });
});

describe('join/leave pairing keeps spaceCount balanced', () => {
  test('a single join followed by a single leave nets zero', () => {
    // join: marker absent → +1, marker set
    expect(shouldCountJoin(false)).toBe(true);
    // duplicate join: marker present → skip
    expect(shouldCountJoin(true)).toBe(false);
    // leave: marker present → -1, marker deleted
    expect(shouldCountLeave(true)).toBe(true);
    // duplicate leave: marker absent → skip
    expect(shouldCountLeave(false)).toBe(false);
  });
});

import { describe, it, expect } from 'vitest';
import { isAcceptedTransition } from '../../src/notification/onFriendRequestAccepted.js';

describe('isAcceptedTransition', () => {
  it('fires on pending → accepted (the canonical case)', () => {
    expect(isAcceptedTransition('pending', 'accepted')).toBe(true);
  });

  it('skips no-op update (accepted → accepted)', () => {
    // Without this guard, every updatedAt touch on an already-accepted
    // request would re-push the notification.
    expect(isAcceptedTransition('accepted', 'accepted')).toBe(false);
  });

  it('skips pending → declined', () => {
    expect(isAcceptedTransition('pending', 'declined')).toBe(false);
  });

  it('skips pending → pending (no status change)', () => {
    expect(isAcceptedTransition('pending', 'pending')).toBe(false);
  });

  it('also fires on declined → accepted (defensive, real flow unlikely)', () => {
    // Rule firestore.rules:188-194 only allows pending → accepted/declined,
    // so this should never happen in prod — but if it does we still want
    // the sender to know they're now friends.
    expect(isAcceptedTransition('declined', 'accepted')).toBe(true);
  });

  it('skips when afterStatus is missing', () => {
    expect(isAcceptedTransition('pending', undefined)).toBe(false);
  });

  it('skips when afterStatus is not a string', () => {
    expect(isAcceptedTransition('pending', 123)).toBe(false);
  });

  it('treats missing beforeStatus as non-accepted (fires)', () => {
    // Defensive: if `before` is malformed but `after` is accepted, still notify.
    expect(isAcceptedTransition(undefined, 'accepted')).toBe(true);
  });
});

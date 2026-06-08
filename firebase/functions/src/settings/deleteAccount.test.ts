import { describe, test, expect } from 'vitest';
import {
  isReauthWithinWindow,
  REAUTH_WINDOW_SECONDS,
} from './deleteAccount.js';

describe('isReauthWithinWindow (AUTH-SEC-001)', () => {
  const now = 1_000_000;

  test('fresh token (auth_time = now) is within window', () => {
    expect(isReauthWithinWindow(now, now)).toBe(true);
  });

  test('token at exactly the window boundary is allowed', () => {
    expect(isReauthWithinWindow(now - REAUTH_WINDOW_SECONDS, now)).toBe(true);
  });

  test('token 1 second past the window is rejected', () => {
    expect(isReauthWithinWindow(now - REAUTH_WINDOW_SECONDS - 1, now)).toBe(false);
  });

  test('stale token (1 hour old) is rejected', () => {
    expect(isReauthWithinWindow(now - 3600, now)).toBe(false);
  });

  test('clock skew (auth_time in the future) is treated as fresh', () => {
    expect(isReauthWithinWindow(now + 30, now)).toBe(true);
  });
});

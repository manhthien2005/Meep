import { describe, it, expect } from 'vitest';
import { isPermanentTokenError } from '../../src/notification/_fcm.js';

describe('isPermanentTokenError', () => {
  it('flags unregistered tokens for deletion', () => {
    expect(isPermanentTokenError('messaging/registration-token-not-registered')).toBe(true);
  });

  it('flags invalid registration tokens for deletion', () => {
    expect(isPermanentTokenError('messaging/invalid-registration-token')).toBe(true);
  });

  it('flags invalid-argument for deletion (issue spec)', () => {
    expect(isPermanentTokenError('messaging/invalid-argument')).toBe(true);
  });

  it('keeps token on transient quota error (NOT permanent)', () => {
    // Quota errors retry the next event; deleting the token would lose it.
    expect(isPermanentTokenError('messaging/quota-exceeded')).toBe(false);
  });

  it('keeps token on internal server error (NOT permanent)', () => {
    expect(isPermanentTokenError('messaging/internal-error')).toBe(false);
  });

  it('keeps token on undefined error code (treat as transient)', () => {
    expect(isPermanentTokenError(undefined)).toBe(false);
  });

  it('keeps token on unknown error code (conservative default)', () => {
    expect(isPermanentTokenError('messaging/some-new-code')).toBe(false);
  });
});

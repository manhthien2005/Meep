import { describe, it, expect } from 'vitest';
import { buildFriendRequestPayload } from '../../src/notification/onFriendRequestCreated.js';
import { isAlreadyExists, readDisplayName } from '../../src/notification/_helpers.js';

describe('buildFriendRequestPayload', () => {
  it('interpolates sender name into title with Vietnamese copy', () => {
    const payload = buildFriendRequestPayload('Khoa', 'req-1', 'sender-uid');
    expect(payload.title).toBe('Khoa muốn kết bạn với bạn');
    expect(payload.body).toBe('Tap để xem và chấp nhận');
  });

  it('FCM data uses snake_case type so deep-link router can route directly', () => {
    const payload = buildFriendRequestPayload('Khoa', 'req-abc', 'uid-1');
    expect(payload.data).toEqual({
      type: 'friend_request',
      requestId: 'req-abc',
      senderId: 'uid-1',
    });
  });

  it('data values are all strings (FCM requirement)', () => {
    const payload = buildFriendRequestPayload('Khoa', 'r', 's');
    for (const v of Object.values(payload.data)) {
      expect(typeof v).toBe('string');
    }
  });
});

describe('readDisplayName', () => {
  it('returns displayName when present', () => {
    expect(readDisplayName({ displayName: 'Thien' })).toBe('Thien');
  });

  it('falls back when user data is null', () => {
    expect(readDisplayName(null)).toBe('Một người dùng');
  });

  it('falls back when user data is undefined', () => {
    expect(readDisplayName(undefined)).toBe('Một người dùng');
  });

  it('falls back when displayName is empty string', () => {
    expect(readDisplayName({ displayName: '' })).toBe('Một người dùng');
  });

  it('falls back when displayName is not a string', () => {
    expect(readDisplayName({ displayName: 123 })).toBe('Một người dùng');
  });

  it('falls back when displayName field is missing', () => {
    expect(readDisplayName({ uid: 'x' })).toBe('Một người dùng');
  });
});

describe('isAlreadyExists', () => {
  it('detects gRPC ALREADY_EXISTS (code 6)', () => {
    expect(isAlreadyExists({ code: 6, message: 'doc exists' })).toBe(true);
  });

  it('rejects other gRPC codes', () => {
    expect(isAlreadyExists({ code: 5 })).toBe(false); // NOT_FOUND
    expect(isAlreadyExists({ code: 7 })).toBe(false); // PERMISSION_DENIED
  });

  it('rejects non-object errors', () => {
    expect(isAlreadyExists('error string')).toBe(false);
    expect(isAlreadyExists(null)).toBe(false);
    expect(isAlreadyExists(undefined)).toBe(false);
  });

  it('rejects objects without code field', () => {
    expect(isAlreadyExists({ message: 'oops' })).toBe(false);
  });
});

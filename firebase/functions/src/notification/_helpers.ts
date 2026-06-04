/**
 * Cross-CF helpers for the notification module. Kept separate from `_fcm.ts`
 * so FCM concerns stay isolated from generic Firestore/user-doc utilities.
 */

/**
 * Pull `displayName` out of a /users/{uid} doc payload defensively — the
 * user might not have set one yet, in which case we fall back to a generic
 * label rather than rendering "undefined muốn kết bạn".
 */
export function readDisplayName(userData: unknown): string {
  if (userData == null || typeof userData !== 'object') return 'Một người dùng';
  const name = (userData as { displayName?: unknown }).displayName;
  if (typeof name === 'string' && name.length > 0) return name;
  return 'Một người dùng';
}

/**
 * Firestore admin SDK throws gRPC errors with `code: 6` (ALREADY_EXISTS)
 * when `.create()` hits an existing doc. We use this to make triggers
 * idempotent against the documented "triggers may fire twice" risk
 * (firebase/functions/CLAUDE.md).
 */
export function isAlreadyExists(e: unknown): boolean {
  return typeof e === 'object' && e !== null && (e as { code?: unknown }).code === 6;
}

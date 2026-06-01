import { describe, it, expect } from 'vitest';
import { z } from 'zod';

// Mirror schemas từ src/space/leaveSpace.ts + kickMember.ts +
// transferOwnership.ts. Test isolated — không cần emulator.

const leaveSpaceSchema = z.object({
  spaceId: z.string().min(1),
});

const kickMemberSchema = z.object({
  spaceId: z.string().min(1),
  targetUid: z.string().min(1),
});

const transferOwnershipSchema = z.object({
  spaceId: z.string().min(1),
  newCreatorUid: z.string().min(1),
});

describe('leaveSpace schema', () => {
  it('accepts valid spaceId', () => {
    const result = leaveSpaceSchema.safeParse({ spaceId: 'abc123' });
    expect(result.success).toBe(true);
  });

  it('rejects empty spaceId', () => {
    const result = leaveSpaceSchema.safeParse({ spaceId: '' });
    expect(result.success).toBe(false);
  });

  it('rejects missing spaceId', () => {
    const result = leaveSpaceSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it('rejects non-string spaceId', () => {
    const result = leaveSpaceSchema.safeParse({ spaceId: 123 });
    expect(result.success).toBe(false);
  });
});

describe('kickMember schema', () => {
  it('accepts valid spaceId + targetUid', () => {
    const result = kickMemberSchema.safeParse({
      spaceId: 's1',
      targetUid: 'user2',
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty spaceId', () => {
    const result = kickMemberSchema.safeParse({
      spaceId: '',
      targetUid: 'user2',
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty targetUid', () => {
    const result = kickMemberSchema.safeParse({
      spaceId: 's1',
      targetUid: '',
    });
    expect(result.success).toBe(false);
  });

  it('rejects missing targetUid', () => {
    const result = kickMemberSchema.safeParse({ spaceId: 's1' });
    expect(result.success).toBe(false);
  });
});

describe('transferOwnership schema', () => {
  it('accepts valid spaceId + newCreatorUid', () => {
    const result = transferOwnershipSchema.safeParse({
      spaceId: 's1',
      newCreatorUid: 'newCreator',
    });
    expect(result.success).toBe(true);
  });

  it('rejects empty spaceId', () => {
    const result = transferOwnershipSchema.safeParse({
      spaceId: '',
      newCreatorUid: 'newCreator',
    });
    expect(result.success).toBe(false);
  });

  it('rejects empty newCreatorUid', () => {
    const result = transferOwnershipSchema.safeParse({
      spaceId: 's1',
      newCreatorUid: '',
    });
    expect(result.success).toBe(false);
  });

  it('rejects non-string newCreatorUid', () => {
    const result = transferOwnershipSchema.safeParse({
      spaceId: 's1',
      newCreatorUid: 123,
    });
    expect(result.success).toBe(false);
  });
});

// TODO(#136/ThienPDM): Integration tests qua emulator cho 3 CFs:
// leaveSpace:
//   - Happy: member rời → /space_members member doc xóa, memberIds/memberCount giảm
//   - Creator leave → throw failed-precondition
//   - Non-member leave → throw permission-denied
//   - Space deleted → throw failed-precondition
//
// kickMember:
//   - Happy: creator kick member → docs xóa + memberIds giảm
//   - Non-creator caller → throw permission-denied
//   - Creator self-kick → throw invalid-argument
//   - Target không phải member → throw not-found
//
// transferOwnership:
//   - Happy: roles update + creatorId update
//   - Non-creator caller → throw permission-denied
//   - newCreator không phải member → throw failed-precondition
//   - Self-transfer → throw invalid-argument

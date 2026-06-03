/**
 * Storage security rules unit tests.
 * Run via: firebase emulators:exec --only storage "npm run test:rules"
 *
 * Covers: avatars/{uid}/ — owner / authed-other / unauthenticated; size cap;
 * MIME validation. Per issue #114 (Profile T9) acceptance criteria.
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';

// ===== Setup =====

let testEnv: RulesTestEnvironment;

const RULES_PATH = resolve(__dirname, '../../storage.rules');

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'meep-storage-test',
    storage: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

// ===== Helpers =====

const uid = (n: string) => `user-${n}`;

function authed(userId: string) {
  return testEnv.authenticatedContext(userId);
}

function unauthed() {
  return testEnv.unauthenticatedContext();
}

/**
 * Tạo Blob giả lập ảnh size [bytes] cho test upload.
 * Storage emulator chấp nhận Blob với contentType + size từ blob.size.
 */
function fakeImage(bytes: number, mimeType: string = 'image/jpeg'): Blob {
  const buffer = new Uint8Array(bytes);
  return new Blob([buffer], { type: mimeType });
}

// ===== /avatars/{uid}/{filename} =====

describe('Storage /avatars/{uid}/', () => {
  describe('write', () => {
    test('owner can upload valid JPEG ≤ 5MB', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertSucceeds(ref.put(fakeImage(1024)));
    });

    test('owner can upload exactly 5MB - 1 byte (under cap)', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertSucceeds(ref.put(fakeImage(5 * 1024 * 1024 - 1)));
    });

    test('owner cannot upload exactly 5MB (cap is strict <)', async () => {
      // Rule: request.resource.size < 5 * 1024 * 1024 — boundary excluded.
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertFails(ref.put(fakeImage(5 * 1024 * 1024)));
    });

    test('owner cannot upload > 5MB', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertFails(ref.put(fakeImage(5 * 1024 * 1024 + 1)));
    });

    test('owner cannot upload non-image (text/plain)', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.txt`);
      await assertFails(ref.put(fakeImage(1024, 'text/plain')));
    });

    test('owner cannot upload non-image (application/pdf)', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.pdf`);
      await assertFails(ref.put(fakeImage(1024, 'application/pdf')));
    });

    test('owner can upload PNG (image/png matches image/.*)', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.png`);
      await assertSucceeds(ref.put(fakeImage(1024, 'image/png')));
    });

    test('stranger cannot upload to another user prefix', async () => {
      const alice = uid('alice');
      const bob = uid('bob');
      const ref = authed(bob).storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertFails(ref.put(fakeImage(1024)));
    });

    test('unauthenticated cannot upload', async () => {
      const alice = uid('alice');
      const ref = unauthed().storage().ref(`avatars/${alice}/avatar.jpg`);
      await assertFails(ref.put(fakeImage(1024)));
    });
  });

  describe('read', () => {
    test('owner can read own avatar', async () => {
      const alice = uid('alice');
      const ref = authed(alice).storage().ref(`avatars/${alice}/avatar.jpg`);
      await ref.put(fakeImage(1024));

      await assertSucceeds(ref.getDownloadURL());
    });

    test('other authed user can read (friends need to see avatars)', async () => {
      const alice = uid('alice');
      const bob = uid('bob');
      // alice uploads
      await authed(alice)
        .storage()
        .ref(`avatars/${alice}/avatar.jpg`)
        .put(fakeImage(1024));

      // bob reads
      await assertSucceeds(
        authed(bob).storage().ref(`avatars/${alice}/avatar.jpg`).getDownloadURL(),
      );
    });

    test('unauthenticated cannot read', async () => {
      const alice = uid('alice');
      await authed(alice)
        .storage()
        .ref(`avatars/${alice}/avatar.jpg`)
        .put(fakeImage(1024));

      await assertFails(
        unauthed().storage().ref(`avatars/${alice}/avatar.jpg`).getDownloadURL(),
      );
    });
  });
});

// ===== /diary/{uid}/{allPaths=**} =====

describe('Storage /diary/{uid}/', () => {
  describe('write', () => {
    test('owner can upload valid JPEG ≤ 10MB', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertSucceeds(ref.put(fakeImage(1024)));
    });

    test('owner can upload exactly 10MB - 1 byte (under cap)', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertSucceeds(ref.put(fakeImage(10 * 1024 * 1024 - 1)));
    });

    test('owner cannot upload exactly 10MB (cap strict <)', async () => {
      // Rule: request.resource.size < 10 * 1024 * 1024 — boundary excluded.
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertFails(ref.put(fakeImage(10 * 1024 * 1024)));
    });

    test('owner cannot upload > 10MB', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertFails(ref.put(fakeImage(10 * 1024 * 1024 + 1)));
    });

    test('owner cannot upload non-image (text/plain)', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/notes.txt`);
      await assertFails(ref.put(fakeImage(1024, 'text/plain')));
    });

    test('owner cannot upload non-image (application/pdf)', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/doc.pdf`);
      await assertFails(ref.put(fakeImage(1024, 'application/pdf')));
    });

    test('owner can upload PNG (image/png matches image/.*)', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/img_1.png`);
      await assertSucceeds(ref.put(fakeImage(1024, 'image/png')));
    });

    test('owner can upload inline image into nested path', async () => {
      // Pattern `{allPaths=**}` allows deeper paths than `{filename}`. Diary
      // dùng `diary/{uid}/{entryId}/img_N.jpg` (3 segments sau uid).
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/img_2.jpg`);
      await assertSucceeds(ref.put(fakeImage(1024)));
    });

    test('stranger cannot upload to another user prefix', async () => {
      const alice = uid('alice');
      const bob = uid('bob');
      const ref = authed(bob)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertFails(ref.put(fakeImage(1024)));
    });

    test('stranger cannot upload to deep nested path of another user', async () => {
      // Rule `{allPaths=**}` cho phép path sâu — defense check để pattern match
      // không bypass uid enforcement.
      const alice = uid('alice');
      const bob = uid('bob');
      const ref = authed(bob)
        .storage()
        .ref(`diary/${alice}/entry-1/sub/folder/file.jpg`);
      await assertFails(ref.put(fakeImage(1024)));
    });

    test('unauthenticated cannot upload', async () => {
      const alice = uid('alice');
      const ref = unauthed()
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await assertFails(ref.put(fakeImage(1024)));
    });
  });

  describe('read', () => {
    test('owner can read own diary image', async () => {
      const alice = uid('alice');
      const ref = authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`);
      await ref.put(fakeImage(1024));

      await assertSucceeds(ref.getDownloadURL());
    });

    test('other authed user can read (Firestore rule controls visibility)', async () => {
      // Storage rule cho phép mọi authed user read; Firestore rule
      // `/diary/{id}` mới enforce friend + privacy. URL đã được lưu
      // trong doc nên client KHÔNG list được prefix.
      const alice = uid('alice');
      const bob = uid('bob');
      await authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`)
        .put(fakeImage(1024));

      await assertSucceeds(
        authed(bob)
          .storage()
          .ref(`diary/${alice}/entry-1/cover.jpg`)
          .getDownloadURL(),
      );
    });

    test('unauthenticated cannot read', async () => {
      const alice = uid('alice');
      await authed(alice)
        .storage()
        .ref(`diary/${alice}/entry-1/cover.jpg`)
        .put(fakeImage(1024));

      await assertFails(
        unauthed()
          .storage()
          .ref(`diary/${alice}/entry-1/cover.jpg`)
          .getDownloadURL(),
      );
    });
  });
});

// ===== Default deny — non-avatar paths =====

describe('Storage default deny', () => {
  test('owner cannot write to /random/{path}', async () => {
    const alice = uid('alice');
    const ref = authed(alice).storage().ref(`random/${alice}/file.jpg`);
    await assertFails(ref.put(fakeImage(1024)));
  });
});

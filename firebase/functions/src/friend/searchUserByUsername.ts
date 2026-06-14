import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import {
  buildPublicProfileData,
  publicProfileSourceSchema,
} from '../user/publicProfile.js';

const searchUserByUsernameSchema = z
  .object({
    username: z.string().min(1).max(64),
  })
  .strict();

export interface SearchUserProfile {
  uid: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  bio: string | null;
  isSearchable: boolean;
  updatedAtMillis: number;
}

export function normalizeSearchUsername(raw: string): string | null {
  const username = raw.toLowerCase().trim();
  return /^[a-z0-9_]{3,20}$/.test(username) ? username : null;
}

function timestampToMillis(value: unknown): number {
  if (
    typeof value === 'object' &&
    value !== null &&
    'toMillis' in value &&
    typeof (value as { toMillis?: unknown }).toMillis === 'function'
  ) {
    return (value as { toMillis: () => number }).toMillis();
  }
  return Date.now();
}

export function buildSearchUserProfile(
  uid: string,
  data: z.infer<typeof publicProfileSourceSchema>,
  updatedAt: unknown,
): SearchUserProfile | null {
  if (data.isSearchable === false) {
    return null;
  }

  return {
    uid,
    displayName: data.displayName,
    username: data.username,
    avatarUrl: data.avatarUrl ?? null,
    bio: data.bio ?? null,
    isSearchable: data.isSearchable ?? true,
    updatedAtMillis: timestampToMillis(updatedAt),
  };
}

async function resolveUserDocByExactUsername(
  db: FirebaseFirestore.Firestore,
  username: string,
): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  const usernameDoc = await db.collection('usernames').doc(username).get();
  if (usernameDoc.exists) {
    const usernameData = usernameDoc.data() as
      | Record<string, unknown>
      | undefined;
    const uid = usernameData?.uid;
    if (typeof uid === 'string' && uid.length > 0) {
      const userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) return userDoc;
    } else {
      logger.warn('friendSearch: invalid username doc');
    }
  }

  // Exact fallback only: repairs accounts created before /usernames or
  // public/profile were populated. This is NOT prefix/fuzzy search.
  const usersSnap = await db
    .collection('users')
    .where('username', '==', username)
    .limit(1)
    .get();

  return usersSnap.empty ? null : usersSnap.docs[0] ?? null;
}

/**
 * Exact username lookup for friend discovery.
 *
 * Uses /usernames as the source of truth because it is written synchronously
 * during signup; /users/{uid}/public/profile is still repaired opportunistically
 * so existing collection-group reads recover after one successful search.
 */
export const searchUserByUsername = onCall(
  { region: 'asia-southeast1' },
  async (request): Promise<{ profile: SearchUserProfile | null }> => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }

    const parsed = searchUserByUsernameSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const username = normalizeSearchUsername(parsed.data.username);
    if (username == null) {
      return { profile: null };
    }

    const db = getFirestore();
    const userDoc = await resolveUserDocByExactUsername(db, username);
    if (userDoc == null) {
      return { profile: null };
    }
    const uid = userDoc.id;

    const userData = userDoc.data();
    if (userData == null) {
      return { profile: null };
    }

    const publicFields = publicProfileSourceSchema.safeParse(userData);
    if (!publicFields.success || publicFields.data.username !== username) {
      logger.warn(
        {
          uid,
          fields: publicFields.success
            ? ['username']
            : publicFields.error.issues.map((issue) => issue.path.join('.')),
        },
        'friendSearch: user doc cannot be projected',
      );
      return { profile: null };
    }

    const projection = buildPublicProfileData(uid, publicFields.data);
    await Promise.all([
      db.collection('usernames').doc(username).set({ uid }, { merge: false }),
      userDoc.ref.collection('public').doc('profile').set(projection, {
        merge: false,
      }),
    ]);

    return {
      profile: buildSearchUserProfile(
        uid,
        publicFields.data,
        userData.updatedAt ?? userData.createdAt,
      ),
    };
  },
);

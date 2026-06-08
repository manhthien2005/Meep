import { FieldPath, FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

export const publicProfileSourceSchema = z
  .object({
    displayName: z.string().min(1).max(50),
    username: z
      .string()
      .min(3)
      .max(20)
      .regex(/^[a-z0-9_]+$/),
    avatarUrl: z.string().max(500).nullable().optional(),
    bio: z.string().max(300).nullable().optional(),
    isSearchable: z.boolean().optional(),
  })
  .passthrough();

export const migratePublicProfilesSchema = z.object({}).strict();

type PublicProfileSource = z.infer<typeof publicProfileSourceSchema>;

export interface PublicProfileWrite {
  uid: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  bio: string | null;
  isSearchable: boolean;
  updatedAt: unknown;
}

export function buildPublicProfileData(
  uid: string,
  data: PublicProfileSource,
  updatedAt: unknown = FieldValue.serverTimestamp(),
): PublicProfileWrite {
  return {
    uid,
    displayName: data.displayName,
    username: data.username,
    avatarUrl: data.avatarUrl ?? null,
    bio: data.bio ?? null,
    isSearchable: data.isSearchable ?? true,
    updatedAt,
  };
}

function publicProfileRef(uid: string) {
  return getFirestore().doc(`users/${uid}/public/profile`);
}

async function writePublicProfile(
  uid: string,
  data: Record<string, unknown>,
): Promise<boolean> {
  const parsed = publicProfileSourceSchema.safeParse(data);
  if (!parsed.success) {
    logger.warn(
      {
        uid,
        fields: parsed.error.issues.map((issue) => issue.path.join('.')),
      },
      'publicProfile: user doc has invalid public fields',
    );
    return false;
  }

  await publicProfileRef(uid).set(buildPublicProfileData(uid, parsed.data), {
    merge: false,
  });
  return true;
}

export const onUserProfileChanged = onDocumentWritten(
  {
    document: 'users/{uid}',
    region: 'asia-southeast1',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;

    if (after?.exists !== true) {
      await publicProfileRef(uid).delete();
      logger.info({ uid }, 'publicProfile: deleted');
      return;
    }

    const data = after.data();
    if (data == null) {
      logger.warn({ uid }, 'publicProfile: user doc missing data');
      return;
    }
    await writePublicProfile(uid, data);
  },
);

export const migratePublicProfiles = onCall(
  {
    region: 'asia-southeast1',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Login required');
    }
    if (request.auth.token.admin !== true) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const parsed = migratePublicProfilesSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError('invalid-argument', parsed.error.message);
    }

    const db = getFirestore();
    let migrated = 0;
    let skipped = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    while (true) {
      let query: FirebaseFirestore.Query = db
        .collection('users')
        .orderBy(FieldPath.documentId())
        .limit(400);

      if (lastDoc !== undefined) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();
      let writes = 0;

      for (const doc of snap.docs) {
        const parsedDoc = publicProfileSourceSchema.safeParse(doc.data());
        if (!parsedDoc.success) {
          skipped += 1;
          logger.warn(
            {
              uid: doc.id,
              fields: parsedDoc.error.issues.map((issue) =>
                issue.path.join('.'),
              ),
            },
            'publicProfile: skipped invalid user doc during migration',
          );
          continue;
        }

        batch.set(
          doc.ref.collection('public').doc('profile'),
          buildPublicProfileData(doc.id, parsedDoc.data),
          { merge: false },
        );
        writes += 1;
      }

      if (writes > 0) {
        await batch.commit();
      }
      migrated += writes;

      if (snap.size < 400) break;
      const nextLastDoc = snap.docs.at(-1);
      if (!nextLastDoc) break;
      lastDoc = nextLastDoc;
    }

    logger.info({ migrated, skipped }, 'publicProfile: migration complete');
    return { success: true, migrated, skipped };
  },
);

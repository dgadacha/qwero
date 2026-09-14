import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';

import type { DailyQuestSet, QuestAssignment, QuestDifficulty, UserDoc } from '../types';

/**
 * Attribution des quêtes du jour à un joueur (§74).
 *
 * Le client ne choisit pas ses quêtes : il lit ses assignations. C'est ce qui
 * garantit qu'un groupe d'amis a bien le même set, et que l'expiration est
 * décidée côté serveur.
 */

const DIFFICULTIES: { key: keyof DailyQuestSet; difficulty: QuestDifficulty }[] = [
  { key: 'easyQuestId', difficulty: 'easy' },
  { key: 'mediumQuestId', difficulty: 'medium' },
  { key: 'hardQuestId', difficulty: 'hard' },
  { key: 'worldQuestId', difficulty: 'world' },
];

export async function assignSetToUser(
  db: Firestore,
  userId: string,
  set: DailyQuestSet,
): Promise<void> {
  const assignments = db.collection('users').doc(userId).collection('assignments');
  const batch = db.batch();

  for (const { key, difficulty } of DIFFICULTIES) {
    const questId = set[key] as string;
    const assignment: QuestAssignment = {
      questId,
      dailySetId: set.id,
      difficulty,
      status: 'available',
      assignedAt: Timestamp.now(),
      expiresAt: set.endsAt,
    };
    // L'identifiant est celui de la quête : une quête assignée deux fois ne
    // crée pas deux lignes.
    batch.set(assignments.doc(questId), assignment, { merge: true });
  }

  batch.update(db.collection('users').doc(userId), {
    currentSetId: set.id,
    lastAssignedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
}

/** Assigne le set du jour à toute une cohorte, par lots. */
export async function assignSetToCohort(
  db: Firestore,
  set: DailyQuestSet,
): Promise<number> {
  let assigned = 0;
  let lastId: string | null = null;

  for (;;) {
    let query = db
      .collection('users')
      .where('cohortId', '==', set.cohortId)
      .orderBy('__name__')
      .limit(200);
    if (lastId) query = query.startAfter(lastId);

    const page = await query.get();
    if (page.empty) break;

    await Promise.all(page.docs.map((doc) => assignSetToUser(db, doc.id, set)));
    assigned += page.size;
    lastId = page.docs[page.docs.length - 1]?.id ?? null;
    if (page.size < 200) break;
  }

  return assigned;
}

/** Les cohortes qui comptent au moins un joueur. */
export async function activeCohorts(db: Firestore): Promise<Map<string, UserDoc['timezone']>> {
  const cohorts = new Map<string, string>();
  const snapshot = await db.collection('users').select('cohortId', 'timezone').get();

  for (const doc of snapshot.docs) {
    const data = doc.data() as Pick<UserDoc, 'cohortId' | 'timezone'>;
    if (data.cohortId && !cohorts.has(data.cohortId)) {
      cohorts.set(data.cohortId, data.timezone);
    }
  }
  return cohorts;
}

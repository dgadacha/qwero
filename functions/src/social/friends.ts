import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { COHORT_BUCKETS, cohortIdFor, timezoneGroupOf } from '../quests/daily';
import type { UserDoc } from '../types';

/**
 * Relations d'amitié (§163).
 *
 * Relation mutuelle, pas d'abonnement. Chaque amitié est écrite dans les deux
 * sens pour que la lecture reste un simple `exists()` côté règles.
 */

export function friendshipId(a: string, b: string): string {
  return `${a}_${b}`;
}

export async function areFriends(db: Firestore, a: string, b: string): Promise<boolean> {
  const snapshot = await db.collection('friendships').doc(friendshipId(a, b)).get();
  return snapshot.exists;
}

export async function createFriendship(db: Firestore, a: string, b: string): Promise<void> {
  const batch = db.batch();
  const now = FieldValue.serverTimestamp();

  batch.set(db.collection('friendships').doc(friendshipId(a, b)), {
    userId: a,
    friendId: b,
    createdAt: now,
  });
  batch.set(db.collection('friendships').doc(friendshipId(b, a)), {
    userId: b,
    friendId: a,
    createdAt: now,
  });

  await batch.commit();
  await alignCohorts(db, a, b);
}

/**
 * Cohérence de cohorte (§135).
 *
 * Deux amis doivent recevoir le même set. Quand ils sont dans des cohortes
 * différentes du même groupe de fuseaux, le plus récemment inscrit rejoint
 * l'autre. On ne déplace jamais quelqu'un hors de son groupe de fuseaux : ce
 * serait lui donner une journée décalée.
 */
async function alignCohorts(db: Firestore, a: string, b: string): Promise<void> {
  const [snapA, snapB] = await Promise.all([
    db.collection('users').doc(a).get(),
    db.collection('users').doc(b).get(),
  ]);
  if (!snapA.exists || !snapB.exists) return;

  const userA = snapA.data() as UserDoc;
  const userB = snapB.data() as UserDoc;

  if (userA.cohortId === userB.cohortId) return;
  if (timezoneGroupOf(userA.timezone) !== timezoneGroupOf(userB.timezone)) return;

  const aCreated = userA.createdAt?.toMillis?.() ?? 0;
  const bCreated = userB.createdAt?.toMillis?.() ?? 0;
  const [mover, target] = aCreated >= bCreated ? [a, userB.cohortId] : [b, userA.cohortId];

  await db.collection('users').doc(mover).update({ cohortId: target });
}

/** Cohorte initiale d'un nouveau joueur. */
export function initialCohort(userId: string, timezone: string): string {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    hash = (hash * 31 + userId.charCodeAt(i)) % 1_000_000;
  }
  return cohortIdFor(timezone, hash % COHORT_BUCKETS);
}

/** Identifiants des amis d'un joueur. */
export async function friendIds(db: Firestore, userId: string): Promise<string[]> {
  const snapshot = await db
    .collection('friendships')
    .where('userId', '==', userId)
    .limit(500)
    .get();
  return snapshot.docs.map((doc) => doc.data().friendId as string);
}

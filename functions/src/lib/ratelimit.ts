import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { errors } from './errors';

/**
 * Limitation de débit (§155).
 *
 * Un compteur par utilisateur, action et fenêtre. La transaction sert de verrou :
 * deux appels simultanés ne peuvent pas passer sous la limite tous les deux.
 */
export async function consumeQuota(
  db: Firestore,
  userId: string,
  action: string,
  limit: number,
  windowKey: string,
  message: string,
): Promise<void> {
  const ref = db
    .collection('users')
    .doc(userId)
    .collection('quotas')
    .doc(`${action}_${windowKey}`);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const used = (snapshot.data()?.count as number | undefined) ?? 0;
    if (used >= limit) {
      throw errors.exhausted(message);
    }
    tx.set(
      ref,
      { count: used + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

/** Clé de fenêtre journalière, dans le fuseau du joueur. */
export function dayWindow(date: Date, timezone: string): string {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(date);
  } catch {
    return date.toISOString().slice(0, 10);
  }
}

export function hourWindow(date: Date): string {
  return date.toISOString().slice(0, 13);
}

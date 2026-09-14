import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';

import { xpForLevel } from '../config';
import type { UserDoc, XpEvent } from '../types';

/**
 * XP et niveaux (§50, §51).
 *
 * Le client ne demande jamais « donne-moi 400 XP » : il demande à terminer une
 * quête, et le serveur décide. Chaque attribution laisse un événement dans le
 * journal, ce qui rend le solde reconstituable et les corrections traçables.
 */

export interface AwardInput {
  userId: string;
  amount: number;
  reason: XpEvent['reason'];
  questId: string | null;
  completionId: string | null;
}

export interface AwardOutput {
  xp: number;
  level: number;
  leveledUp: boolean;
}

/** Applique un gain d'XP dans une transaction, journal compris. */
export function awardXp(
  db: Firestore,
  tx: Transaction,
  user: UserDoc,
  input: AwardInput,
): AwardOutput {
  const levelBefore = user.level;
  let xp = user.xp + input.amount;
  let level = user.level;

  while (xp >= xpForLevel(level)) {
    xp -= xpForLevel(level);
    level += 1;
  }

  const userRef = db.collection('users').doc(input.userId);
  tx.update(userRef, { xp, level });

  const eventRef = userRef.collection('xpEvents').doc();
  tx.set(eventRef, {
    amount: input.amount,
    reason: input.reason,
    questId: input.questId,
    completionId: input.completionId,
    levelBefore,
    levelAfter: level,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { xp, level, leveledUp: level > levelBefore };
}

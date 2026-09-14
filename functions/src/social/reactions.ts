import { FieldValue, type Firestore } from 'firebase-admin/firestore';

/**
 * Réactions et commentaires (§25).
 *
 * Les compteurs sont dénormalisés sur la participation : le feed doit pouvoir
 * trier par réactions sans lire chaque sous-collection.
 */

export const ALLOWED_EMOJIS = ['🔥', '😂', '❤️', '🤯', '👏'] as const;
export type ReactionEmoji = (typeof ALLOWED_EMOJIS)[number];

export function reactionId(userId: string, emoji: string): string {
  return `${userId}_${Buffer.from(emoji).toString('hex')}`;
}

export async function syncReactionCount(
  db: Firestore,
  completionId: string,
  delta: number,
): Promise<void> {
  await db
    .collection('questCompletions')
    .doc(completionId)
    .update({ reactionCount: FieldValue.increment(delta) });
}

export async function syncCommentCount(
  db: Firestore,
  completionId: string,
  delta: number,
): Promise<void> {
  await db
    .collection('questCompletions')
    .doc(completionId)
    .update({ commentCount: FieldValue.increment(delta) });
}

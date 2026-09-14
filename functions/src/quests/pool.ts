import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { generateQuests, normalizeTitle, toTemplate } from '../claude/generate';
import type { QuestCategory, QuestDifficulty, QuestTemplate } from '../types';

/**
 * Alimentation du pool de quêtes (§13).
 *
 *   Claude → validation du schéma → modération → doublons → faisabilité →
 *   compatibilité QuestCheck → pool approuvé → planificateur
 *
 * Les quêtes sont produites plusieurs jours à l'avance : au moment où un set du
 * jour se compose, il n'y a plus aucun appel modèle à attendre (§77).
 */

const TARGET_POOL: Record<QuestDifficulty, number> = {
  easy: 50,
  medium: 30,
  hard: 20,
  world: 10,
};

const CATEGORY_MIX: QuestCategory[] = [
  'observation',
  'photography',
  'creative',
  'nature',
  'exploration',
  'food',
  'social',
  'funny',
];

export interface RefillReport {
  difficulty: QuestDifficulty;
  generated: number;
  approved: number;
  rejectedUnsafe: number;
  rejectedDuplicate: number;
  rejectedUnverifiable: number;
}

/** Complète le pool d'une difficulté jusqu'à sa cible. */
export async function refillPool(
  db: Firestore,
  difficulty: Exclude<QuestDifficulty, 'world'>,
  season: string,
  locale: string,
): Promise<RefillReport> {
  const report: RefillReport = {
    difficulty,
    generated: 0,
    approved: 0,
    rejectedUnsafe: 0,
    rejectedDuplicate: 0,
    rejectedUnverifiable: 0,
  };

  const available = await db
    .collection('questTemplates')
    .where('status', '==', 'approved')
    .where('difficulty', '==', difficulty)
    .count()
    .get();

  const missing = TARGET_POOL[difficulty] - available.data().count;
  if (missing <= 0) return report;

  const recent = await db
    .collection('questTemplates')
    .where('difficulty', '==', difficulty)
    .orderBy('createdAt', 'desc')
    .limit(60)
    .get();

  const known = new Set(recent.docs.map((d) => (d.data() as QuestTemplate).normalizedTitle));
  const avoidTitles = recent.docs.slice(0, 30).map((d) => (d.data() as QuestTemplate).title);

  const quests = await generateQuests({
    difficulty,
    count: Math.min(missing, 15),
    avoidTitles,
    season,
    categoryMix: CATEGORY_MIX,
    locale,
  });
  report.generated = quests.length;

  const batch = db.batch();

  for (const quest of quests) {
    const template = toTemplate(quest, 'ai');

    // Modération : la politique de sécurité est dans le prompt, mais on ne fait
    // pas confiance à un seul rempart (§42).
    if (template.status === 'rejected' || quest.riskLevel !== 'low') {
      report.rejectedUnsafe += 1;
      continue;
    }

    // Doublons (§79).
    if (known.has(template.normalizedTitle)) {
      report.rejectedDuplicate += 1;
      continue;
    }

    // Compatibilité QuestCheck : sans critère vérifiable autre que la technique,
    // la quête ne peut pas être jugée.
    const verifiable = template.requirements.filter((r) => r.type !== 'technical');
    if (verifiable.length === 0) {
      report.rejectedUnverifiable += 1;
      continue;
    }

    known.add(template.normalizedTitle);
    const ref = db.collection('questTemplates').doc();
    batch.set(ref, {
      ...template,
      status: 'approved',
      lastUsedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });
    report.approved += 1;
  }

  await batch.commit();
  return report;
}

/** Nombre de quêtes approuvées par difficulté, pour la supervision. */
export async function poolHealth(db: Firestore): Promise<Record<string, number>> {
  const entries = await Promise.all(
    (Object.keys(TARGET_POOL) as QuestDifficulty[]).map(async (difficulty) => {
      const snapshot = await db
        .collection('questTemplates')
        .where('status', '==', 'approved')
        .where('difficulty', '==', difficulty)
        .count()
        .get();
      return [difficulty, snapshot.data().count] as const;
    }),
  );
  return Object.fromEntries(entries);
}

export { normalizeTitle };

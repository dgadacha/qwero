import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';

import type { DailyQuestSet, QuestDifficulty, QuestTemplate } from '../types';

/**
 * Composition des sets du jour (§11, §77).
 *
 * Une cohorte reçoit exactement le même set : c'est ce qui rend la comparaison
 * entre amis possible (§18). La personnalisation reste secondaire (§134).
 */

/** Groupes de fuseaux (§19). Une journée ne doit pas déborder sur la suivante. */
export const TIMEZONE_GROUPS = {
  pacific: { offsetHours: 11, label: 'Pacific' },
  asia: { offsetHours: 8, label: 'Asia' },
  europe: { offsetHours: 1, label: 'Europe' },
  americas: { offsetHours: -5, label: 'Americas' },
} as const;

export type TimezoneGroup = keyof typeof TIMEZONE_GROUPS;

export function timezoneGroupOf(timezone: string): TimezoneGroup {
  if (timezone.startsWith('Pacific/') || timezone.startsWith('Australia/')) return 'pacific';
  if (timezone.startsWith('Asia/')) return 'asia';
  if (timezone.startsWith('America/')) return 'americas';
  return 'europe';
}

/**
 * Cohorte d'un joueur (§135, §136).
 *
 * L'identifiant n'est jamais exposé dans l'interface. Il place ensemble les
 * gens qui jouent ensemble : même groupe de fuseaux d'abord, puis un bucket
 * stable dérivé de l'identifiant. Quand deux amis se retrouvent dans des
 * buckets différents, la fonction d'ajout d'ami les rapproche.
 */
export function cohortIdFor(timezone: string, bucket: number): string {
  return `${timezoneGroupOf(timezone)}-${bucket}`;
}

export const COHORT_BUCKETS = 8;

export function defaultBucket(userId: string): number {
  let hash = 0;
  for (const code of userId) {
    hash = (hash * 31 + code.charCodeAt(0)) % 1_000_000;
  }
  return hash % COHORT_BUCKETS;
}

/** Choisit une quête peu utilisée récemment (§80). */
async function pickQuest(
  db: Firestore,
  difficulty: QuestDifficulty,
  used: Set<string>,
): Promise<QuestTemplate | null> {
  const snapshot = await db
    .collection('questTemplates')
    .where('status', '==', 'approved')
    .where('difficulty', '==', difficulty)
    .orderBy('lastUsedAt', 'asc')
    .limit(12)
    .get();

  const candidates = snapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }) as QuestTemplate)
    .filter((quest) => !used.has(quest.id));

  if (candidates.length === 0) return null;

  // Un peu d'aléa parmi les plus anciennes : deux cohortes voisines ne reçoivent
  // pas mécaniquement la même quête.
  const index = Math.floor(Math.random() * Math.min(candidates.length, 5));
  return candidates[index] ?? candidates[0] ?? null;
}

export interface BuildSetInput {
  db: Firestore;
  cohortId: string;
  date: string;
  group: TimezoneGroup;
  worldQuestId: string;
}

/** Compose et publie le set d'une cohorte pour une date donnée. */
export async function buildDailySet({
  db,
  cohortId,
  date,
  group,
  worldQuestId,
}: BuildSetInput): Promise<DailyQuestSet | null> {
  const setId = `${date}-${cohortId}`;
  const ref = db.collection('dailyQuestSets').doc(setId);

  const existing = await ref.get();
  if (existing.exists) return { id: setId, ...existing.data() } as DailyQuestSet;

  const used = new Set<string>([worldQuestId]);
  const easy = await pickQuest(db, 'easy', used);
  if (easy) used.add(easy.id);
  const medium = await pickQuest(db, 'medium', used);
  if (medium) used.add(medium.id);
  const hard = await pickQuest(db, 'hard', used);

  if (!easy || !medium || !hard) {
    console.error('Pool insuffisant pour composer un set', { cohortId, date });
    return null;
  }

  const offset = TIMEZONE_GROUPS[group].offsetHours;
  const startsAt = new Date(`${date}T00:00:00.000Z`);
  startsAt.setUTCHours(startsAt.getUTCHours() - offset);
  const endsAt = new Date(startsAt.getTime() + 24 * 3600 * 1000);

  const set: Omit<DailyQuestSet, 'id'> = {
    date,
    cohortId,
    timezoneGroup: group,
    easyQuestId: easy.id,
    mediumQuestId: medium.id,
    hardQuestId: hard.id,
    worldQuestId,
    status: 'published',
    startsAt: Timestamp.fromDate(startsAt),
    endsAt: Timestamp.fromDate(endsAt),
  };

  await ref.set(set);

  // Marquer les quêtes comme servies évite de les reprendre le lendemain.
  const batch = db.batch();
  for (const quest of [easy, medium, hard]) {
    batch.update(db.collection('questTemplates').doc(quest.id), {
      lastUsedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  return { id: setId, ...set };
}

/** La World Quest du jour, commune à tout le monde (§17). */
export async function ensureWorldQuest(db: Firestore, date: string): Promise<string | null> {
  const ref = db.collection('worldQuests').doc(date);
  const existing = await ref.get();
  if (existing.exists) return existing.data()?.questId as string;

  const snapshot = await db
    .collection('questTemplates')
    .where('status', '==', 'approved')
    .where('difficulty', '==', 'world')
    .orderBy('lastUsedAt', 'asc')
    .limit(1)
    .get();

  const doc = snapshot.docs[0];
  if (!doc) return null;

  const counter = await db.collection('worldQuests').count().get();
  await ref.set({
    questId: doc.id,
    number: counter.data().count + 1,
    date,
    createdAt: FieldValue.serverTimestamp(),
  });
  await doc.ref.update({ lastUsedAt: FieldValue.serverTimestamp() });

  return doc.id;
}

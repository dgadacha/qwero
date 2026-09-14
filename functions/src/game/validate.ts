import { getStorage } from 'firebase-admin/storage';
import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';

import { analyseProof } from '../claude/questcheck';
import { XP_REWARDS } from '../config';
import { DUPLICATE_THRESHOLD, hammingDistance, prepareProof } from '../lib/image';
import type {
  CompletionDoc,
  QuestCheckItem,
  QuestCheckResult,
  QuestTemplate,
  UserDoc,
} from '../types';
import {
  buildResult,
  deterministicPassedChecks,
  rejectedResult,
  runDeterministicChecks,
} from './score';
import { awardXp } from './xp';
import { updateStreak } from './streak';

/**
 * Pipeline de validation (§33).
 *
 *   preuve déposée → contrôles déterministes → analyse Claude →
 *   Score Engine → attribution (XP, streak) → état publié au client
 *
 * L'ensemble est exécuté par le serveur. Le client observe seulement le
 * document de participation changer d'état (§83).
 */

export interface ValidateInput {
  db: Firestore;
  completionId: string;
  completion: CompletionDoc;
}

export async function validateCompletion({
  db,
  completionId,
  completion,
}: ValidateInput): Promise<void> {
  const completionRef = db.collection('questCompletions').doc(completionId);

  const [questSnap, userSnap] = await Promise.all([
    db.collection('questTemplates').doc(completion.questId).get(),
    db.collection('users').doc(completion.userId).get(),
  ]);

  if (!questSnap.exists || !userSnap.exists) {
    await completionRef.update({
      status: 'rejected',
      reason: 'Quête ou joueur introuvable.',
      validatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  const quest = { id: questSnap.id, ...questSnap.data() } as QuestTemplate;
  const user = userSnap.data() as UserDoc;
  const now = new Date();

  // --- Contrôles déterministes -------------------------------------------

  const [alreadyCompleted, previousProofs] = await Promise.all([
    hasValidatedCompletion(db, completion.userId, completion.questId, completionId),
    recentProofHashes(db, completion.userId, completionId),
  ]);

  const assignment = completion.dailySetId
    ? await db
        .collection('users')
        .doc(completion.userId)
        .collection('assignments')
        .doc(completion.questId)
        .get()
    : null;

  let proof;
  try {
    proof = await downloadAndPrepare(completion.proofPath);
  } catch (error) {
    console.error('Preuve illisible', { completionId, error: String(error) });
    await completionRef.update({
      status: 'rejected',
      reason: "La photo n'a pas pu être lue.",
      validatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  const duplicate = previousProofs.find(
    (candidate) => hammingDistance(candidate.hash, proof.perceptualHash) <= DUPLICATE_THRESHOLD,
  );

  const deterministic = runDeterministicChecks({
    quest,
    completion,
    alreadyCompleted,
    duplicateOfCompletionId: duplicate?.id ?? null,
    expiresAt: assignment?.exists
      ? (assignment.data()?.expiresAt as Timestamp | undefined)?.toDate() ?? null
      : null,
    now,
  });

  if (deterministic.rejection) {
    await publish(db, completionRef, completion, rejectedResult(deterministic.rejection), {
      proofHash: proof.perceptualHash,
    });
    return;
  }

  // --- Analyse multimodale ------------------------------------------------

  let result: QuestCheckResult;
  try {
    const analysis = await analyseProof({
      questTitle: quest.title,
      questDescription: quest.description,
      requirements: quest.requirements,
      imageBase64: proof.base64,
      mediaType: proof.mediaType,
      locale: user.locale || 'fr',
    });

    const checks: QuestCheckItem[] = [...deterministicPassedChecks(), ...analysis.checks];

    if (analysis.suspicious) {
      checks.push({
        id: 'authentic',
        label: 'Photo authentique',
        passed: false,
        confidence: 1,
      });
    }

    result = buildResult(checks, analysis.summary, 'model');
  } catch (error) {
    // Claude indisponible : la participation est conservée et reprise plus
    // tard, jamais perdue (§160).
    console.error('QuestCheck indisponible', { completionId, error: String(error) });
    await completionRef.update({
      status: 'delayed',
      reason: 'Vérification différée. Ta quête est bien enregistrée.',
      proofHash: proof.perceptualHash,
    });
    return;
  }

  await publish(db, completionRef, completion, result, { proofHash: proof.perceptualHash });
}

/** Écrit le verdict et, s'il est favorable, attribue XP et streak. */
async function publish(
  db: Firestore,
  completionRef: FirebaseFirestore.DocumentReference,
  completion: CompletionDoc,
  result: QuestCheckResult,
  extra: { proofHash: string },
): Promise<void> {
  const status =
    result.verdict === 'pass' ? 'validated' : result.verdict === 'uncertain' ? 'uncertain' : 'rejected';

  if (status !== 'validated') {
    await completionRef.update({
      status,
      validationScore: result.score,
      checks: result.checks,
      reason: result.reason,
      proofHash: extra.proofHash,
      validatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  const questRef = db.collection('questTemplates').doc(completion.questId);
  const userRef = db.collection('users').doc(completion.userId);

  await db.runTransaction(async (tx) => {
    const [userSnap, questSnap, currentSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(questRef),
      tx.get(completionRef),
    ]);

    // Une participation n'est créditée qu'une fois, même si le déclencheur
    // rejoue (Cloud Functions garantit au moins une exécution, pas une seule).
    const current = currentSnap.data() as CompletionDoc | undefined;
    if (!current || current.status === 'validated') return;

    const user = userSnap.data() as UserDoc;
    const quest = questSnap.data() as QuestTemplate | undefined;
    const reward = quest?.xpReward ?? XP_REWARDS[quest?.difficulty ?? 'easy'] ?? 50;

    const now = new Date();
    const streak = updateStreak(user, now);

    awardXp(db, tx, user, {
      userId: completion.userId,
      amount: reward,
      reason: completion.challengeId ? 'challenge_completion' : 'quest_completion',
      questId: completion.questId,
      completionId: completionRef.id,
    });

    tx.update(userRef, {
      questsCompleted: FieldValue.increment(1),
      streak: streak.streak,
      lastCompletionDate: streak.lastCompletionDate,
    });

    tx.update(completionRef, {
      status: 'validated',
      validationScore: result.score,
      checks: result.checks,
      reason: result.reason,
      xpAwarded: reward,
      proofHash: extra.proofHash,
      validatedAt: FieldValue.serverTimestamp(),
    });

    if (completion.dailySetId) {
      tx.set(
        userRef.collection('assignments').doc(completion.questId),
        { status: 'completed' },
        { merge: true },
      );
    }

    tx.update(questRef, {
      usageCount: FieldValue.increment(1),
      lastUsedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function hasValidatedCompletion(
  db: Firestore,
  userId: string,
  questId: string,
  exceptId: string,
): Promise<boolean> {
  const snapshot = await db
    .collection('questCompletions')
    .where('userId', '==', userId)
    .where('questId', '==', questId)
    .where('status', '==', 'validated')
    .limit(2)
    .get();

  return snapshot.docs.some((doc) => doc.id !== exceptId);
}

async function recentProofHashes(
  db: Firestore,
  userId: string,
  exceptId: string,
): Promise<{ id: string; hash: string }[]> {
  const snapshot = await db
    .collection('questCompletions')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .limit(40)
    .get();

  return snapshot.docs
    .filter((doc) => doc.id !== exceptId)
    .map((doc) => ({ id: doc.id, hash: (doc.data() as CompletionDoc).proofHash ?? '' }))
    .filter((entry) => entry.hash.length > 0);
}

async function downloadAndPrepare(proofPath: string) {
  const [buffer] = await getStorage().bucket().file(proofPath).download();
  return prepareProof(buffer);
}

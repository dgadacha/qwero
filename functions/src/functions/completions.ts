import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';

import { anthropicApiKey, LIMITS, region } from '../config';
import { validateCompletion } from '../game/validate';
import { db } from '../index';
import { errors } from '../lib/errors';
import { consumeQuota, dayWindow } from '../lib/ratelimit';
import { notify } from '../notifications/send';
import { friendIds } from '../social/friends';
import { ALLOWED_EMOJIS, syncCommentCount, syncReactionCount } from '../social/reactions';
import type { CompletionDoc, QuestTemplate, UserDoc } from '../types';

/**
 * Participation à une quête (§83).
 *
 * Le client crée le document avec sa preuve ; le déclencheur ci-dessous
 * enchaîne la validation. Le client n'écrit jamais ni le statut final, ni l'XP.
 */

/** Démarrage d'une quête (§76). Sert au suivi et aux statistiques d'entonnoir. */
export const startQuest = onCall({ region: region.value(), cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw errors.unauthenticated();

  const questId = String(request.data?.questId ?? '');
  if (!questId) throw errors.invalid('Quête manquante.');

  await db
    .collection('users')
    .doc(uid)
    .collection('assignments')
    .doc(questId)
    .set({ status: 'in_progress', startedAt: FieldValue.serverTimestamp() }, { merge: true });

  return { ok: true };
});

/**
 * Validation déclenchée à la création de la participation.
 *
 * `onDocumentCreated` peut rejouer : `validateCompletion` ne crédite qu'une
 * fois, en vérifiant l'état courant dans sa transaction.
 */
export const onCompletionCreated = onDocumentCreated(
  {
    document: 'questCompletions/{completionId}',
    region: region.value(),
    secrets: [anthropicApiKey],
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const completion = snapshot.data() as CompletionDoc;
    if (completion.status !== 'pending_validation') return;

    await validateCompletion({
      db,
      completionId: event.params.completionId,
      completion,
    });
  },
);

/** Prévient le joueur, puis ses amis, une fois le verdict rendu. */
export const onCompletionValidated = onDocumentWritten(
  { document: 'questCompletions/{completionId}', region: region.value() },
  async (event) => {
    const before = event.data?.before.data() as CompletionDoc | undefined;
    const after = event.data?.after.data() as CompletionDoc | undefined;
    if (!after || before?.status === after.status) return;
    if (after.status !== 'validated' && after.status !== 'uncertain') return;

    const questSnap = await db.collection('questTemplates').doc(after.questId).get();
    const quest = questSnap.data() as QuestTemplate | undefined;
    const title = quest?.title ?? 'Ta quête';

    if (after.status === 'uncertain') {
      await notify({
        db,
        userId: after.userId,
        type: 'quest_uncertain',
        title: "On n'est pas sûrs...",
        body: `On n'a pas pu vérifier « ${title} » avec certitude.`,
        questId: after.questId,
      });
      return;
    }

    await notify({
      db,
      userId: after.userId,
      type: 'quest_validated',
      title: 'Quête validée ✨',
      body: `+${after.xpAwarded} XP pour « ${title} ».`,
      questId: after.questId,
    });

    // Les amis apprennent la participation, jamais son contenu (§133).
    const friends = await friendIds(db, after.userId);
    const authorSnap = await db.collection('users').doc(after.userId).get();
    const author = authorSnap.data() as UserDoc | undefined;
    if (!author) return;

    await Promise.all(
      friends.slice(0, 50).map((friendId) =>
        notify({
          db,
          userId: friendId,
          type: 'friend_completed',
          title: `${author.displayName} a joué 👀`,
          body: `« ${title} » est faite de son côté.`,
          questId: after.questId,
          actorId: after.userId,
        }),
      ),
    );
  },
);

/** Contestation d'un refus (§40). Une seule par participation. */
export const contestCompletion = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const completionId = String(request.data?.completionId ?? '');
    const ref = db.collection('questCompletions').doc(completionId);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw errors.notFound('Participation');

    const completion = snapshot.data() as CompletionDoc;
    if (completion.userId !== uid) throw errors.permission();
    if (completion.contested) {
      throw errors.failed('Cette participation a déjà été contestée.');
    }
    if (completion.status === 'validated') {
      throw errors.failed('Cette participation est déjà validée.');
    }
    if (completion.retryCount >= LIMITS.maxRetriesPerQuest) {
      throw errors.exhausted('Limite de nouvelles tentatives atteinte.');
    }

    await ref.update({
      contested: true,
      retryCount: FieldValue.increment(1),
      contestedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true };
  },
);

/** Pose ou retire une réaction (§25). */
export const toggleReaction = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const completionId = String(request.data?.completionId ?? '');
    const emoji = String(request.data?.emoji ?? '');
    if (!ALLOWED_EMOJIS.includes(emoji as (typeof ALLOWED_EMOJIS)[number])) {
      throw errors.invalid('Réaction non reconnue.');
    }

    const completionRef = db.collection('questCompletions').doc(completionId);
    const completionSnap = await completionRef.get();
    if (!completionSnap.exists) throw errors.notFound('Participation');

    const reactionRef = completionRef
      .collection('reactions')
      .doc(`${uid}_${Buffer.from(emoji).toString('hex')}`);

    const existing = await reactionRef.get();
    if (existing.exists) {
      await reactionRef.delete();
      await syncReactionCount(db, completionId, -1);
      return { ok: true, active: false };
    }

    await reactionRef.set({
      userId: uid,
      emoji,
      createdAt: FieldValue.serverTimestamp(),
    });
    await syncReactionCount(db, completionId, 1);
    return { ok: true, active: true };
  },
);

/** Ajoute un commentaire (§109 pour la modération a posteriori). */
export const addComment = onCall({ region: region.value(), cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw errors.unauthenticated();

  const completionId = String(request.data?.completionId ?? '');
  const text = String(request.data?.text ?? '').trim();
  if (text.length === 0 || text.length > 500) throw errors.invalid('Commentaire invalide.');

  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data() as UserDoc | undefined;
  if (!user) throw errors.notFound('Profil');

  await consumeQuota(
    db,
    uid,
    'comments',
    LIMITS.maxCommentsPerHour,
    new Date().toISOString().slice(0, 13),
    'Trop de commentaires, réessaie un peu plus tard.',
  );

  const completionRef = db.collection('questCompletions').doc(completionId);
  await completionRef.collection('comments').add({
    authorId: uid,
    authorName: user.displayName,
    text,
    createdAt: FieldValue.serverTimestamp(),
  });
  await syncCommentCount(db, completionId, 1);

  return { ok: true };
});

/** Marque la journée du joueur, utilisé par les rappels de streak. */
export const touchActivity = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const userSnap = await db.collection('users').doc(uid).get();
    const user = userSnap.data() as UserDoc | undefined;
    if (!user) throw errors.notFound('Profil');

    await db.collection('users').doc(uid).update({
      lastSeenAt: Timestamp.now(),
      lastSeenDay: dayWindow(new Date(), user.timezone),
    });
    return { ok: true };
  },
);

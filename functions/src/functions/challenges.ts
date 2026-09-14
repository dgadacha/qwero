import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { parseUserQuest } from '../claude/moderate';
import { normalizeTitle } from '../claude/generate';
import { anthropicApiKey, LIMITS, region, XP_REWARDS } from '../config';
import { db } from '../index';
import { errors } from '../lib/errors';
import { consumeQuota, dayWindow } from '../lib/ratelimit';
import { notify } from '../notifications/send';
import { areFriends } from '../social/friends';
import type { ChallengeDoc, UserDoc } from '../types';

/**
 * Challenges entre amis (§43, §46).
 *
 *   consigne → analyse Claude → contrôle de sécurité → critères →
 *   choix de l'ami → envoi
 *
 * Le défi est asynchrone : chacun le relève quand il veut, dans les 24 heures.
 */

export const sendChallenge = onCall(
  {
    region: region.value(),
    cors: true,
    secrets: [anthropicApiKey],
    timeoutSeconds: 60,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const toId = String(request.data?.toId ?? '');
    const text = String(request.data?.text ?? '').trim();

    if (!toId) throw errors.invalid('Destinataire manquant.');
    if (toId === uid) throw errors.invalid('On ne se défie pas soi-même.');
    if (text.length < 5 || text.length > 120) {
      throw errors.invalid('La consigne doit faire entre 5 et 120 caractères.');
    }
    if (!(await areFriends(db, uid, toId))) {
      throw errors.permission('Vous ne faites pas partie des amis.');
    }

    const userSnap = await db.collection('users').doc(uid).get();
    const user = userSnap.data() as UserDoc | undefined;
    if (!user) throw errors.notFound('Profil');

    await consumeQuota(
      db,
      uid,
      'challenges',
      LIMITS.maxChallengesPerDay,
      dayWindow(new Date(), user.timezone),
      'Tu as atteint ta limite de challenges pour aujourd\'hui.',
    );

    const parsed = await parseUserQuest(text, user.locale || 'fr');
    if (!parsed.safe) {
      throw errors.invalid(parsed.rejectionReason ?? 'Cette consigne ne peut pas être envoyée.');
    }

    const questRef = db.collection('questTemplates').doc();
    await questRef.set({
      title: text,
      description: `Challenge lancé par ${user.displayName}.`,
      category: parsed.category,
      difficulty: parsed.difficulty,
      estimatedMinutes: parsed.estimatedMinutes,
      proofType: 'photo',
      galleryAllowed: false,
      xpReward: XP_REWARDS[parsed.difficulty] ?? 50,
      requirements: [
        { id: 'photo', type: 'technical', value: 'in_app', label: 'Photo', emoji: '📷' },
        ...parsed.requirements.map((r) => ({
          id: r.id,
          type: r.type,
          value: r.value,
          ...(r.target ? { target: r.target } : {}),
          label: r.label,
          emoji: r.emoji,
        })),
      ],
      safety: { riskLevel: 'low' },
      source: 'user',
      status: 'approved',
      authorId: uid,
      usageCount: 0,
      normalizedTitle: normalizeTitle(text),
      lastUsedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    const expiresAt = Timestamp.fromDate(new Date(Date.now() + 24 * 3600 * 1000));
    const challengeRef = db.collection('challenges').doc();
    await challengeRef.set({
      fromId: uid,
      toId,
      questId: questRef.id,
      state: 'pending',
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      respondedAt: null,
    } satisfies Omit<ChallengeDoc, 'createdAt'> & { createdAt: FirebaseFirestore.FieldValue });

    await notify({
      db,
      userId: toId,
      type: 'challenge_received',
      title: `⚔️ ${user.displayName} t'a défié`,
      body: text,
      questId: questRef.id,
      actorId: uid,
    });

    return { ok: true, challengeId: challengeRef.id, questId: questRef.id };
  },
);

export const answerChallenge = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const challengeId = String(request.data?.challengeId ?? '');
    const accept = request.data?.accept === true;

    const ref = db.collection('challenges').doc(challengeId);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw errors.notFound('Challenge');

    const challenge = snapshot.data() as ChallengeDoc;
    if (challenge.toId !== uid) throw errors.permission();
    if (challenge.state !== 'pending') throw errors.failed('Ce challenge a déjà une réponse.');

    await ref.update({
      state: accept ? 'accepted' : 'declined',
      respondedAt: FieldValue.serverTimestamp(),
    });

    if (accept) {
      await db
        .collection('users')
        .doc(uid)
        .collection('assignments')
        .doc(challenge.questId)
        .set(
          {
            questId: challenge.questId,
            dailySetId: null,
            difficulty: 'medium',
            status: 'available',
            assignedAt: FieldValue.serverTimestamp(),
            expiresAt: challenge.expiresAt,
            challengeId,
          },
          { merge: true },
        );
    }

    return { ok: true };
  },
);

/** Quête libre proposée à la communauté (§45). */
export const submitCommunityQuest = onCall(
  {
    region: region.value(),
    cors: true,
    secrets: [anthropicApiKey],
    timeoutSeconds: 60,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const text = String(request.data?.text ?? '').trim();
    if (text.length < 5 || text.length > 120) {
      throw errors.invalid('La consigne doit faire entre 5 et 120 caractères.');
    }

    const userSnap = await db.collection('users').doc(uid).get();
    const user = userSnap.data() as UserDoc | undefined;
    if (!user) throw errors.notFound('Profil');

    await consumeQuota(
      db,
      uid,
      'userQuests',
      LIMITS.maxUserQuestsPerDay,
      dayWindow(new Date(), user.timezone),
      'Tu as déjà proposé plusieurs quêtes aujourd\'hui.',
    );

    const parsed = await parseUserQuest(text, user.locale || 'fr');

    // Une quête communautaire reste en attente : elle n'atteint personne avant
    // relecture (§42).
    const ref = db.collection('questTemplates').doc();
    await ref.set({
      title: text,
      description: 'Proposée par la communauté.',
      category: parsed.category,
      difficulty: parsed.difficulty,
      estimatedMinutes: parsed.estimatedMinutes,
      proofType: 'photo',
      galleryAllowed: false,
      xpReward: XP_REWARDS[parsed.difficulty] ?? 50,
      requirements: parsed.requirements,
      safety: { riskLevel: parsed.safe ? 'low' : 'high' },
      source: 'user',
      status: parsed.safe ? 'draft' : 'rejected',
      ...(parsed.rejectionReason ? { rejectionReason: parsed.rejectionReason } : {}),
      authorId: uid,
      usageCount: 0,
      normalizedTitle: normalizeTitle(text),
      lastUsedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    if (!parsed.safe) {
      throw errors.invalid(parsed.rejectionReason ?? 'Cette quête ne peut pas être publiée.');
    }

    return { ok: true, status: 'draft' };
  },
);

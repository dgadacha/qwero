import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { LIMITS, region } from '../config';
import { db } from '../index';
import { errors } from '../lib/errors';
import { consumeQuota, dayWindow } from '../lib/ratelimit';
import { notify } from '../notifications/send';
import { areFriends, createFriendship } from '../social/friends';
import type { UserDoc } from '../types';

/**
 * Demandes d'amitié (§163) et signalements (§109).
 *
 * L'amitié est mutuelle : elle n'existe qu'après acceptation, et les deux sens
 * sont écrits ensemble par `createFriendship`.
 */

export const sendFriendRequest = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const username = String(request.data?.username ?? '').trim().toLowerCase();
    if (!username) throw errors.invalid('Pseudo manquant.');

    const usernameSnap = await db.collection('usernames').doc(username).get();
    if (!usernameSnap.exists) throw errors.notFound('Ce pseudo');

    const toId = usernameSnap.data()?.userId as string;
    if (toId === uid) throw errors.invalid('Tu es déjà toi-même.');
    if (await areFriends(db, uid, toId)) throw errors.failed('Vous êtes déjà amis.');

    const blocked = await db.collection('blocks').doc(`${toId}_${uid}`).get();
    if (blocked.exists) throw errors.permission();

    const userSnap = await db.collection('users').doc(uid).get();
    const user = userSnap.data() as UserDoc | undefined;
    if (!user) throw errors.notFound('Profil');

    await consumeQuota(
      db,
      uid,
      'friendRequests',
      LIMITS.maxFriendRequestsPerDay,
      dayWindow(new Date(), user.timezone),
      'Trop de demandes envoyées aujourd\'hui.',
    );

    // Une demande en sens inverse vaut acceptation : deux personnes qui
    // s'ajoutent en même temps deviennent amies sans étape de plus.
    const reverseId = `${toId}_${uid}`;
    const reverse = await db.collection('friendRequests').doc(reverseId).get();
    if (reverse.exists && reverse.data()?.state === 'pending') {
      await Promise.all([
        createFriendship(db, uid, toId),
        reverse.ref.update({ state: 'accepted', respondedAt: FieldValue.serverTimestamp() }),
      ]);
      return { ok: true, friends: true };
    }

    await db.collection('friendRequests').doc(`${uid}_${toId}`).set({
      fromId: uid,
      toId,
      fromName: user.displayName,
      state: 'pending',
      createdAt: FieldValue.serverTimestamp(),
      respondedAt: null,
    });

    await notify({
      db,
      userId: toId,
      type: 'friend_completed',
      title: 'Nouvelle demande',
      body: `${user.displayName} veut jouer avec toi.`,
      actorId: uid,
    });

    return { ok: true, friends: false };
  },
);

export const answerFriendRequest = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const requestId = String(request.data?.requestId ?? '');
    const accept = request.data?.accept === true;

    const ref = db.collection('friendRequests').doc(requestId);
    const snapshot = await ref.get();
    if (!snapshot.exists) throw errors.notFound('Demande');

    const data = snapshot.data() as { fromId: string; toId: string; state: string };
    if (data.toId !== uid) throw errors.permission();
    if (data.state !== 'pending') throw errors.failed('Cette demande a déjà une réponse.');

    await ref.update({
      state: accept ? 'accepted' : 'declined',
      respondedAt: FieldValue.serverTimestamp(),
    });

    if (accept) await createFriendship(db, data.fromId, data.toId);

    return { ok: true };
  },
);

/** Bloquer quelqu'un rompt l'amitié dans les deux sens (§109). */
export const blockUser = onCall({ region: region.value(), cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw errors.unauthenticated();

  const targetId = String(request.data?.userId ?? '');
  if (!targetId || targetId === uid) throw errors.invalid('Utilisateur invalide.');

  const batch = db.batch();
  batch.set(db.collection('blocks').doc(`${uid}_${targetId}`), {
    userId: uid,
    blockedId: targetId,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.delete(db.collection('friendships').doc(`${uid}_${targetId}`));
  batch.delete(db.collection('friendships').doc(`${targetId}_${uid}`));
  await batch.commit();

  return { ok: true };
});

/** Signalement d'une participation ou d'un commentaire (§109). */
export const reportContent = onCall({ region: region.value(), cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw errors.unauthenticated();

  const reasons = ['dangerous', 'harassment', 'nudity', 'spam', 'privacy', 'illegal', 'other'];
  const reason = String(request.data?.reason ?? '');
  const targetId = String(request.data?.targetId ?? '');
  const targetType = String(request.data?.targetType ?? 'completion');

  if (!reasons.includes(reason)) throw errors.invalid('Motif inconnu.');
  if (!targetId) throw errors.invalid('Contenu manquant.');

  await db.collection('reports').add({
    reporterId: uid,
    targetId,
    targetType,
    reason,
    note: String(request.data?.note ?? '').slice(0, 500),
    state: 'open',
    createdAt: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

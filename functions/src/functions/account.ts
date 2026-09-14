import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';

import { db } from '../index';
import { errors } from '../lib/errors';
import { initialCohort } from '../social/friends';
import { region } from '../config';
import type { QuestCategory, UserDoc, Visibility } from '../types';

/**
 * Création de compte et profil (§72, §164).
 *
 * Le pseudo est unique et insensible à la casse. La réservation passe par une
 * transaction sur un document dédié : deux inscriptions simultanées avec le
 * même pseudo ne peuvent pas aboutir toutes les deux.
 */

const USERNAME_PATTERN = /^[a-z0-9_]{3,20}$/;

export const createAccount = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const username = String(request.data?.username ?? '').trim().toLowerCase();
    const displayName = String(request.data?.displayName ?? '').trim();
    const timezone = String(request.data?.timezone ?? 'Europe/Paris');
    const locale = String(request.data?.locale ?? 'fr');
    const interests = (request.data?.interests ?? []) as QuestCategory[];

    if (!USERNAME_PATTERN.test(username)) {
      throw errors.invalid('Le pseudo doit faire 3 à 20 caractères : a-z, 0-9 et _.');
    }
    if (displayName.length === 0 || displayName.length > 40) {
      throw errors.invalid('Nom affiché invalide.');
    }

    const userRef = db.collection('users').doc(uid);
    const usernameRef = db.collection('usernames').doc(username);

    await db.runTransaction(async (tx) => {
      const [existingUser, takenUsername] = await Promise.all([
        tx.get(userRef),
        tx.get(usernameRef),
      ]);

      if (existingUser.exists) throw errors.failed('Ce compte est déjà créé.');
      if (takenUsername.exists) throw errors.failed('Ce pseudo est déjà pris.');

      const user: Omit<UserDoc, 'createdAt'> & { createdAt: FirebaseFirestore.FieldValue } = {
        username,
        usernameLower: username,
        displayName,
        avatarUrl: null,
        level: 1,
        xp: 0,
        streak: 0,
        questsCompleted: 0,
        lastCompletionDate: null,
        timezone,
        locale,
        interests,
        visibility: 'friends' as Visibility,
        worldQuestOptIn: false,
        cohortId: initialCohort(uid, timezone),
        fcmTokens: [],
        notificationPrefs: { dailyQuests: true, friendActivity: true, challenges: true },
        createdAt: FieldValue.serverTimestamp(),
      };

      tx.set(userRef, user);
      tx.set(usernameRef, { userId: uid, createdAt: FieldValue.serverTimestamp() });
      tx.set(db.collection('publicProfiles').doc(uid), {
        username,
        displayName,
        avatarUrl: null,
        level: 1,
      });
    });

    return { ok: true, cohortId: initialCohort(uid, timezone) };
  },
);

/** Enregistre le jeton push de l'appareil courant. */
export const registerDevice = onCall(
  { region: region.value(), cors: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw errors.unauthenticated();

    const token = String(request.data?.token ?? '');
    if (token.length < 10) throw errors.invalid('Jeton invalide.');

    await db.collection('users').doc(uid).update({
      fcmTokens: FieldValue.arrayUnion(token),
    });
    return { ok: true };
  },
);

/** Libère le pseudo quand un compte disparaît. */
export const releaseUsername = onDocumentDeleted(
  { document: 'users/{userId}', region: region.value() },
  async (event) => {
    const username = (event.data?.data() as UserDoc | undefined)?.usernameLower;
    if (!username) return;
    await Promise.all([
      db.collection('usernames').doc(username).delete(),
      db.collection('publicProfiles').doc(event.params.userId).delete(),
    ]);
  },
);

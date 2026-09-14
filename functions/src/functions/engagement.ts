import { Timestamp } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { region } from '../config';
import { db } from '../index';
import { notify } from '../notifications/send';
import { localDate } from '../game/streak';
import type { UserDoc } from '../types';

/**
 * Notifications de rythme (§64, §133, §179).
 *
 * Deux moments, pas davantage : les quêtes du matin, et un rappel de streak en
 * soirée pour qui n'a rien fait. Le contenu ne révèle jamais la réponse d'un
 * ami.
 */

/** « Tes nouvelles quêtes sont là » : à 8h locale de chaque groupe. */
export const sendMorningQuests = onSchedule(
  {
    schedule: '0 * * * *',
    timeZone: 'UTC',
    region: region.value(),
    timeoutSeconds: 540,
  },
  async () => {
    await notifyAtLocalHour(8, async (user, userId) => {
      if (user.notificationPrefs?.dailyQuests === false) return;
      await notify({
        db,
        userId,
        type: 'daily_quests',
        title: 'Tes nouvelles quêtes sont là 👀',
        body: "Trois défis et une World Quest t'attendent.",
      });
    });
  },
);

/** Rappel de streak à 20h locale, seulement si la journée est vide (§63). */
export const sendStreakReminder = onSchedule(
  {
    schedule: '30 * * * *',
    timeZone: 'UTC',
    region: region.value(),
    timeoutSeconds: 540,
  },
  async () => {
    await notifyAtLocalHour(20, async (user, userId) => {
      if (user.notificationPrefs?.dailyQuests === false) return;
      if (user.streak === 0) return;

      const today = localDate(new Date(), user.timezone);
      if (user.lastCompletionDate === today) return;

      await notify({
        db,
        userId,
        type: 'streak_reminder',
        title: `🔥 ${user.streak} jours, ça serait dommage`,
        body: 'Une quête facile suffit à garder ton streak.',
      });
    });
  },
);

/**
 * Parcourt les joueurs dont l'heure locale correspond.
 *
 * Firestore ne sait pas filtrer sur « heure locale » : on compare le décalage
 * calculé pour chaque fuseau présent en base, ce qui reste bien moins coûteux
 * qu'une tâche par utilisateur.
 */
async function notifyAtLocalHour(
  targetHour: number,
  action: (user: UserDoc, userId: string) => Promise<void>,
): Promise<void> {
  const now = new Date();
  const snapshot = await db.collection('users').get();

  const work: Promise<void>[] = [];
  for (const doc of snapshot.docs) {
    const user = doc.data() as UserDoc;
    if (localHour(now, user.timezone) !== targetHour) continue;
    work.push(action(user, doc.id));
  }

  await Promise.all(work);
  console.log(JSON.stringify({ localHour: targetHour, notified: work.length }));
}

function localHour(at: Date, timezone: string): number {
  try {
    const formatted = new Intl.DateTimeFormat('en-GB', {
      timeZone: timezone,
      hour: '2-digit',
      hour12: false,
    }).format(at);
    return Number.parseInt(formatted, 10);
  } catch {
    return at.getUTCHours();
  }
}

/** Ferme les challenges dépassés (§46). */
export const expireChallenges = onSchedule(
  { schedule: '15 * * * *', timeZone: 'UTC', region: region.value() },
  async () => {
    const snapshot = await db
      .collection('challenges')
      .where('state', 'in', ['pending', 'accepted'])
      .where('expiresAt', '<', Timestamp.now())
      .limit(500)
      .get();

    if (snapshot.empty) return;

    const batch = db.batch();
    for (const doc of snapshot.docs) batch.update(doc.ref, { state: 'expired' });
    await batch.commit();

    console.log(JSON.stringify({ expiredChallenges: snapshot.size }));
  },
);

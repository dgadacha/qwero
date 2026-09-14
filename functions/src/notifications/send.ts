import { getMessaging } from 'firebase-admin/messaging';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import type { NotificationDoc, UserDoc } from '../types';

/**
 * Notifications (§63, §64).
 *
 * Chaque notification laisse une trace en base et part en push si le joueur l'a
 * acceptée. Le contenu ne divulgue jamais la réponse d'un ami : il donne envie
 * d'ouvrir, sans divulgâcher (§133).
 */

export interface NotifyInput {
  db: Firestore;
  userId: string;
  type: NotificationDoc['type'];
  title: string;
  body: string;
  questId?: string | null;
  actorId?: string | null;
}

export async function notify(input: NotifyInput): Promise<void> {
  const { db, userId } = input;

  const userSnap = await db.collection('users').doc(userId).get();
  if (!userSnap.exists) return;
  const user = userSnap.data() as UserDoc;

  await db
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .add({
      type: input.type,
      title: input.title,
      body: input.body,
      questId: input.questId ?? null,
      actorId: input.actorId ?? null,
      createdAt: FieldValue.serverTimestamp(),
      readAt: null,
    });

  if (!wantsPush(user, input.type)) return;
  const tokens = user.fcmTokens ?? [];
  if (tokens.length === 0) return;

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: input.title, body: input.body },
      data: {
        type: input.type,
        ...(input.questId ? { questId: input.questId } : {}),
      },
      apns: { payload: { aps: { sound: 'default' } } },
      android: { priority: 'high' },
    });

    // Les jetons refusés sont retirés : un appareil désinstallé ne doit pas
    // faire échouer les envois suivants.
    const stale = response.responses
      .map((result, index) => (result.success ? null : tokens[index]))
      .filter((token): token is string => token !== null);

    if (stale.length > 0) {
      await db
        .collection('users')
        .doc(userId)
        .update({ fcmTokens: FieldValue.arrayRemove(...stale) });
    }
  } catch (error) {
    console.error('Envoi push en échec', { userId, error: String(error) });
  }
}

function wantsPush(user: UserDoc, type: NotificationDoc['type']): boolean {
  const prefs = user.notificationPrefs;
  if (!prefs) return true;
  switch (type) {
    case 'daily_quests':
    case 'streak_reminder':
      return prefs.dailyQuests !== false;
    case 'challenge_received':
      return prefs.challenges !== false;
    case 'friend_completed':
    case 'friend_favorite':
      return prefs.friendActivity !== false;
    default:
      return true;
  }
}

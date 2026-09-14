import type { UserDoc } from '../types';

/**
 * Streak (§53).
 *
 * Le streak avance à la première quête terminée dans la journée locale du
 * joueur : deux quêtes le même jour ne comptent qu'une fois, et un jour sauté
 * remet le compteur à un.
 */

export interface StreakOutput {
  streak: number;
  changed: boolean;
  lastCompletionDate: string;
}

/** Date locale du joueur, au format YYYY-MM-DD. */
export function localDate(at: Date, timezone: string): string {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(at);
  } catch {
    // Fuseau inconnu : on retombe sur UTC plutôt que d'échouer.
    return at.toISOString().slice(0, 10);
  }
}

function previousDay(date: string): string {
  const [y, m, d] = date.split('-').map(Number);
  const previous = new Date(Date.UTC(y ?? 1970, (m ?? 1) - 1, (d ?? 1) - 1));
  return previous.toISOString().slice(0, 10);
}

export function updateStreak(user: UserDoc, completedAt: Date): StreakOutput {
  const today = localDate(completedAt, user.timezone);
  const last = user.lastCompletionDate;

  if (last === today) {
    return { streak: user.streak, changed: false, lastCompletionDate: today };
  }

  const continued = last !== null && last === previousDay(today);
  const streak = continued ? user.streak + 1 : 1;

  return { streak, changed: true, lastCompletionDate: today };
}

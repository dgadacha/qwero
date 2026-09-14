import { onSchedule } from 'firebase-functions/v2/scheduler';

import { anthropicApiKey, region } from '../config';
import { db } from '../index';
import { assignSetToCohort } from '../quests/assign';
import { buildDailySet, ensureWorldQuest, TIMEZONE_GROUPS, type TimezoneGroup } from '../quests/daily';
import { poolHealth, refillPool } from '../quests/pool';

/**
 * Planification (§77).
 *
 * Deux rythmes distincts :
 *   - le pool se remplit une fois par jour, très en avance ;
 *   - les sets se composent une heure avant le basculement de chaque groupe de
 *     fuseaux, en puisant dans le pool déjà constitué.
 *
 * Rien n'attend Claude au moment où un joueur ouvre l'application.
 */

/** Remplissage du pool. Tourne à 03h00 UTC, loin des pics d'usage. */
export const refillQuestPool = onSchedule(
  {
    schedule: '0 3 * * *',
    timeZone: 'UTC',
    region: region.value(),
    secrets: [anthropicApiKey],
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const season = seasonOf(new Date());
    const reports = [];

    for (const difficulty of ['easy', 'medium', 'hard'] as const) {
      try {
        reports.push(await refillPool(db, difficulty, season, 'fr'));
      } catch (error) {
        console.error('Remplissage du pool en échec', { difficulty, error: String(error) });
      }
    }

    console.log(JSON.stringify({ poolRefill: reports, health: await poolHealth(db) }));
  },
);

/**
 * Composition et attribution des sets.
 *
 * La fonction tourne toutes les heures et ne traite que les groupes de fuseaux
 * dont la journée commence dans l'heure qui suit.
 */
export const publishDailySets = onSchedule(
  {
    schedule: '5 * * * *',
    timeZone: 'UTC',
    region: region.value(),
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const now = new Date();
    const groups = groupsStartingSoon(now);
    if (groups.length === 0) return;

    for (const group of groups) {
      const date = localDateForGroup(now, group);
      const worldQuestId = await ensureWorldQuest(db, date);
      if (!worldQuestId) {
        console.error('Aucune World Quest disponible', { date });
        continue;
      }

      const cohorts = await cohortsOfGroup(group);
      for (const cohortId of cohorts) {
        const set = await buildDailySet({ db, cohortId, date, group, worldQuestId });
        if (!set) continue;
        const assigned = await assignSetToCohort(db, set);
        console.log(JSON.stringify({ dailySet: set.id, assigned }));
      }
    }
  },
);

/** Les groupes dont la journée locale démarre dans l'heure à venir. */
function groupsStartingSoon(now: Date): TimezoneGroup[] {
  const utcHour = now.getUTCHours();
  return (Object.keys(TIMEZONE_GROUPS) as TimezoneGroup[]).filter((group) => {
    const offset = TIMEZONE_GROUPS[group].offsetHours;
    // Minuit local correspond à (24 - offset) % 24 en UTC. On prépare une heure
    // avant pour que tout soit prêt au basculement.
    const localMidnightUtc = (24 - offset + 24) % 24;
    const prepareAt = (localMidnightUtc - 1 + 24) % 24;
    return utcHour === prepareAt;
  });
}

function localDateForGroup(now: Date, group: TimezoneGroup): string {
  const shifted = new Date(now.getTime() + TIMEZONE_GROUPS[group].offsetHours * 3600 * 1000);
  // On prépare la journée qui commence, donc celle de demain côté local.
  shifted.setUTCDate(shifted.getUTCDate() + 1);
  return shifted.toISOString().slice(0, 10);
}

async function cohortsOfGroup(group: TimezoneGroup): Promise<string[]> {
  const snapshot = await db.collection('users').select('cohortId').get();
  const cohorts = new Set<string>();
  for (const doc of snapshot.docs) {
    const cohortId = doc.data().cohortId as string | undefined;
    if (cohortId?.startsWith(`${group}-`)) cohorts.add(cohortId);
  }
  return [...cohorts];
}

function seasonOf(date: Date): string {
  const month = date.getUTCMonth() + 1;
  if (month <= 2 || month === 12) return 'hiver dans l\'hémisphère nord, été dans le sud';
  if (month <= 5) return 'printemps dans l\'hémisphère nord, automne dans le sud';
  if (month <= 8) return 'été dans l\'hémisphère nord, hiver dans le sud';
  return 'automne dans l\'hémisphère nord, printemps dans le sud';
}

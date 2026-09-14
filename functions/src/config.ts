import { defineInt, defineSecret, defineString } from 'firebase-functions/params';

/**
 * Paramètres de déploiement.
 *
 * Les seuils du Score Engine et les récompenses restent réglables sans
 * redéploiement (§36, §121) : ils sont lus depuis Remote Config quand il est
 * disponible, avec ces valeurs pour repli.
 */

export const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

export const region = defineString('QUEST_REGION', { default: 'europe-west1' });

/** Seuils du Score Engine (§36). */
export const passThreshold = defineInt('QUESTCHECK_PASS', { default: 90 });
export const uncertainThreshold = defineInt('QUESTCHECK_UNCERTAIN', { default: 60 });

/** Récompenses de base (§49). */
export const XP_REWARDS: Record<string, number> = {
  easy: 50,
  medium: 150,
  hard: 400,
  world: 250,
};

/** Modèle utilisé pour l'analyse des preuves et la génération des quêtes. */
export const CLAUDE_MODEL = 'claude-opus-5';

/** Quotas (§155). */
export const LIMITS = {
  /** Une seule nouvelle tentative par participation refusée (§40). */
  maxRetriesPerQuest: 1,
  maxChallengesPerDay: 10,
  maxUserQuestsPerDay: 3,
  maxCommentsPerHour: 60,
  maxFriendRequestsPerDay: 30,
};

/** Courbe d'XP (§51). Doit rester identique à celle du client. */
export function xpForLevel(level: number): number {
  return Math.round(100 * Math.pow(level, 1.35));
}

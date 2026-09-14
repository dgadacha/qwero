import { passThreshold, uncertainThreshold } from '../config';
import type {
  CompletionDoc,
  QuestCheckItem,
  QuestCheckResult,
  QuestCheckVerdict,
  QuestTemplate,
} from '../types';

/**
 * Contrôles déterministes (§34) et Score Engine (§36).
 *
 * Tout ce qui peut être tranché sans modèle l'est avant l'appel : c'est plus
 * fiable, instantané, et cela évite une facture inutile (§157).
 */

export interface DeterministicInput {
  quest: QuestTemplate;
  completion: Pick<CompletionDoc, 'capturedAt' | 'createdAt' | 'retryCount'>;
  /** Participation déjà validée pour cette quête et ce joueur. */
  alreadyCompleted: boolean;
  /** Preuve identique déjà envoyée (empreinte perceptuelle, §41). */
  duplicateOfCompletionId: string | null;
  /** Fin de validité de la quête. */
  expiresAt: Date | null;
  now: Date;
}

export interface DeterministicVerdict {
  /** Renseigné seulement si un contrôle rejette d'emblée. */
  rejection: { id: string; label: string; reason: string } | null;
}

/** Contrôles qui ne demandent pas d'analyse d'image. */
export function runDeterministicChecks(input: DeterministicInput): DeterministicVerdict {
  const { quest, completion, now } = input;

  if (input.alreadyCompleted) {
    return {
      rejection: {
        id: 'already_completed',
        label: 'Quête déjà terminée',
        reason: 'Cette quête a déjà été validée pour ce joueur.',
      },
    };
  }

  if (input.duplicateOfCompletionId) {
    return {
      rejection: {
        id: 'duplicate_proof',
        label: 'Photo déjà utilisée',
        reason: 'Cette photo a déjà servi à valider une quête.',
      },
    };
  }

  if (input.expiresAt && now.getTime() > input.expiresAt.getTime()) {
    return {
      rejection: {
        id: 'expired',
        label: 'Quête expirée',
        reason: "La quête n'était plus disponible au moment de la capture.",
      },
    };
  }

  // La capture doit être récente et postérieure au début de la quête : une
  // photo prise depuis l'app porte l'horodatage du client, borné par celui du
  // serveur à l'écriture.
  const capturedAt = completion.capturedAt?.toDate() ?? null;
  if (capturedAt) {
    const ageMinutes = (now.getTime() - capturedAt.getTime()) / 60_000;
    if (ageMinutes > 60) {
      return {
        rejection: {
          id: 'stale_capture',
          label: 'Capture trop ancienne',
          reason: "La photo n'a pas été prise à l'instant depuis l'application.",
        },
      };
    }
    if (ageMinutes < -5) {
      return {
        rejection: {
          id: 'clock_skew',
          label: 'Horodatage incohérent',
          reason: "L'horodatage de la capture est dans le futur.",
        },
      };
    }
  }

  if (quest.proofType !== 'photo') {
    return {
      rejection: {
        id: 'unsupported_proof',
        label: 'Type de preuve non pris en charge',
        reason: 'Seules les preuves photo sont vérifiées pour le moment.',
      },
    };
  }

  return { rejection: null };
}

/** Contrôles toujours satisfaits quand la preuve vient de l'app (§34). */
export function deterministicPassedChecks(): QuestCheckItem[] {
  return [
    { id: 'photo', label: "Photo prise depuis l'app", passed: true, confidence: 1 },
    { id: 'live', label: 'Capture en direct', passed: true, confidence: 1 },
  ];
}

/**
 * Score Engine (§36). Moyenne des confiances, les critères non remplis pesant
 * zéro, puis comparaison aux seuils.
 */
export function scoreEngine(checks: QuestCheckItem[]): {
  score: number;
  verdict: QuestCheckVerdict;
} {
  if (checks.length === 0) return { score: 0, verdict: 'fail' };

  const total = checks.reduce((sum, c) => sum + (c.passed ? c.confidence : 0), 0);
  const score = total / checks.length;

  const pass = passThreshold.value() / 100;
  const uncertain = uncertainThreshold.value() / 100;

  const verdict: QuestCheckVerdict =
    score >= pass ? 'pass' : score >= uncertain ? 'uncertain' : 'fail';

  return { score, verdict };
}

/** Assemble le résultat rendu au client. */
export function buildResult(
  checks: QuestCheckItem[],
  reason: string,
  decidedBy: QuestCheckResult['decidedBy'],
): QuestCheckResult {
  const { score, verdict } = scoreEngine(checks);
  return { verdict, score, checks, reason, decidedBy };
}

/** Résultat d'un refus déterministe : pas d'appel modèle, score nul. */
export function rejectedResult(
  rejection: NonNullable<DeterministicVerdict['rejection']>,
): QuestCheckResult {
  return {
    verdict: 'fail',
    score: 0,
    checks: [{ id: rejection.id, label: rejection.label, passed: false, confidence: 1 }],
    reason: rejection.reason,
    decidedBy: 'deterministic',
  };
}

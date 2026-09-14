import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod';

import { CLAUDE_MODEL } from '../config';
import type { QuestCheckItem, QuestRequirement } from '../types';
import { claude, logUsage } from './client';

/**
 * Analyse multimodale de la preuve (§35).
 *
 * Claude ne décide pas seul du verdict : il répond par critère, avec une
 * confiance. Le Score Engine (game/score.ts) tranche à partir de seuils
 * réglables. Cette séparation permet d'ajuster la sévérité sans retoucher au
 * prompt.
 */

const AnalysisSchema = z.object({
  checks: z
    .array(
      z.object({
        id: z.string().describe("Identifiant du critère, repris tel quel"),
        passed: z.boolean(),
        confidence: z.number().min(0).max(1),
        evidence: z
          .string()
          .describe("Ce qui est visible dans l'image et justifie la décision"),
      }),
    )
    .describe('Un élément par critère demandé, dans le même ordre'),
  summary: z.string().describe('Une phrase, adressée au joueur'),
  suspicious: z
    .boolean()
    .describe(
      "Vrai si l'image semble être une capture d'écran, une photo de photo ou une image générée",
    ),
});

export type ModelAnalysis = z.infer<typeof AnalysisSchema>;

/**
 * Consigne stable : placée en tête et mise en cache, elle ne varie pas d'une
 * quête à l'autre (§81).
 */
const SYSTEM = `Tu es QuestCheck, le système de vérification de QUEST, une application où des amis accomplissent chaque jour des défis dans la vraie vie et en rapportent une photo.

Ton rôle : dire, critère par critère, si la photo remplit ce que la quête demande.

Règles de jugement :
- Juge uniquement ce qui est visible dans l'image. N'invente rien.
- Accorde le bénéfice du doute sur les quêtes légères : un faux refus frustre davantage qu'une validation un peu permissive. Si un critère est plausiblement rempli, marque-le comme rempli avec une confiance moyenne plutôt que de le refuser.
- Reste strict sur ce qui est vérifiable objectivement : un objet absent est absent, un intérieur n'est pas un extérieur.
- Une photo manifestement hors-sujet doit être refusée clairement.
- Signale comme suspecte une capture d'écran, une photo d'écran, une image visiblement générée ou une reproduction d'image existante.
- La confiance exprime ta certitude visuelle, pas ton indulgence.

Tu réponds toujours dans la structure demandée, avec exactement un élément par critère, en reprenant les identifiants fournis.`;

export interface AnalyseInput {
  questTitle: string;
  questDescription: string;
  requirements: QuestRequirement[];
  imageBase64: string;
  mediaType: 'image/jpeg' | 'image/png' | 'image/webp';
  locale: string;
}

export interface AnalyseOutput {
  checks: QuestCheckItem[];
  summary: string;
  suspicious: boolean;
}

/** Appelle Claude et renvoie une évaluation par critère. */
export async function analyseProof(input: AnalyseInput): Promise<AnalyseOutput> {
  const startedAt = Date.now();

  const criteria = input.requirements
    .map((r) => `- ${r.id} (${r.type}${r.target ? ` sur ${r.target}` : ''} = ${r.value}) : ${r.label}`)
    .join('\n');

  const response = await claude().messages.parse({
    model: CLAUDE_MODEL,
    max_tokens: 2000,
    system: [{ type: 'text', text: SYSTEM, cache_control: { type: 'ephemeral' } }],
    thinking: { type: 'adaptive' },
    output_config: {
      effort: 'medium',
      format: zodOutputFormat(AnalysisSchema),
    },
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: input.mediaType, data: input.imageBase64 },
          },
          {
            type: 'text',
            text: `Quête : ${input.questTitle}
Consigne donnée au joueur : ${input.questDescription}

Critères à vérifier :
${criteria}

Rédige "summary" dans la langue du joueur (${input.locale}).`,
          },
        ],
      },
    ],
  });

  logUsage(
    'questcheck',
    { requirements: input.requirements.length, suspicious: null },
    response.usage,
    startedAt,
  );

  const parsed = response.parsed_output;
  if (!parsed) {
    throw new Error('QuestCheck : réponse du modèle non exploitable');
  }

  // Le modèle peut omettre un critère ou en inventer un : on repart de la liste
  // demandée, ce qui garantit un contrôle par critère et dans l'ordre.
  const byId = new Map(parsed.checks.map((c) => [c.id, c]));
  const checks: QuestCheckItem[] = input.requirements.map((requirement) => {
    const found = byId.get(requirement.id);
    if (!found) {
      return { id: requirement.id, label: requirement.label, passed: false, confidence: 0 };
    }
    return {
      id: requirement.id,
      label: requirement.label,
      passed: found.passed,
      confidence: Math.max(0, Math.min(1, found.confidence)),
    };
  });

  return { checks, summary: parsed.summary, suspicious: parsed.suspicious };
}

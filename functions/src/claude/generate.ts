import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod';

import { CLAUDE_MODEL, XP_REWARDS } from '../config';
import type { QuestCategory, QuestDifficulty, QuestTemplate } from '../types';
import { claude, logUsage } from './client';

/**
 * Génération des quêtes (§13, §78).
 *
 * On ne génère jamais une quête par utilisateur à la connexion (§12) : Claude
 * produit des lots qui alimentent un pool, dans lequel le Quest Engine puise.
 * C'est moins cher, modérable, et surtout cela permet aux amis de recevoir la
 * même quête.
 */

const CATEGORIES = [
  'adventure',
  'photography',
  'creative',
  'food',
  'social',
  'nature',
  'sport',
  'music',
  'gaming',
  'travel',
  'funny',
  'observation',
  'exploration',
] as const;

const RequirementSchema = z.object({
  id: z.string().describe('identifiant court en snake_case, ex: object_red'),
  type: z
    .enum(['object', 'object_color', 'environment', 'time', 'activity', 'scene'])
    .describe('famille de contrôle'),
  value: z.string().describe('valeur attendue, en anglais et au singulier'),
  target: z.string().nullable().describe("objet visé quand le critère porte sur autre chose"),
  label: z.string().describe("libellé court affiché au joueur, dans sa langue"),
  emoji: z.string().describe('un emoji illustrant le critère'),
});

const QuestSchema = z.object({
  title: z.string().describe('titre court et frappant, 2 à 6 mots'),
  description: z.string().describe('une à deux phrases, ton direct, tutoiement'),
  category: z.enum(CATEGORIES),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  estimatedMinutes: z.number().int().min(1).max(120),
  requirements: z
    .array(RequirementSchema)
    .min(1)
    .max(4)
    .describe('critères vérifiables sur une photo, hors contrôles techniques'),
  riskLevel: z.enum(['low', 'medium', 'high']),
  riskNotes: z.string().nullable(),
});

const BatchSchema = z.object({ quests: z.array(QuestSchema) });

export type GeneratedQuest = z.infer<typeof QuestSchema>;

/**
 * Politique de sécurité (§42, §138). Elle est en tête du prompt et mise en
 * cache : elle ne change pas d'un lot à l'autre.
 */
const SYSTEM = `Tu écris les quêtes quotidiennes de QUEST, une application où des amis relèvent chaque jour les mêmes défis dans la vraie vie et en rapportent une photo prise depuis l'application.

Ce qui fait une bonne quête :
- Elle se fait aujourd'hui, là où la personne se trouve déjà.
- Elle se vérifie sur une photo, sans ambiguïté.
- Elle laisse de la place à l'interprétation : deux amis doivent pouvoir y répondre très différemment. C'est de cette différence que naît l'intérêt du jeu.
- Elle donne envie de sortir, de regarder autour de soi, de faire un détour.
- Elle est écrite en tutoiement, avec un ton amical et joueur, sans être puéril.

Difficultés :
- easy : 1 à 5 minutes, faisable sans bouger ou presque.
- medium : 5 à 30 minutes, demande un petit effort ou un déplacement.
- hard : 15 à 90 minutes, une vraie sortie, un moment à aller chercher.

Interdits absolus, sans exception :
- conduite dangereuse, vitesse, usage du téléphone en conduisant
- intrusion, propriété privée, lieux interdits ou abandonnés
- automutilation, comportement à risque, cascades, hauteur, eau profonde
- violence, harcèlement, humiliation d'autrui, photographier quelqu'un sans son accord
- activité illégale, substances
- animaux dangereux ou sauvages approchés
- toute quête qui exige un achat, une voiture, un objet coûteux, ou d'aborder des inconnus

Une quête accessible n'exige jamais de courir, de marcher longtemps ni de sortir : le lot doit mélanger intérieur, extérieur, observation, création et social.

Tu réponds uniquement dans la structure demandée.`;

export interface GenerateInput {
  difficulty: QuestDifficulty;
  count: number;
  /** Titres récemment utilisés, pour éviter de tourner en rond (§79). */
  avoidTitles: string[];
  /** Saison de l'hémisphère visé, pour rester plausible. */
  season: string;
  categoryMix: QuestCategory[];
  locale: string;
}

export async function generateQuests(input: GenerateInput): Promise<GeneratedQuest[]> {
  const startedAt = Date.now();

  const response = await claude().messages.parse({
    model: CLAUDE_MODEL,
    max_tokens: 8000,
    system: [{ type: 'text', text: SYSTEM, cache_control: { type: 'ephemeral' } }],
    thinking: { type: 'adaptive' },
    output_config: { effort: 'high', format: zodOutputFormat(BatchSchema) },
    messages: [
      {
        role: 'user',
        content: `Écris ${input.count} quêtes de difficulté "${input.difficulty}".

Langue : ${input.locale}
Saison : ${input.season}
Catégories à couvrir, sans toutes les épuiser : ${input.categoryMix.join(', ')}

Ne reprends ni ces titres ni leur idée :
${input.avoidTitles.map((t) => `- ${t}`).join('\n') || '- (aucun)'}

Varie les formes : observation, création, déplacement, rencontre, nourriture, lumière, son. Évite que deux quêtes du lot se ressemblent.`,
      },
    ],
  });

  logUsage(
    'generate_quests',
    { difficulty: input.difficulty, count: input.count },
    response.usage,
    startedAt,
  );

  const parsed = response.parsed_output;
  if (!parsed) throw new Error('Génération : réponse non exploitable');

  return parsed.quests;
}

/** Convertit une quête générée en modèle Firestore. */
export function toTemplate(
  quest: GeneratedQuest,
  source: QuestTemplate['source'],
): Omit<QuestTemplate, 'id' | 'createdAt' | 'lastUsedAt'> {
  return {
    title: quest.title,
    description: quest.description,
    category: quest.category,
    difficulty: quest.difficulty,
    estimatedMinutes: quest.estimatedMinutes,
    proofType: 'photo',
    galleryAllowed: false,
    xpReward: XP_REWARDS[quest.difficulty] ?? 50,
    requirements: [
      { id: 'photo', type: 'technical', value: 'in_app', label: 'Photo', emoji: '📷' },
      ...quest.requirements.map((r) => ({
        id: r.id,
        type: r.type,
        value: r.value,
        ...(r.target ? { target: r.target } : {}),
        label: r.label,
        emoji: r.emoji,
      })),
    ],
    safety: {
      riskLevel: quest.riskLevel,
      ...(quest.riskNotes ? { notes: quest.riskNotes } : {}),
    },
    source,
    status: quest.riskLevel === 'low' ? 'draft' : 'rejected',
    usageCount: 0,
    normalizedTitle: normalizeTitle(quest.title),
  };
}

/** Normalisation utilisée pour la détection de doublons (§79). */
export function normalizeTitle(title: string): string {
  return title
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((word) => word.length > 2 && !STOP_WORDS.has(word))
    .sort()
    .join(' ');
}

const STOP_WORDS = new Set([
  'the', 'and', 'for', 'que', 'qui', 'une', 'des', 'les', 'ton', 'ta', 'tes',
  'dans', 'avec', 'sur', 'plus', 'tout', 'toute', 'trouve', 'find', 'your',
]);

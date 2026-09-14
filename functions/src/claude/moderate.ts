import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod';

import { CLAUDE_MODEL } from '../config';
import { claude, logUsage } from './client';

/**
 * Modération et analyse des quêtes écrites par les joueurs (§42, §44).
 *
 * Une consigne libre passe ici avant d'atteindre qui que ce soit : le texte est
 * jugé sûr ou non, puis transformé en critères vérifiables.
 */

const ParseSchema = z.object({
  safe: z.boolean().describe('faux si la consigne enfreint la politique'),
  rejectionReason: z
    .string()
    .nullable()
    .describe('si refusée, une phrase courte et compréhensible pour le joueur'),
  category: z.enum([
    'adventure', 'photography', 'creative', 'food', 'social', 'nature',
    'sport', 'music', 'gaming', 'travel', 'funny', 'observation', 'exploration',
  ]),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  estimatedMinutes: z.number().int().min(1).max(120),
  requirements: z.array(
    z.object({
      id: z.string(),
      type: z.enum(['object', 'object_color', 'environment', 'time', 'activity', 'scene']),
      value: z.string(),
      target: z.string().nullable(),
      label: z.string(),
      emoji: z.string(),
    }),
  ).min(1).max(4),
});

export type ParsedQuest = z.infer<typeof ParseSchema>;

const SYSTEM = `Tu analyses les défis que les joueurs de QUEST s'envoient entre amis.

Deux tâches :
1. Décider si la consigne est acceptable.
2. Si elle l'est, la traduire en critères vérifiables sur une photo.

Refuse, en expliquant simplement : conduite dangereuse, intrusion, automutilation, cascades, violence, harcèlement, humiliation, nudité, activité illégale, animaux dangereux, photographier une personne sans son accord, ou toute consigne qui exige un achat ou d'aborder des inconnus.

Une consigne moqueuse entre amis reste acceptable tant qu'elle ne vise pas à humilier une personne réelle identifiable.

Si la consigne est trop vague pour être vérifiée sur une photo, retiens le critère le plus proche de l'intention plutôt que de la refuser.`;

export async function parseUserQuest(text: string, locale: string): Promise<ParsedQuest> {
  const startedAt = Date.now();

  const response = await claude().messages.parse({
    model: CLAUDE_MODEL,
    max_tokens: 1500,
    system: [{ type: 'text', text: SYSTEM, cache_control: { type: 'ephemeral' } }],
    thinking: { type: 'adaptive' },
    output_config: { effort: 'low', format: zodOutputFormat(ParseSchema) },
    messages: [
      {
        role: 'user',
        content: `Consigne écrite par un joueur : "${text}"

Rédige les libellés des critères et l'éventuel refus en ${locale}.`,
      },
    ],
  });

  logUsage('parse_user_quest', { length: text.length }, response.usage, startedAt);

  const parsed = response.parsed_output;
  if (!parsed) throw new Error('Analyse de consigne : réponse non exploitable');
  return parsed;
}

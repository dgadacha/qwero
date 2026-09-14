import Anthropic from '@anthropic-ai/sdk';

let cached: Anthropic | null = null;

/**
 * Client Claude partagé entre les invocations chaudes.
 *
 * La clé est un secret de déploiement : elle n'est jamais lue côté client, et
 * Flutter n'appelle jamais Claude directement (§7).
 */
export function claude(): Anthropic {
  if (cached) return cached;
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error(
      'ANTHROPIC_API_KEY absent : déclarer le secret avant de déployer les fonctions IA.',
    );
  }
  cached = new Anthropic({ apiKey, maxRetries: 2, timeout: 60_000 });
  return cached;
}

/** Journalisation utile sans contenu personnel (§156). */
export function logUsage(
  kind: string,
  meta: Record<string, string | number | boolean | null>,
  usage: { input_tokens: number; output_tokens: number } | undefined,
  startedAt: number,
): void {
  console.log(
    JSON.stringify({
      claudeCall: kind,
      ...meta,
      inputTokens: usage?.input_tokens ?? null,
      outputTokens: usage?.output_tokens ?? null,
      latencyMs: Date.now() - startedAt,
    }),
  );
}

import { createHash } from 'node:crypto';
import sharp from 'sharp';

/**
 * Préparation de la preuve avant analyse (§158, §159).
 *
 * Deux objectifs : ne pas envoyer une photo de 48 Mpx au modèle, et reconnaître
 * une image déjà soumise même ré-encodée.
 */

export interface PreparedProof {
  base64: string;
  mediaType: 'image/jpeg';
  width: number;
  height: number;
  /** Empreinte perceptuelle, pour la détection de doublons. */
  perceptualHash: string;
  /** Empreinte exacte, pour le cache d'analyse. */
  exactHash: string;
}

/**
 * dHash : l'image est ramenée à 9x8 en niveaux de gris, puis chaque pixel est
 * comparé à son voisin de droite. Le résultat survit au recadrage léger, au
 * changement de compression et au redimensionnement, ce qu'un hash
 * cryptographique ne ferait pas.
 */
async function differenceHash(input: Buffer): Promise<string> {
  const { data } = await sharp(input)
    .greyscale()
    .resize(9, 8, { fit: 'fill' })
    .raw()
    .toBuffer({ resolveWithObject: true });

  let bits = '';
  for (let row = 0; row < 8; row++) {
    for (let col = 0; col < 8; col++) {
      const left = data[row * 9 + col] ?? 0;
      const right = data[row * 9 + col + 1] ?? 0;
      bits += left > right ? '1' : '0';
    }
  }

  let hex = '';
  for (let i = 0; i < 64; i += 4) {
    hex += parseInt(bits.slice(i, i + 4), 2).toString(16);
  }
  return hex;
}

/** Distance de Hamming entre deux empreintes, en bits différents. */
export function hammingDistance(a: string, b: string): number {
  if (a.length !== b.length) return Number.MAX_SAFE_INTEGER;
  let distance = 0;
  for (let i = 0; i < a.length; i++) {
    const diff = parseInt(a[i]!, 16) ^ parseInt(b[i]!, 16);
    distance += (diff & 1) + ((diff >> 1) & 1) + ((diff >> 2) & 1) + ((diff >> 3) & 1);
  }
  return distance;
}

/** Deux preuves sont considérées identiques en deçà de ce seuil. */
export const DUPLICATE_THRESHOLD = 6;

export async function prepareProof(input: Buffer): Promise<PreparedProof> {
  const image = sharp(input, { failOn: 'error' });
  const metadata = await image.metadata();

  // 1024 px de côté long suffisent largement à juger le contenu (§159).
  const resized = await sharp(input)
    .rotate()
    .resize(1024, 1024, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 82 })
    .toBuffer();

  const [perceptualHash] = await Promise.all([differenceHash(resized)]);

  return {
    base64: resized.toString('base64'),
    mediaType: 'image/jpeg',
    width: metadata.width ?? 0,
    height: metadata.height ?? 0,
    perceptualHash,
    exactHash: createHash('sha256').update(resized).digest('hex'),
  };
}

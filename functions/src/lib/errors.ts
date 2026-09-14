import { HttpsError } from 'firebase-functions/v2/https';

/** Erreurs renvoyées au client, sans détail interne. */
export const errors = {
  unauthenticated: () => new HttpsError('unauthenticated', 'Connexion requise.'),
  notFound: (what: string) => new HttpsError('not-found', `${what} introuvable.`),
  permission: (why = 'Action non autorisée.') => new HttpsError('permission-denied', why),
  invalid: (why: string) => new HttpsError('invalid-argument', why),
  exhausted: (why: string) => new HttpsError('resource-exhausted', why),
  failed: (why: string) => new HttpsError('failed-precondition', why),
  internal: (why = 'Une erreur est survenue.') => new HttpsError('internal', why),
};

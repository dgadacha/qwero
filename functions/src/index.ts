import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp();
export const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

export * from './functions/account';
export * from './functions/completions';
export * from './functions/challenges';
export * from './functions/engagement';
export * from './functions/scheduler';
export * from './functions/social';

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

/**
 * Vérification des règles Firestore (§153).
 *
 * Ces tests décrivent ce qu'un client mal intentionné ne doit pas pouvoir
 * faire. Ils tournent contre l'émulateur, sans projet Firebase réel.
 */

let env: RulesTestEnvironment;

const ALICE = 'user_alice';
const BOB = 'user_bob';
const MALLORY = 'user_mallory';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'quest-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', ALICE), {
      username: 'alice',
      displayName: 'Alice',
      level: 14,
      xp: 1840,
      streak: 12,
      questsCompleted: 428,
      interests: [],
      timezone: 'Pacific/Noumea',
    });
    await setDoc(doc(db, 'users', BOB), {
      username: 'bob',
      displayName: 'Bob',
      level: 3,
      xp: 10,
      streak: 1,
      questsCompleted: 4,
    });
    // Alice et Bob sont amis, dans les deux sens.
    await setDoc(doc(db, 'friendships', `${ALICE}_${BOB}`), { userId: ALICE, friendId: BOB });
    await setDoc(doc(db, 'friendships', `${BOB}_${ALICE}`), { userId: BOB, friendId: ALICE });

    await setDoc(doc(db, 'questTemplates', 'q_hard'), {
      title: 'Chase le coucher de soleil',
      status: 'approved',
      difficulty: 'hard',
      xpReward: 400,
    });
    await setDoc(doc(db, 'questTemplates', 'q_draft'), {
      title: 'Brouillon',
      status: 'draft',
      difficulty: 'easy',
    });

    await setDoc(doc(db, 'questCompletions', 'c_alice'), {
      userId: ALICE,
      questId: 'q_hard',
      proofPath: `completions/${ALICE}/c_alice`,
      status: 'validated',
      xpAwarded: 400,
      validationScore: 0.97,
      visibility: 'friends',
      caption: 'Beau spot',
    });
  });
});

function as(uid: string) {
  return env.authenticatedContext(uid).firestore();
}

function anon() {
  return env.unauthenticatedContext().firestore();
}

describe('profils', () => {
  it('un joueur lit son propre profil', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'users', ALICE)));
  });

  it('un ami lit le profil', async () => {
    await assertSucceeds(getDoc(doc(as(BOB), 'users', ALICE)));
  });

  it("un inconnu ne lit pas le profil", async () => {
    await assertFails(getDoc(doc(as(MALLORY), 'users', ALICE)));
  });

  it('un anonyme ne lit rien', async () => {
    await assertFails(getDoc(doc(anon(), 'users', ALICE)));
  });

  it('un joueur modifie ses préférences', async () => {
    await assertSucceeds(
      updateDoc(doc(as(ALICE), 'users', ALICE), { displayName: 'Alice B.' }),
    );
  });

  it("un joueur ne s'attribue pas d'XP", async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'users', ALICE), { xp: 999999 }));
  });

  it('un joueur ne se donne pas de niveau', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'users', ALICE), { level: 99 }));
  });

  it('un joueur ne gonfle pas son streak', async () => {
    await assertFails(updateDoc(doc(as(ALICE), 'users', ALICE), { streak: 365 }));
  });

  it('un joueur ne modifie pas le profil d\'un autre', async () => {
    await assertFails(
      updateDoc(doc(as(MALLORY), 'users', ALICE), { displayName: 'Piraté' }),
    );
  });

  it("le journal d'XP est en lecture seule", async () => {
    await assertFails(
      setDoc(doc(as(ALICE), 'users', ALICE, 'xpEvents', 'forged'), { amount: 10000 }),
    );
  });
});

describe('catalogue de quêtes', () => {
  it('une quête approuvée est lisible', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'questTemplates', 'q_hard')));
  });

  it("un brouillon n'est pas lisible", async () => {
    await assertFails(getDoc(doc(as(ALICE), 'questTemplates', 'q_draft')));
  });

  it('un joueur ne crée pas de quête directement', async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'questTemplates', 'q_forged'), {
        title: 'XP facile',
        status: 'approved',
        xpReward: 100000,
      }),
    );
  });

  it("un joueur n'écrit pas le set du jour", async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'dailyQuestSets', '2026-09-15-pacific-0'), {
        status: 'published',
      }),
    );
  });
});

describe('participations', () => {
  it('un joueur crée sa participation en attente', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), 'questCompletions', 'c_bob'), {
        userId: BOB,
        questId: 'q_hard',
        proofPath: `completions/${BOB}/c_bob`,
        status: 'pending_validation',
        xpAwarded: 0,
        validationScore: 0,
        visibility: 'friends',
      }),
    );
  });

  it('un joueur ne crée pas une participation déjà validée', async () => {
    await assertFails(
      setDoc(doc(as(BOB), 'questCompletions', 'c_cheat'), {
        userId: BOB,
        questId: 'q_hard',
        proofPath: `completions/${BOB}/c_cheat`,
        status: 'validated',
        xpAwarded: 400,
        validationScore: 1,
        visibility: 'friends',
      }),
    );
  });

  it("un joueur ne s'attribue pas d'XP à la création", async () => {
    await assertFails(
      setDoc(doc(as(BOB), 'questCompletions', 'c_cheat2'), {
        userId: BOB,
        questId: 'q_hard',
        proofPath: `completions/${BOB}/c_cheat2`,
        status: 'pending_validation',
        xpAwarded: 400,
        validationScore: 0,
        visibility: 'friends',
      }),
    );
  });

  it("un joueur ne crée pas de participation au nom d'un autre", async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'questCompletions', 'c_usurped'), {
        userId: ALICE,
        questId: 'q_hard',
        proofPath: `completions/${ALICE}/x`,
        status: 'pending_validation',
        xpAwarded: 0,
        validationScore: 0,
        visibility: 'friends',
      }),
    );
  });

  it('un ami lit une participation partagée aux amis', async () => {
    await assertSucceeds(getDoc(doc(as(BOB), 'questCompletions', 'c_alice')));
  });

  it("un inconnu ne lit pas une participation entre amis", async () => {
    await assertFails(getDoc(doc(as(MALLORY), 'questCompletions', 'c_alice')));
  });

  it("l'auteur change sa légende", async () => {
    await assertSucceeds(
      updateDoc(doc(as(ALICE), 'questCompletions', 'c_alice'), { caption: 'Autre chose' }),
    );
  });

  it("l'auteur ne repasse pas son score à la main", async () => {
    await assertFails(
      updateDoc(doc(as(ALICE), 'questCompletions', 'c_alice'), { validationScore: 1 }),
    );
  });

  it('un tiers ne valide pas une participation', async () => {
    await assertFails(
      updateDoc(doc(as(MALLORY), 'questCompletions', 'c_alice'), { status: 'validated' }),
    );
  });

  it("l'auteur supprime sa participation", async () => {
    await assertSucceeds(deleteDoc(doc(as(ALICE), 'questCompletions', 'c_alice')));
  });

  it('un tiers ne supprime pas la participation', async () => {
    await assertFails(deleteDoc(doc(as(MALLORY), 'questCompletions', 'c_alice')));
  });
});

describe('réactions et commentaires', () => {
  it('une réaction porte son propre identifiant', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), 'questCompletions', 'c_alice', 'reactions', `${BOB}_f09f94a5`), {
        userId: BOB,
        emoji: '🔥',
      }),
    );
  });

  it("on ne réagit pas au nom de quelqu'un d'autre", async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'questCompletions', 'c_alice', 'reactions', `${BOB}_f09f94a5`), {
        userId: BOB,
        emoji: '🔥',
      }),
    );
  });

  it('une réaction ne se modifie pas', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'questCompletions', 'c_alice', 'reactions', `${BOB}_x`),
        { userId: BOB, emoji: '👏' },
      );
    });
    await assertFails(
      updateDoc(doc(as(BOB), 'questCompletions', 'c_alice', 'reactions', `${BOB}_x`), {
        emoji: '❤️',
      }),
    );
  });

  it('un commentaire vide est refusé', async () => {
    await assertFails(
      setDoc(doc(as(BOB), 'questCompletions', 'c_alice', 'comments', 'cm1'), {
        authorId: BOB,
        text: '',
      }),
    );
  });

  it('un commentaire trop long est refusé', async () => {
    await assertFails(
      setDoc(doc(as(BOB), 'questCompletions', 'c_alice', 'comments', 'cm2'), {
        authorId: BOB,
        text: 'x'.repeat(501),
      }),
    );
  });

  it("un commentaire signé d'un autre est refusé", async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'questCompletions', 'c_alice', 'comments', 'cm3'), {
        authorId: BOB,
        text: 'Pas moi',
      }),
    );
  });
});

describe('challenges et amitiés', () => {
  it('un joueur ne crée pas un challenge directement', async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'challenges', 'ch_forged'), {
        fromId: MALLORY,
        toId: ALICE,
        questId: 'q_hard',
        state: 'pending',
      }),
    );
  });

  it('un joueur ne se déclare pas ami avec quelqu\'un', async () => {
    await assertFails(
      setDoc(doc(as(MALLORY), 'friendships', `${MALLORY}_${ALICE}`), {
        userId: MALLORY,
        friendId: ALICE,
      }),
    );
  });

  it('un joueur lit ses propres amitiés', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), 'friendships', `${ALICE}_${BOB}`)));
  });

  it("un joueur ne lit pas les amitiés des autres", async () => {
    await assertFails(getDoc(doc(as(MALLORY), 'friendships', `${ALICE}_${BOB}`)));
  });
});

describe('signalements', () => {
  it('un joueur signale un contenu', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), 'reports', 'r1'), {
        reporterId: BOB,
        targetId: 'c_alice',
        reason: 'spam',
      }),
    );
  });

  it('un signalement ne se relit pas', async () => {
    await assertFails(getDoc(doc(as(BOB), 'reports', 'r1')));
  });
});

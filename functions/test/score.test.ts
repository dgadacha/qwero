import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { normalizeTitle } from '../src/claude/generate';
import { hammingDistance } from '../src/lib/image';
import { localDate, updateStreak } from '../src/game/streak';
import { xpForLevel } from '../src/config';
import type { UserDoc } from '../src/types';

function user(overrides: Partial<UserDoc> = {}): UserDoc {
  return {
    username: 'dylan',
    usernameLower: 'dylan',
    displayName: 'Dylan',
    avatarUrl: null,
    level: 1,
    xp: 0,
    streak: 0,
    questsCompleted: 0,
    lastCompletionDate: null,
    timezone: 'Pacific/Noumea',
    locale: 'fr',
    interests: [],
    visibility: 'friends',
    worldQuestOptIn: false,
    cohortId: 'pacific-0',
    fcmTokens: [],
    notificationPrefs: { dailyQuests: true, friendActivity: true, challenges: true },
    createdAt: null as never,
    ...overrides,
  };
}

describe('streak', () => {
  it('démarre à un à la première quête', () => {
    const result = updateStreak(user(), new Date('2026-09-15T02:00:00Z'));
    assert.equal(result.streak, 1);
    assert.equal(result.changed, true);
  });

  it("n'avance qu'une fois par jour", () => {
    const today = localDate(new Date('2026-09-15T02:00:00Z'), 'Pacific/Noumea');
    const result = updateStreak(
      user({ streak: 12, lastCompletionDate: today }),
      new Date('2026-09-15T08:00:00Z'),
    );
    assert.equal(result.streak, 12);
    assert.equal(result.changed, false);
  });

  it('continue après une journée consécutive', () => {
    const result = updateStreak(
      user({ streak: 12, lastCompletionDate: '2026-09-14' }),
      new Date('2026-09-15T02:00:00Z'),
    );
    assert.equal(result.streak, 13);
  });

  it('repart de un après un jour sauté', () => {
    const result = updateStreak(
      user({ streak: 12, lastCompletionDate: '2026-09-10' }),
      new Date('2026-09-15T02:00:00Z'),
    );
    assert.equal(result.streak, 1);
  });

  it('respecte le fuseau du joueur', () => {
    // 2026-09-15 12:00 UTC est déjà le 15 à Nouméa (UTC+11) et encore le 15 à Paris.
    assert.equal(localDate(new Date('2026-09-15T12:00:00Z'), 'Pacific/Noumea'), '2026-09-15');
    // 2026-09-14 22:00 UTC est déjà le 15 à Nouméa mais encore le 15 à Paris (UTC+2).
    assert.equal(localDate(new Date('2026-09-14T22:00:00Z'), 'Pacific/Noumea'), '2026-09-15');
    assert.equal(localDate(new Date('2026-09-14T22:00:00Z'), 'Europe/Paris'), '2026-09-15');
  });

  it('retombe sur UTC pour un fuseau inconnu', () => {
    assert.equal(localDate(new Date('2026-09-15T12:00:00Z'), 'Mars/Olympus'), '2026-09-15');
  });
});

describe('courbe XP', () => {
  it('correspond à la formule du cahier des charges', () => {
    assert.equal(xpForLevel(1), 100);
    assert.equal(xpForLevel(14), 3526);
  });

  it('croît strictement', () => {
    for (let level = 1; level < 60; level++) {
      assert.ok(xpForLevel(level + 1) > xpForLevel(level));
    }
  });
});

describe('détection de doublons', () => {
  it('donne zéro pour deux empreintes identiques', () => {
    assert.equal(hammingDistance('f0f0f0f0f0f0f0f0', 'f0f0f0f0f0f0f0f0'), 0);
  });

  it('compte les bits différents', () => {
    assert.equal(hammingDistance('0000000000000000', '0000000000000001'), 1);
    assert.equal(hammingDistance('0000000000000000', '000000000000000f'), 4);
  });

  it('écarte des longueurs différentes', () => {
    assert.ok(hammingDistance('f0f0', 'f0f0f0f0') > 64);
  });
});

describe('normalisation des titres', () => {
  it('ignore casse, accents et ponctuation', () => {
    assert.equal(
      normalizeTitle('Trouve quelque chose de ROUGE !'),
      normalizeTitle('trouve  quelque chose de rouge'),
    );
  });

  it("rapproche deux formulations du même défi", () => {
    assert.equal(
      normalizeTitle('Chase le coucher de soleil'),
      normalizeTitle('Le coucher de soleil, chase-le'),
    );
  });

  it('distingue deux défis différents', () => {
    assert.notEqual(normalizeTitle('Trouve un arbre'), normalizeTitle('Trouve un reflet'));
  });
});

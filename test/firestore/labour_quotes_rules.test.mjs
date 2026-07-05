import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { before, after, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = resolve(__dirname, '../../firebaserules.txt');
const rules = readFileSync(rulesPath, 'utf8');
const projectId = 'roofgrid-labour-rules-test';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

async function seedUser(userId, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`users/${userId}`).set(data);
  });
}

function quotesRef(userId, quoteId) {
  return testEnv
    .authenticatedContext(userId)
    .firestore()
    .doc(`users/${userId}/labour_quotes/${quoteId}`);
}

describe('labour_quotes Firestore rules', () => {
  it('allows owner with labour add-on to read and write', async () => {
    const userId = 'labour-user';
    await seedUser(userId, {
      role: 'pro',
      labourCalculatorActive: true,
    });

    await assertSucceeds(
      quotesRef(userId, 'quote-1').set({
        id: 'quote-1',
        name: 'Test quote',
        savedAt: new Date().toISOString(),
      }),
    );
    await assertSucceeds(quotesRef(userId, 'quote-1').get());
    await assertSucceeds(quotesRef(userId, 'quote-1').delete());
  });

  it('denies owner without labour add-on', async () => {
    const userId = 'free-user';
    await seedUser(userId, {
      role: 'pro',
      labourCalculatorActive: false,
    });

    await assertFails(
      quotesRef(userId, 'quote-2').set({
        id: 'quote-2',
        name: 'Blocked',
        savedAt: new Date().toISOString(),
      }),
    );
    await assertFails(quotesRef(userId, 'quote-2').get());
  });

  it('denies cross-user access', async () => {
    const ownerId = 'owner-user';
    const otherId = 'other-user';
    await seedUser(ownerId, {
      role: 'pro',
      labourCalculatorActive: true,
    });
    await seedUser(otherId, {
      role: 'pro',
      labourCalculatorActive: true,
    });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`users/${ownerId}/labour_quotes/quote-3`)
        .set({ id: 'quote-3', name: 'Owner quote' });
    });

    const otherReadsOwner = testEnv
      .authenticatedContext(otherId)
      .firestore()
      .doc(`users/${ownerId}/labour_quotes/quote-3`);

    await assertFails(otherReadsOwner.get());
    await assertFails(
      otherReadsOwner.set({
        id: 'quote-3',
        name: 'Hijack',
      }),
    );
  });
});
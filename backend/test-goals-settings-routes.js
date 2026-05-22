#!/usr/bin/env node
/**
 * Manual API route tester for goals and settings.
 * Requires the backend server to be running (npm run dev / npm start).
 *
 * Usage:
 *   node test-goals-settings-routes.js
 *   API_BASE_URL=http://127.0.0.1:3000 node test-goals-settings-routes.js
 */

const crypto = require('crypto');

const BASE_URL = (process.env.API_BASE_URL || 'http://127.0.0.1:3000').replace(
  /\/$/,
  ''
);
const API_PREFIX = '/api/v1';

const PASSWORD = 'TestPass1';

let accessToken = null;
let goalId = null;
let accountId = null;

const results = { passed: 0, failed: 0, tests: [] };

function futureDueDate() {
  const date = new Date();
  date.setMonth(date.getMonth() + 3);
  return date.toISOString().slice(0, 10);
}

function uniqueEmail() {
  return `apitest-${Date.now()}-${crypto.randomBytes(4).toString('hex')}@example.com`;
}

function uniqueName(prefix) {
  return `${prefix}-${Date.now()}`;
}

async function api(method, path, { body, query, auth = true } = {}) {
  const url = new URL(`${BASE_URL}${API_PREFIX}${path}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      url.searchParams.set(key, value);
    }
  }

  const headers = { 'Content-Type': 'application/json' };
  if (auth && accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }

  const options = { method, headers };
  if (body !== undefined) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(url, options);
  let payload = null;
  try {
    payload = await response.json();
  } catch {
    payload = null;
  }

  return { status: response.status, payload };
}

function record(name, ok, detail = '') {
  results.tests.push({ name, ok, detail });
  if (ok) {
    results.passed += 1;
    console.log(`  ✓ ${name}`);
  } else {
    results.failed += 1;
    console.log(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

function assertSuccess(name, { status, payload }, expectedStatus) {
  const ok =
    status === expectedStatus &&
    payload &&
    payload.success === true;
  const detail = ok
    ? ''
    : `expected ${expectedStatus}, got ${status}${
        payload?.error?.code ? ` (${payload.error.code})` : ''
      }${payload?.error?.message ? `: ${payload.error.message}` : ''}`;
  record(name, ok, detail);
  return ok;
}

async function authenticate() {
  const email = uniqueEmail();
  const registerBody = {
    firstName: 'Api',
    lastName: 'Tester',
    email,
    password: PASSWORD,
    confirmPassword: PASSWORD,
    university: 'Test University',
    department: 'Computer Science',
    termsAccepted: 'true',
  };

  console.log('\nAuth');
  console.log(`  Registering ${email}`);

  const registerRes = await api('POST', '/auth/register', {
    body: registerBody,
    auth: false,
  });

  if (registerRes.status === 201 && registerRes.payload?.data?.tokens?.accessToken) {
    accessToken = registerRes.payload.data.tokens.accessToken;
    record('POST /auth/register', true);
    return;
  }

  if (registerRes.status === 409) {
    record('POST /auth/register', false, 'email conflict on fresh address');
  } else {
    record('POST /auth/register', false);
  }

  console.log('  Falling back to login');
  const loginRes = await api('POST', '/auth/login', {
    body: { email, password: PASSWORD },
    auth: false,
  });

  if (
    loginRes.status === 200 &&
    loginRes.payload?.data?.tokens?.accessToken
  ) {
    accessToken = loginRes.payload.data.tokens.accessToken;
    record('POST /auth/login', true);
    return;
  }

  record('POST /auth/login', false);
  throw new Error('Could not obtain access token via register or login');
}

async function testSettingsRoutes() {
  console.log('\nSettings routes (/api/v1/settings)');

  let res = await api('GET', '/settings/accounts');
  assertSuccess('GET /settings/accounts', res, 200);

  const accountName = uniqueName('Test Account');
  res = await api('POST', '/settings/accounts', {
    body: { name: accountName, type: 'bank' },
  });
  if (assertSuccess('POST /settings/accounts', res, 201)) {
    accountId = res.payload.data.id;
  }

  res = await api('GET', '/settings/allowance');
  assertSuccess('GET /settings/allowance', res, 200);

  res = await api('PUT', '/settings/allowance', {
    body: { monthlyAmount: 5000, cycleStartDay: 1 },
  });
  assertSuccess('PUT /settings/allowance', res, 200);

  res = await api('GET', '/settings/preferences');
  assertSuccess('GET /settings/preferences', res, 200);

  res = await api('PATCH', '/settings/preferences', {
    body: { preferredLanguage: 'English', themeMode: 'dark' },
  });
  assertSuccess('PATCH /settings/preferences', res, 200);

  if (accountId) {
    res = await api('DELETE', `/settings/accounts/${accountId}`);
    assertSuccess('DELETE /settings/accounts/:accountId', res, 200);
    accountId = null;
  } else {
    record('DELETE /settings/accounts/:accountId', false, 'no accountId from create');
  }
}

async function testGoalRoutes() {
  console.log('\nGoal routes (/api/v1/goals)');

  let res = await api('GET', '/goals');
  assertSuccess('GET /goals', res, 200);

  res = await api('GET', '/goals', { query: { status: 'active' } });
  assertSuccess('GET /goals?status=active', res, 200);

  res = await api('POST', '/goals', {
    body: {
      title: uniqueName('Savings Goal'),
      period: 'monthly',
      targetAmount: 1000,
      currentAmount: 0,
      dueDate: futureDueDate(),
      note: 'Created by API route test script',
    },
  });
  if (assertSuccess('POST /goals', res, 201)) {
    goalId = res.payload.data.id;
  }

  if (!goalId) {
    record('GET /goals/:goalId', false, 'skipped — no goalId');
    record('PATCH /goals/:goalId', false, 'skipped — no goalId');
    record('PATCH /goals/:goalId/lock', false, 'skipped — no goalId');
    record('POST /goals/:goalId/deposits', false, 'skipped — no goalId');
    record('GET /goals/:goalId/deposits', false, 'skipped — no goalId');
    record('DELETE /goals/:goalId', false, 'skipped — no goalId');
    return;
  }

  res = await api('GET', `/goals/${goalId}`);
  assertSuccess('GET /goals/:goalId', res, 200);

  res = await api('PATCH', `/goals/${goalId}`, {
    body: { title: uniqueName('Updated Goal'), note: 'Updated by test script' },
  });
  assertSuccess('PATCH /goals/:goalId', res, 200);

  res = await api('POST', `/goals/${goalId}/deposits`, {
    body: { amount: 100, source: 'manual savings' },
  });
  assertSuccess('POST /goals/:goalId/deposits', res, 201);

  res = await api('GET', `/goals/${goalId}/deposits`);
  assertSuccess('GET /goals/:goalId/deposits', res, 200);

  res = await api('PATCH', `/goals/${goalId}/lock`, {
    body: { isLocked: true },
  });
  assertSuccess('PATCH /goals/:goalId/lock', res, 200);

  res = await api('DELETE', `/goals/${goalId}`);
  assertSuccess('DELETE /goals/:goalId', res, 200);
  goalId = null;
}

async function checkServer() {
  try {
    const res = await fetch(`${BASE_URL}${API_PREFIX}/health`);
    if (!res.ok) {
      throw new Error(`health returned ${res.status}`);
    }
    const payload = await res.json();
    if (!payload?.success) {
      throw new Error('health response missing success flag');
    }
    return true;
  } catch (err) {
    console.error(`\nCannot reach API at ${BASE_URL}`);
    console.error(`Start the server first: cd backend && npm run dev`);
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
}

async function main() {
  console.log(`Kise API route tester`);
  console.log(`Base URL: ${BASE_URL}`);

  await checkServer();
  await authenticate();
  await testSettingsRoutes();
  await testGoalRoutes();

  console.log('\nSummary');
  console.log(`  Passed: ${results.passed}`);
  console.log(`  Failed: ${results.failed}`);

  if (results.failed > 0) {
    console.log('\nFailed tests:');
    for (const t of results.tests.filter((x) => !x.ok)) {
      console.log(`  - ${t.name}${t.detail ? `: ${t.detail}` : ''}`);
    }
    process.exit(1);
  }

  console.log('\nAll routes passed.');
}

main().catch((err) => {
  console.error('\nFatal error:', err.message);
  process.exit(1);
});

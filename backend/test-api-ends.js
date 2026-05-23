#!/usr/bin/env node
/**
 * Manual API route tester for all mounted /api/v1 endpoints.
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
let refreshToken = null;
let registeredEmail = null;

let goalId = null;
let debtId = null;
let transactionId = null;
let accountId = null;

const results = { passed: 0, failed: 0, skipped: 0, tests: [] };

function futureDueDate() {
  const date = new Date();
  date.setMonth(date.getMonth() + 3);
  return date.toISOString().slice(0, 10);
}

function todayDate() {
  return new Date().toISOString().slice(0, 10);
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
  results.tests.push({ name, ok, detail, skipped: false });
  if (ok) {
    results.passed += 1;
    console.log(`  ✓ ${name}`);
  } else {
    results.failed += 1;
    console.log(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

function recordSkipped(name, detail = '') {
  results.tests.push({ name, ok: null, detail, skipped: true });
  results.skipped += 1;
  console.log(`  ○ ${name} (skipped${detail ? ` — ${detail}` : ''})`);
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

function storeTokens(tokens) {
  if (tokens?.accessToken) {
    accessToken = tokens.accessToken;
  }
  if (tokens?.refreshToken) {
    refreshToken = tokens.refreshToken;
  }
}

async function authenticate() {
  registeredEmail = uniqueEmail();
  const registerBody = {
    firstName: 'Api',
    lastName: 'Tester',
    email: registeredEmail,
    password: PASSWORD,
    confirmPassword: PASSWORD,
    university: 'Test University',
    department: 'Computer Science',
    termsAccepted: 'true',
  };

  console.log('\nAuth');
  console.log(`  Registering ${registeredEmail}`);

  const registerRes = await api('POST', '/auth/register', {
    body: registerBody,
    auth: false,
  });

  if (registerRes.status === 201 && registerRes.payload?.data?.tokens) {
    storeTokens(registerRes.payload.data.tokens);
    record('POST /auth/register', true);
    return;
  }

  record('POST /auth/register', false);

  console.log('  Falling back to login');
  const loginRes = await api('POST', '/auth/login', {
    body: { email: registeredEmail, password: PASSWORD },
    auth: false,
  });

  if (loginRes.status === 200 && loginRes.payload?.data?.tokens) {
    storeTokens(loginRes.payload.data.tokens);
    record('POST /auth/login (fallback)', true);
    return;
  }

  record('POST /auth/login (fallback)', false);
  throw new Error('Could not obtain access token via register or login');
}

async function testHealth() {
  console.log('\nHealth');
  const res = await api('GET', '/health', { auth: false });
  assertSuccess('GET /health', res, 200);
}

async function testAuthRoutes() {
  console.log('\nAuth routes (/api/v1/auth)');

  let res = await api('POST', '/auth/login', {
    body: { email: registeredEmail, password: PASSWORD },
    auth: false,
  });
  if (assertSuccess('POST /auth/login', res, 200)) {
    storeTokens(res.payload.data.tokens);
  }

  res = await api('GET', '/auth/me');
  assertSuccess('GET /auth/me', res, 200);

  if (refreshToken) {
    res = await api('POST', '/auth/refresh', {
      body: { refreshToken },
      auth: false,
    });
    if (assertSuccess('POST /auth/refresh', res, 200)) {
      storeTokens(res.payload.data.tokens);
    }
  } else {
    record('POST /auth/refresh', false, 'no refresh token from register/login');
  }
}

async function testUserRoutes() {
  console.log('\nUser routes (/api/v1/users)');

  let res = await api('GET', '/users/me');
  assertSuccess('GET /users/me', res, 200);

  res = await api('PATCH', '/users/me', {
    body: { firstName: 'ApiUpdated', preferredLanguage: 'English' },
  });
  assertSuccess('PATCH /users/me', res, 200);
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
}

async function deleteSettingsAccount() {
  if (!accountId) {
    record('DELETE /settings/accounts/:accountId', false, 'no accountId from create');
    return;
  }

  const res = await api('DELETE', `/settings/accounts/${accountId}`);
  assertSuccess('DELETE /settings/accounts/:accountId', res, 200);
  accountId = null;
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

async function testDebtRoutes() {
  console.log('\nDebt routes (/api/v1/debts)');

  let res = await api('GET', '/debts/summary');
  assertSuccess('GET /debts/summary', res, 200);

  res = await api('GET', '/debts/analytics');
  assertSuccess('GET /debts/analytics', res, 200);

  res = await api('GET', '/debts');
  assertSuccess('GET /debts', res, 200);

  res = await api('GET', '/debts', { query: { filter: 'active' } });
  assertSuccess('GET /debts?filter=active', res, 200);

  res = await api('POST', '/debts', {
    body: {
      personName: uniqueName('Test Person'),
      type: 'lent',
      totalAmount: 500,
      paidAmount: 0,
      debtDate: todayDate(),
      notes: 'Created by API route test script',
    },
  });
  if (assertSuccess('POST /debts', res, 201)) {
    debtId = res.payload.data.id;
  }

  if (!debtId) {
    record('GET /debts/:debtId', false, 'skipped — no debtId');
    record('PATCH /debts/:debtId', false, 'skipped — no debtId');
    record('GET /debts/:debtId/payments', false, 'skipped — no debtId');
    record('POST /debts/:debtId/payments', false, 'skipped — no debtId');
    record('DELETE /debts/:debtId', false, 'skipped — no debtId');
    return;
  }

  res = await api('GET', `/debts/${debtId}`);
  assertSuccess('GET /debts/:debtId', res, 200);

  res = await api('PATCH', `/debts/${debtId}`, {
    body: { notes: 'Updated by test script' },
  });
  assertSuccess('PATCH /debts/:debtId', res, 200);

  res = await api('POST', `/debts/${debtId}/payments`, {
    body: { amount: 50, paymentDate: todayDate(), notes: 'Test payment' },
  });
  assertSuccess('POST /debts/:debtId/payments', res, 200);

  res = await api('GET', `/debts/${debtId}/payments`);
  assertSuccess('GET /debts/:debtId/payments', res, 200);

  res = await api('DELETE', `/debts/${debtId}`);
  assertSuccess('DELETE /debts/:debtId', res, 200);
  debtId = null;
}

async function testDashboardRoutes() {
  console.log('\nDashboard routes (/api/v1/dashboard)');

  let res = await api('GET', '/dashboard/home');
  assertSuccess('GET /dashboard/home', res, 200);

  res = await api('GET', '/dashboard/home', { query: { range: '3m' } });
  assertSuccess('GET /dashboard/home?range=3m', res, 200);
}

async function testTransactionRoutes() {
  console.log('\nTransaction routes (/api/v1/transactions)');

  const probe = await api('GET', '/transactions');
  if (probe.status === 404) {
    recordSkipped(
      'Transaction routes',
      'not mounted — enable router.use("/transactions", ...) in src/routes/index.js'
    );
    return;
  }

  let res = probe;
  assertSuccess('GET /transactions', res, 200);

  res = await api('GET', '/transactions/summary');
  assertSuccess('GET /transactions/summary', res, 200);

  res = await api('GET', '/transactions/analytics');
  assertSuccess('GET /transactions/analytics', res, 200);

  res = await api('GET', '/transactions/analytics', { query: { range: '1m' } });
  assertSuccess('GET /transactions/analytics?range=1m', res, 200);

  res = await api('POST', '/transactions', {
    body: {
      type: 'Expense',
      title: uniqueName('Test Expense'),
      category: 'Food',
      amount: 42.5,
      transactionDate: todayDate(),
      accountId: accountId || undefined,
      note: 'Created by API route test script',
    },
  });
  if (assertSuccess('POST /transactions', res, 201)) {
    transactionId = res.payload.data.id;
  }

  if (!transactionId) {
    record('GET /transactions/:transactionId', false, 'skipped — no transactionId');
    record('PATCH /transactions/:transactionId', false, 'skipped — no transactionId');
    record('DELETE /transactions/:transactionId', false, 'skipped — no transactionId');
    return;
  }

  res = await api('GET', `/transactions/${transactionId}`);
  assertSuccess('GET /transactions/:transactionId', res, 200);

  res = await api('PATCH', `/transactions/${transactionId}`, {
    body: { title: uniqueName('Updated Expense'), amount: 55 },
  });
  assertSuccess('PATCH /transactions/:transactionId', res, 200);

  res = await api('DELETE', `/transactions/${transactionId}`);
  assertSuccess('DELETE /transactions/:transactionId', res, 200);
  transactionId = null;
}

async function testAuthLogout() {
  console.log('\nAuth logout');

  if (!refreshToken) {
    record('POST /auth/logout', false, 'no refresh token');
    return;
  }

  const res = await api('POST', '/auth/logout', {
    body: { refreshToken },
    auth: false,
  });
  assertSuccess('POST /auth/logout', res, 200);
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
  console.log('Kise API route tester (all endpoints)');
  console.log(`Base URL: ${BASE_URL}`);

  await checkServer();
  await testHealth();
  await authenticate();
  await testAuthRoutes();
  await testUserRoutes();
  await testSettingsRoutes();
  await testGoalRoutes();
  await testDebtRoutes();
  await testDashboardRoutes();
  await testTransactionRoutes();
  await deleteSettingsAccount();
  await testAuthLogout();

  console.log('\nSummary');
  console.log(`  Passed:  ${results.passed}`);
  console.log(`  Failed:  ${results.failed}`);
  if (results.skipped > 0) {
    console.log(`  Skipped: ${results.skipped}`);
  }

  if (results.failed > 0) {
    console.log('\nFailed tests:');
    for (const t of results.tests.filter((x) => x.ok === false)) {
      console.log(`  - ${t.name}${t.detail ? `: ${t.detail}` : ''}`);
    }
    process.exit(1);
  }

  console.log('\nAll route tests passed.');
}

main().catch((err) => {
  console.error('\nFatal error:', err.message);
  process.exit(1);
});

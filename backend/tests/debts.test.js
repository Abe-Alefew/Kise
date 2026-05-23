const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const assert = require('node:assert/strict');
const { test, before, after } = require('node:test');
const express = require('express');
const bcrypt = require('bcryptjs');

process.env.NODE_ENV = 'test';
process.env.DB_PATH = path.resolve(__dirname, '../data/kise-auth.test.db');
process.env.JWT_ACCESS_SECRET =
	process.env.JWT_ACCESS_SECRET || 'test-access-secret';
process.env.JWT_REFRESH_SECRET =
	process.env.JWT_REFRESH_SECRET || 'test-refresh-secret';

const database = require('../src/config/database');
const authRoutes = require('../src/routes/auth.routes');
const { notFoundHandler, errorHandler } = require('../src/middleware/error.middleware');

const dbPath = process.env.DB_PATH;

function createTestApp() {
	const app = express();
	app.use(express.json());
	app.use('/api/v1/auth', authRoutes);
	app.use(notFoundHandler);
	app.use(errorHandler);
	return app;
}

let server;
let baseUrl;

async function startServer() {
	const app = createTestApp();
	await new Promise((resolve) => {
		server = app.listen(0, () => {
			const { port } = server.address();
			baseUrl = `http://127.0.0.1:${port}`;
			resolve();
		});
	});
}

async function stopServer() {
	if (!server) {
		return;
	}

	await new Promise((resolve) => server.close(resolve));
	server = null;
}

async function request(pathname, options = {}) {
	const response = await fetch(`${baseUrl}${pathname}`, {
		...options,
		headers: {
			'Content-Type': 'application/json',
			...(options.headers || {}),
		},
	});

	let payload = null;
	try {
		payload = await response.json();
	} catch (error) {
		payload = null;
	}

	return { status: response.status, payload };
}

async function seedUser() {
	const id = crypto.randomUUID();
	const now = new Date().toISOString();
	const passwordHash = await bcrypt.hash('Passw0rd!', 10);

	await database.run(
		`
			INSERT INTO users (
				id,
				email,
				password_hash,
				first_name,
				last_name,
				phone,
				username,
				university,
				department,
				currency,
				terms_accepted_at,
				created_at,
				updated_at
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
		`,
		[
			id,
			'ada@example.com',
			passwordHash,
			'Ada',
			'Lovelace',
			null,
			null,
			'Kise U',
			'CS',
			'ETB',
			now,
			now,
			now,
		]
	);

	await database.run(
		`
			INSERT INTO user_preferences (user_id, preferred_language, theme_mode, updated_at)
			VALUES (?, ?, 'system', ?);
		`,
		[id, 'English', now]
	);

	return id;
}

async function loginAndGetTokens() {
	const { status, payload } = await request('/api/v1/auth/login', {
		method: 'POST',
		body: JSON.stringify({
			email: 'ada@example.com',
			password: 'Passw0rd!',
		}),
	});

	assert.equal(status, 200);
	assert.equal(payload.success, true);
	assert.ok(payload.data.tokens.accessToken);
	assert.ok(payload.data.tokens.refreshToken);

	return payload.data.tokens;
}

before(async () => {
	if (fs.existsSync(dbPath)) {
		fs.unlinkSync(dbPath);
	}

	await database.initialize();
	await seedUser();
	await startServer();
});

after(async () => {
	await stopServer();
	await database.close();

	if (fs.existsSync(dbPath)) {
		fs.unlinkSync(dbPath);
	}
});

test('POST /api/v1/auth/register validates required fields', async () => {
	const { status, payload } = await request('/api/v1/auth/register', {
		method: 'POST',
		body: JSON.stringify({}),
	});

	assert.equal(status, 400);
	assert.equal(payload.success, false);
	assert.equal(payload.error.code, 'VALIDATION_ERROR');
	assert.ok(Array.isArray(payload.error.details));
});

test('POST /api/v1/auth/login returns token pair', async () => {
	const { status, payload } = await request('/api/v1/auth/login', {
		method: 'POST',
		body: JSON.stringify({
			email: 'ada@example.com',
			password: 'Passw0rd!',
		}),
	});

	assert.equal(status, 200);
	assert.equal(payload.success, true);
	assert.ok(payload.data.tokens.accessToken);
	assert.ok(payload.data.tokens.refreshToken);
	assert.equal(payload.data.user.email, 'ada@example.com');
});

test('GET /api/v1/auth/me rejects missing token', async () => {
	const { status, payload } = await request('/api/v1/auth/me');

	assert.equal(status, 401);
	assert.equal(payload.success, false);
	assert.equal(payload.error.code, 'UNAUTHORIZED');
});

test('GET /api/v1/auth/me returns profile', async () => {
	const tokens = await loginAndGetTokens();
	const { status, payload } = await request('/api/v1/auth/me', {
		headers: {
			Authorization: `Bearer ${tokens.accessToken}`,
		},
	});

	assert.equal(status, 200);
	assert.equal(payload.success, true);
	assert.equal(payload.data.user.email, 'ada@example.com');
});

test('POST /api/v1/auth/refresh rotates refresh token', async () => {
	const tokens = await loginAndGetTokens();
	const { status, payload } = await request('/api/v1/auth/refresh', {
		method: 'POST',
		body: JSON.stringify({ refreshToken: tokens.refreshToken }),
	});

	assert.equal(status, 200);
	assert.equal(payload.success, true);
	assert.ok(payload.data.tokens.accessToken);
	assert.ok(payload.data.tokens.refreshToken);
	assert.notEqual(payload.data.tokens.refreshToken, tokens.refreshToken);
});

test('POST /api/v1/auth/logout revokes refresh token', async () => {
	const tokens = await loginAndGetTokens();

	const logoutResponse = await request('/api/v1/auth/logout', {
		method: 'POST',
		body: JSON.stringify({ refreshToken: tokens.refreshToken }),
	});

	assert.equal(logoutResponse.status, 200);
	assert.equal(logoutResponse.payload.success, true);

	const refreshResponse = await request('/api/v1/auth/refresh', {
		method: 'POST',
		body: JSON.stringify({ refreshToken: tokens.refreshToken }),
	});

	assert.equal(refreshResponse.status, 401);
	assert.equal(refreshResponse.payload.success, false);
	assert.equal(refreshResponse.payload.error.code, 'UNAUTHORIZED');
});

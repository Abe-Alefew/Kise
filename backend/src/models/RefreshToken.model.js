const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

const REFRESH_TOKENS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

class RefreshTokenModel {
  static hashToken(rawToken) {
    return crypto.createHash('sha256').update(rawToken).digest('hex');
  }

  static async createTable() {
    await db.run(REFRESH_TOKENS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);'
    );
  }

  static async create(userId, rawToken, expiresAt) {
    const id = uuidv4();
    const tokenHash = RefreshTokenModel.hashToken(rawToken);
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?);
      `,
      [id, userId, tokenHash, expiresAt.toISOString(), now]
    );

    return {
      id,
      userId,
      expiresAt: expiresAt.toISOString(),
    };
  }

  static async findActiveByRawToken(rawToken) {
    const tokenHash = RefreshTokenModel.hashToken(rawToken);
    const row = await db.get(
      `
        SELECT id, user_id, token_hash, expires_at, revoked_at, created_at
        FROM refresh_tokens
        WHERE token_hash = ?
        LIMIT 1;
      `,
      [tokenHash]
    );

    if (!row) {
      return null;
    }

    if (row.revoked_at) {
      return null;
    }

    if (new Date(row.expires_at).getTime() <= Date.now()) {
      return null;
    }

    return {
      id: row.id,
      userId: row.user_id,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    };
  }

  static async revokeById(id) {
    const now = new Date().toISOString();
    await db.run(
      `
        UPDATE refresh_tokens
        SET revoked_at = ?
        WHERE id = ? AND revoked_at IS NULL;
      `,
      [now, id]
    );
  }

  static async revokeAllForUser(userId) {
    const now = new Date().toISOString();
    await db.run(
      `
        UPDATE refresh_tokens
        SET revoked_at = ?
        WHERE user_id = ? AND revoked_at IS NULL;
      `,
      [now, userId]
    );
  }
}

module.exports = RefreshTokenModel;
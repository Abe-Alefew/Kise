const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

const PAYMENT_ACCOUNTS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS payment_accounts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Bank', 'Mobile Money', 'Wallet', 'Other')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id, name)
  );
`;

const ACCOUNT_TYPES = ['Bank', 'Mobile Money', 'Wallet', 'Other'];

class PaymentAccountModel {
  static get allowedTypes() {
    return ACCOUNT_TYPES;
  }

  static async createTable() {
    await db.run(PAYMENT_ACCOUNTS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_id ON payment_accounts(user_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_type ON payment_accounts(user_id, type);'
    );
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      type: row.type,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  static async findAllByUserId(userId) {
    const rows = await db.all(
      `
        SELECT id, user_id, name, type, created_at, updated_at
        FROM payment_accounts
        WHERE user_id = ?
        ORDER BY name COLLATE NOCASE ASC;
      `,
      [userId]
    );

    return rows.map(PaymentAccountModel.mapRow);
  }

  static async findById(userId, accountId) {
    const row = await db.get(
      `
        SELECT id, user_id, name, type, created_at, updated_at
        FROM payment_accounts
        WHERE user_id = ? AND id = ?
        LIMIT 1;
      `,
      [userId, accountId]
    );

    return PaymentAccountModel.mapRow(row);
  }

  static async findByName(userId, name) {
    const row = await db.get(
      `
        SELECT id, user_id, name, type, created_at, updated_at
        FROM payment_accounts
        WHERE user_id = ? AND name = ? COLLATE NOCASE
        LIMIT 1;
      `,
      [userId, name.trim()]
    );

    return PaymentAccountModel.mapRow(row);
  }

  static async create(userId, data) {
    const id = uuidv4();
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO payment_accounts (id, user_id, name, type, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?);
      `,
      [id, userId, data.name.trim(), data.type, now, now]
    );

    return PaymentAccountModel.findById(userId, id);
  }

  static async update(userId, accountId, data) {
    const existing = await PaymentAccountModel.findById(userId, accountId);
    if (!existing) {
      return null;
    }

    const now = new Date().toISOString();

    await db.run(
      `
        UPDATE payment_accounts
        SET
          name = ?,
          type = ?,
          updated_at = ?
        WHERE user_id = ? AND id = ?;
      `,
      [
        data.name !== undefined ? data.name.trim() : existing.name,
        data.type !== undefined ? data.type : existing.type,
        now,
        userId,
        accountId,
      ]
    );

    return PaymentAccountModel.findById(userId, accountId);
  }

  static async delete(userId, accountId) {
    const result = await db.run(
      `
        DELETE FROM payment_accounts
        WHERE user_id = ? AND id = ?;
      `,
      [userId, accountId]
    );

    return result.changes > 0;
  }

  static async countTransactionsLinked(userId, accountId) {
    const row = await db.get(
      `
        SELECT COUNT(*) AS total
        FROM transactions
        WHERE user_id = ?
          AND account_id = ?
          AND deleted_at IS NULL;
      `,
      [userId, accountId]
    );

    return row ? row.total : 0;
  }
}

module.exports = PaymentAccountModel;
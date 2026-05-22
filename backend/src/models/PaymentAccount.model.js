const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class PaymentAccountModel {
  static async createTable() {
    const sql = `
      CREATE TABLE IF NOT EXISTS payment_accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    `;
    return db.run(sql);
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
      `SELECT * FROM payment_accounts WHERE user_id = ? ORDER BY created_at ASC`,
      [userId]
    );
    return rows.map(PaymentAccountModel.mapRow);
  }

  static async findById(userId, accountId) {
    const row = await db.get(
      `SELECT * FROM payment_accounts WHERE id = ? AND user_id = ?`,
      [accountId, userId]
    );
    return PaymentAccountModel.mapRow(row);
  }

  static async findByName(userId, name) {
    const row = await db.get(
      `
        SELECT * FROM payment_accounts
        WHERE user_id = ? AND LOWER(TRIM(name)) = LOWER(TRIM(?))
        LIMIT 1;
      `,
      [userId, name]
    );
    return PaymentAccountModel.mapRow(row);
  }

  static async countTransactionsLinked(userId, accountId) {
    const row = await db.get(
      `
        SELECT COUNT(*) AS count
        FROM goal_deposits
        WHERE user_id = ? AND account_id = ?;
      `,
      [userId, accountId]
    );
    return row ? row.count : 0;
  }

  static async create(userId, data) {
    const { name, type } = data;
    const id = uuidv4();
    const now = new Date().toISOString();

    const sql = `
      INSERT INTO payment_accounts (id, user_id, name, type, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    await db.run(sql, [id, userId, name.trim(), type.trim(), now, now]);
    return PaymentAccountModel.findById(userId, id);
  }

  static async delete(userId, accountId) {
    const result = await db.run(
      `DELETE FROM payment_accounts WHERE id = ? AND user_id = ?`,
      [accountId, userId]
    );
    return result.changes > 0;
  }
}

module.exports = PaymentAccountModel;

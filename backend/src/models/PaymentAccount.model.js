const db = require("../config/database");
const { v4: uuidv4 } = require("uuid");

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

  static async findAllByUserId(userId) {
    const sql = `SELECT * FROM payment_accounts WHERE user_id = ? ORDER BY created_at ASC`;
    return db.all(sql, [userId]);
  }

  static async findById(id, userId) {
    const sql = `SELECT * FROM payment_accounts WHERE id = ? AND user_id = ?`;
    return db.get(sql, [id, userId]);
  }

  static async create(userId, data) {
    const { name, type } = data;
    const id = uuidv4();
    const now = new Date().toISOString();
    
    const sql = `
      INSERT INTO payment_accounts (id, user_id, name, type, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    await db.run(sql, [id, userId, name, type, now, now]);
    return this.findById(id, userId);
  }

  static async delete(id, userId) {
    const sql = `DELETE FROM payment_accounts WHERE id = ? AND user_id = ?`;
    const result = await db.run(sql, [id, userId]);
    return result.changes > 0;
  }
}

module.exports = PaymentAccountModel;

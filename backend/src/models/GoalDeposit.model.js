const db = require("../config/database");
const { v4: uuidv4 } = require("uuid");

class GoalDepositModel {
  static async createTable() {
    const sql = `
      CREATE TABLE IF NOT EXISTS goal_deposits (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        account_id TEXT,
        deposited_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES payment_accounts (id) ON DELETE SET NULL
      )
    `;
    return db.run(sql);
  }

  static async create(userId, goalId, data) {
    const { amount, source, accountId } = data;
    const id = uuidv4();
    const now = new Date().toISOString();
    
    const sql = `
      INSERT INTO goal_deposits (
        id, goal_id, user_id, amount, source, account_id, deposited_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    await db.run(sql, [
      id, goalId, userId, amount, source, accountId || null, now, now
    ]);
    
    const fetchSql = `SELECT * FROM goal_deposits WHERE id = ?`;
    return db.get(fetchSql, [id]);
  }
}

module.exports = GoalDepositModel;

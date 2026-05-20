const db = require("../config/database");

class GoalModel {
  static async createTable() {
    const sql = `
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        period TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        is_locked INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    `;
    return db.run(sql);
  }

  static async findAllByUserId(userId, status) {
    let sql = `SELECT * FROM goals WHERE user_id = ?`;
    const params = [userId];

    if (status && status !== 'all') {
      sql += ` AND status = ?`;
      params.push(status);
    }
    
    sql += ` ORDER BY due_date ASC`;
    return db.all(sql, params);
  }

  static async findById(id, userId) {
    const sql = `SELECT * FROM goals WHERE id = ? AND user_id = ?`;
    return db.get(sql, [id, userId]);
  }

  static async create(userId, data) {
    const { id, title, period, targetAmount, currentAmount = 0, dueDate, note } = data;
    const now = new Date().toISOString();
    
    const sql = `
      INSERT INTO goals (
        id, user_id, title, period, target_amount, current_amount, 
        due_date, note, status, is_locked, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', 0, ?, ?)
    `;
    
    await db.run(sql, [
      id, userId, title, period, targetAmount, currentAmount, 
      dueDate, note || null, now, now
    ]);
    
    return this.findById(id, userId);
  }

  static async update(id, userId, data) {
    const fields = [];
    const params = [];
    const now = new Date().toISOString();

    const allowedFields = ['title', 'period', 'target_amount', 'due_date', 'note', 'status', 'is_locked', 'current_amount'];

    for (const [key, value] of Object.entries(data)) {
      if (allowedFields.includes(key)) {
        fields.push(`${key} = ?`);
        params.push(value);
      }
    }

    if (fields.length === 0) return this.findById(id, userId);

    if (data.status === 'completed' && !fields.includes('completed_at = ?')) {
      fields.push(`completed_at = ?`);
      params.push(now);
    }

    fields.push(`updated_at = ?`);
    params.push(now);

    params.push(id, userId);

    const sql = `UPDATE goals SET ${fields.join(', ')} WHERE id = ? AND user_id = ?`;
    await db.run(sql, params);

    return this.findById(id, userId);
  }

  static async delete(id, userId) {
    const sql = `DELETE FROM goals WHERE id = ? AND user_id = ?`;
    const result = await db.run(sql, [id, userId]);
    return result.changes > 0;
  }
}

module.exports = GoalModel;

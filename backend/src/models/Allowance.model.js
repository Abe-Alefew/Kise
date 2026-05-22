const db = require('../config/database');

const ALLOWANCE_SETTINGS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS allowance_settings (
    user_id TEXT PRIMARY KEY,
    monthly_amount REAL NOT NULL DEFAULT 0
      CHECK (monthly_amount >= 0),
    cycle_start_day INTEGER NOT NULL DEFAULT 1
      CHECK (cycle_start_day >= 1 AND cycle_start_day <= 28),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

class AllowanceModel {
  static async createTable() {
    await db.run(ALLOWANCE_SETTINGS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_allowance_settings_user_id ON allowance_settings(user_id);'
    );
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      userId: row.user_id,
      monthlyAmount: row.monthly_amount,
      cycleStartDay: row.cycle_start_day,
      updatedAt: row.updated_at,
    };
  }

  static async findByUserId(userId) {
    const row = await db.get(
      `
        SELECT user_id, monthly_amount, cycle_start_day, updated_at
        FROM allowance_settings
        WHERE user_id = ?
        LIMIT 1;
      `,
      [userId]
    );

    return AllowanceModel.mapRow(row);
  }

  static async createDefault(userId) {
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO allowance_settings (user_id, monthly_amount, cycle_start_day, updated_at)
        VALUES (?, 0, 1, ?);
      `,
      [userId, now]
    );

    return AllowanceModel.findByUserId(userId);
  }

  static async upsert(userId, data) {
    const existing = await AllowanceModel.findByUserId(userId);
    const now = new Date().toISOString();

    if (!existing) {
      await db.run(
        `
          INSERT INTO allowance_settings (user_id, monthly_amount, cycle_start_day, updated_at)
          VALUES (?, ?, ?, ?);
        `,
        [
          userId,
          data.monthlyAmount !== undefined ? data.monthlyAmount : 0,
          data.cycleStartDay !== undefined ? data.cycleStartDay : 1,
          now,
        ]
      );

      return AllowanceModel.findByUserId(userId);
    }

    await db.run(
      `
        UPDATE allowance_settings
        SET
          monthly_amount = ?,
          cycle_start_day = ?,
          updated_at = ?
        WHERE user_id = ?;
      `,
      [
        data.monthlyAmount !== undefined ? data.monthlyAmount : existing.monthlyAmount,
        data.cycleStartDay !== undefined ? data.cycleStartDay : existing.cycleStartDay,
        now,
        userId,
      ]
    );

    return AllowanceModel.findByUserId(userId);
  }

  static getCycleDateRange(cycleStartDay, referenceDate = new Date()) {
    const safeDay = Math.min(Math.max(cycleStartDay, 1), 28);
    const year = referenceDate.getUTCFullYear();
    const month = referenceDate.getUTCMonth();
    const day = referenceDate.getUTCDate();

    let cycleStartYear = year;
    let cycleStartMonth = month;

    if (day < safeDay) {
      cycleStartMonth -= 1;
      if (cycleStartMonth < 0) {
        cycleStartMonth = 11;
        cycleStartYear -= 1;
      }
    }

    const fromDate = new Date(Date.UTC(cycleStartYear, cycleStartMonth, safeDay));
    const toDate = new Date(referenceDate.toISOString());

    return {
      from: fromDate.toISOString().slice(0, 10),
      to: toDate.toISOString().slice(0, 10),
    };
  }
}

module.exports = AllowanceModel;
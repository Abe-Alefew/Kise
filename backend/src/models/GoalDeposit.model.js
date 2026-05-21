const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const GoalModel = require('./Goal.model');

const GOAL_DEPOSITS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS goal_deposits (
    id TEXT PRIMARY KEY,
    goal_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    source TEXT NOT NULL,
    account_id TEXT,
    deposited_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES payment_accounts(id) ON DELETE SET NULL
  );
`;

class GoalDepositModel {
  static async createTable() {
    await db.run(GOAL_DEPOSITS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_goal_deposits_goal_id ON goal_deposits(goal_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_goal_deposits_user_id ON goal_deposits(user_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_goal_deposits_deposited_at ON goal_deposits(user_id, deposited_at);'
    );
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      goalId: row.goal_id,
      userId: row.user_id,
      amount: row.amount,
      source: row.source,
      accountId: row.account_id,
      depositedAt: row.deposited_at,
      createdAt: row.created_at,
    };
  }

  static async findByGoalId(userId, goalId) {
    const rows = await db.all(
      `
        SELECT id, goal_id, user_id, amount, source, account_id, deposited_at, created_at
        FROM goal_deposits
        WHERE user_id = ? AND goal_id = ?
        ORDER BY deposited_at DESC, created_at DESC;
      `,
      [userId, goalId]
    );

    return rows.map(GoalDepositModel.mapRow);
  }

  static async findById(userId, depositId) {
    const row = await db.get(
      `
        SELECT id, goal_id, user_id, amount, source, account_id, deposited_at, created_at
        FROM goal_deposits
        WHERE user_id = ? AND id = ?
        LIMIT 1;
      `,
      [userId, depositId]
    );

    return GoalDepositModel.mapRow(row);
  }

  static async createAndApply(userId, goalId, data) {
    await db.run('BEGIN IMMEDIATE TRANSACTION;');

    try {
      const incrementResult = await GoalModel.incrementCurrentAmount(
        userId,
        goalId,
        data.amount
      );

      if (incrementResult.error === 'NOT_FOUND') {
        await db.run('ROLLBACK;');
        return { error: 'GOAL_NOT_FOUND' };
      }

      if (incrementResult.error === 'LOCKED') {
        await db.run('ROLLBACK;');
        return { error: 'GOAL_LOCKED' };
      }

      if (incrementResult.error === 'CANCELED') {
        await db.run('ROLLBACK;');
        return { error: 'GOAL_CANCELED' };
      }

      const id = uuidv4();
      const now = new Date().toISOString();
      const depositedAt = data.depositedAt || now;

      await db.run(
        `
          INSERT INTO goal_deposits (
            id,
            goal_id,
            user_id,
            amount,
            source,
            account_id,
            deposited_at,
            created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        `,
        [
          id,
          goalId,
          userId,
          data.amount,
          data.source.trim(),
          data.accountId || null,
          depositedAt,
          now,
        ]
      );

      await db.run('COMMIT;');

      const deposit = await GoalDepositModel.findById(userId, id);

      return {
        goal: incrementResult.goal,
        deposit,
      };
    } catch (error) {
      await db.run('ROLLBACK;');
      throw error;
    }
  }
}

module.exports = GoalDepositModel;
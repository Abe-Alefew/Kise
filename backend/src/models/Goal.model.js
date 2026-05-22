const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { formatDueDateDisplay } = require('../utils/dateHelpers');

const GOALS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS goals (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    period TEXT NOT NULL CHECK (
      period IN ('daily', 'weekly', 'monthly', 'yearly', 'one-time')
    ),
    target_amount REAL NOT NULL CHECK (target_amount > 0),
    current_amount REAL NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    due_date TEXT NOT NULL,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (
      status IN ('active', 'completed', 'canceled')
    ),
    is_locked INTEGER NOT NULL DEFAULT 0 CHECK (is_locked IN (0, 1)),
    completed_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

const GOAL_PERIODS = ['daily', 'weekly', 'monthly', 'yearly', 'one-time'];
const GOAL_STATUSES = ['active', 'completed', 'canceled'];

class GoalModel {
  static get allowedPeriods() {
    return GOAL_PERIODS;
  }

  static get allowedStatuses() {
    return GOAL_STATUSES;
  }

  static async createTable() {
    await db.run(GOALS_TABLE_SQL);
    await db.run('CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_goals_user_status ON goals(user_id, status);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_goals_user_due_date ON goals(user_id, due_date);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_goals_user_period ON goals(user_id, period);');
  }

  static computeIsCompleted(currentAmount, targetAmount, status) {
    if (status === 'completed') {
      return true;
    }
    return currentAmount >= targetAmount;
  }

  static computeProgress(currentAmount, targetAmount) {
    if (targetAmount <= 0) {
      return 0;
    }
    return Math.min(currentAmount / targetAmount, 1);
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    const isCompleted = GoalModel.computeIsCompleted(
      row.current_amount,
      row.target_amount,
      row.status
    );

    return {
      id: row.id,
      userId: row.user_id,
      title: row.title,
      period: row.period,
      targetAmount: row.target_amount,
      currentAmount: row.current_amount,
      dueDate: row.due_date,
      dueDateDisplay: formatDueDateDisplay(row.due_date),
      note: row.note,
      status: row.status,
      isLocked: row.is_locked === 1,
      isCompleted,
      progress: GoalModel.computeProgress(row.current_amount, row.target_amount),
      completedAt: row.completed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  static buildStatusFilterClause(statusFilter) {
    switch (statusFilter) {
      case 'active':
        return `(
          status = 'active'
          AND current_amount < target_amount
        )`;
      case 'completed':
        return `(
          status = 'completed'
          OR current_amount >= target_amount
        )`;
      case 'canceled':
        return `status = 'canceled'`;
      case 'all':
      default:
        return '1 = 1';
    }
  }

  static async findAllByUserId(userId, statusFilter = 'all') {
    const statusClause = GoalModel.buildStatusFilterClause(statusFilter);

    const rows = await db.all(
      `
        SELECT
          id,
          user_id,
          title,
          period,
          target_amount,
          current_amount,
          due_date,
          note,
          status,
          is_locked,
          completed_at,
          created_at,
          updated_at
        FROM goals
        WHERE user_id = ?
          AND ${statusClause}
        ORDER BY
          CASE status
            WHEN 'canceled' THEN 2
            ELSE 1
          END ASC,
          due_date ASC,
          created_at DESC;
      `,
      [userId]
    );

    return rows.map(GoalModel.mapRow);
  }

  static async findById(userId, goalId) {
    const row = await db.get(
      `
        SELECT
          id,
          user_id,
          title,
          period,
          target_amount,
          current_amount,
          due_date,
          note,
          status,
          is_locked,
          completed_at,
          created_at,
          updated_at
        FROM goals
        WHERE user_id = ? AND id = ?
        LIMIT 1;
      `,
      [userId, goalId]
    );

    return GoalModel.mapRow(row);
  }

  static async create(userId, data) {
    const id = uuidv4();
    const now = new Date().toISOString();
    const currentAmount = data.currentAmount || 0;
    const isCompleted = currentAmount >= data.targetAmount;
    const status = data.status || (isCompleted ? 'completed' : 'active');

    await db.run(
      `
        INSERT INTO goals (
          id,
          user_id,
          title,
          period,
          target_amount,
          current_amount,
          due_date,
          note,
          status,
          is_locked,
          completed_at,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      `,
      [
        id,
        userId,
        data.title.trim(),
        data.period,
        data.targetAmount,
        currentAmount,
        data.dueDate,
        data.note ? data.note.trim() : null,
        status,
        data.isLocked ? 1 : 0,
        isCompleted ? now : null,
        now,
        now,
      ]
    );

    return GoalModel.findById(userId, id);
  }

  static async update(userId, goalId, data) {
    const existing = await GoalModel.findById(userId, goalId);
    if (!existing) {
      return null;
    }

    const now = new Date().toISOString();
    const nextTarget =
      data.targetAmount !== undefined ? data.targetAmount : existing.targetAmount;
    const nextCurrent =
      data.currentAmount !== undefined ? data.currentAmount : existing.currentAmount;
    const nextStatus = data.status !== undefined ? data.status : existing.status;
    const nextLocked =
      data.isLocked !== undefined ? (data.isLocked ? 1 : 0) : (existing.isLocked ? 1 : 0);

    const isCompleted = GoalModel.computeIsCompleted(
      nextCurrent,
      nextTarget,
      nextStatus
    );

    let resolvedStatus = nextStatus;
    let completedAt = existing.completedAt;

    if (nextStatus !== 'canceled') {
      if (nextCurrent >= nextTarget) {
        resolvedStatus = 'completed';
        completedAt = completedAt || now;
      } else if (resolvedStatus === 'completed' && nextCurrent < nextTarget) {
        resolvedStatus = 'active';
        completedAt = null;
      }
    }

    await db.run(
      `
        UPDATE goals
        SET
          title = ?,
          period = ?,
          target_amount = ?,
          current_amount = ?,
          due_date = ?,
          note = ?,
          status = ?,
          is_locked = ?,
          completed_at = ?,
          updated_at = ?
        WHERE user_id = ? AND id = ?;
      `,
      [
        data.title !== undefined ? data.title.trim() : existing.title,
        data.period !== undefined ? data.period : existing.period,
        nextTarget,
        nextCurrent,
        data.dueDate !== undefined ? data.dueDate : existing.dueDate,
        data.note !== undefined ? (data.note ? data.note.trim() : null) : existing.note,
        resolvedStatus,
        nextLocked,
        completedAt,
        now,
        userId,
        goalId,
      ]
    );

    return GoalModel.findById(userId, goalId);
  }

  static async setLocked(userId, goalId, isLocked) {
    const existing = await GoalModel.findById(userId, goalId);
    if (!existing) {
      return null;
    }

    const now = new Date().toISOString();

    await db.run(
      `
        UPDATE goals
        SET is_locked = ?, updated_at = ?
        WHERE user_id = ? AND id = ?;
      `,
      [isLocked ? 1 : 0, now, userId, goalId]
    );

    return GoalModel.findById(userId, goalId);
  }

  static async delete(userId, goalId) {
    const result = await db.run(
      `
        DELETE FROM goals
        WHERE user_id = ? AND id = ?;
      `,
      [userId, goalId]
    );

    return result.changes > 0;
  }

  static async incrementCurrentAmount(userId, goalId, amount, options = {}) {
    const manageTransaction = options.manageTransaction !== false;

    if (manageTransaction) {
      await db.run('BEGIN IMMEDIATE TRANSACTION;');
    }

    try {
      const row = await db.get(
        `
          SELECT
            id,
            user_id,
            title,
            period,
            target_amount,
            current_amount,
            due_date,
            note,
            status,
            is_locked,
            completed_at,
            created_at,
            updated_at
          FROM goals
          WHERE user_id = ? AND id = ?
          LIMIT 1;
        `,
        [userId, goalId]
      );

      if (!row) {
        if (manageTransaction) {
          await db.run('ROLLBACK;');
        }
        return { error: 'NOT_FOUND' };
      }

      if (row.status === 'canceled') {
        if (manageTransaction) {
          await db.run('ROLLBACK;');
        }
        return { error: 'CANCELED' };
      }

      if (row.is_locked === 1) {
        if (manageTransaction) {
          await db.run('ROLLBACK;');
        }
        return { error: 'LOCKED' };
      }

      const now = new Date().toISOString();
      const newCurrentAmount = row.current_amount + amount;
      const isCompleted = newCurrentAmount >= row.target_amount;
      const nextStatus = isCompleted ? 'completed' : row.status === 'canceled' ? 'canceled' : 'active';
      const completedAt = isCompleted ? row.completed_at || now : row.completed_at;

      await db.run(
        `
          UPDATE goals
          SET
            current_amount = ?,
            status = ?,
            completed_at = ?,
            updated_at = ?
          WHERE user_id = ? AND id = ?;
        `,
        [newCurrentAmount, nextStatus, completedAt, now, userId, goalId]
      );

      if (manageTransaction) {
        await db.run('COMMIT;');
      }

      const updated = await GoalModel.findById(userId, goalId);
      return { goal: updated };
    } catch (error) {
      if (manageTransaction) {
        await db.run('ROLLBACK;');
      }
      throw error;
    }
  }
}

module.exports = GoalModel;
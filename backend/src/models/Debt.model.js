const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

const DEBTS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS debts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    person_name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('lent', 'borrowed')),
    total_amount REAL NOT NULL CHECK (total_amount >= 0),
    paid_amount REAL NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    debt_date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CHECK (paid_amount <= total_amount)
  );
`;

const DEBT_TYPES = ['lent', 'borrowed'];

class DebtModel {
  static get allowedTypes() {
    return DEBT_TYPES;
  }

  static computeStatus(paidAmount, totalAmount) {
    if (paidAmount >= totalAmount) {
      return 'settled';
    }
    if (paidAmount > 0) {
      return 'partial';
    }
    return 'pending';
  }

  static computeRemaining(totalAmount, paidAmount) {
    return Math.max(totalAmount - paidAmount, 0);
  }

  static async createTable() {
    await db.run(DEBTS_TABLE_SQL);
    await db.run('CREATE INDEX IF NOT EXISTS idx_debts_user_id ON debts(user_id);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_debts_user_type ON debts(user_id, type);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_debts_user_date ON debts(user_id, debt_date);');
    await db.run('CREATE INDEX IF NOT EXISTS idx_debts_user_person ON debts(user_id, person_name);');
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    const remaining = DebtModel.computeRemaining(row.total_amount, row.paid_amount);
    const status = DebtModel.computeStatus(row.paid_amount, row.total_amount);

    return {
      id: row.id,
      userId: row.user_id,
      personName: row.person_name,
      personInitial:
        row.person_name && row.person_name.length > 0
          ? row.person_name[0].toUpperCase()
          : '?',
      type: row.type,
      totalAmount: row.total_amount,
      paidAmount: row.paid_amount,
      remaining,
      status,
      debtDate: row.debt_date,
      notes: row.notes,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      payments: row.payments || [],
    };
  }

  static buildFilterClause(filter) {
    switch (filter) {
      case 'active':
        return 'paid_amount < total_amount';
      case 'lent':
        return `type = 'lent'`;
      case 'borrowed':
        return `type = 'borrowed'`;
      case 'settled':
        return 'paid_amount >= total_amount';
      case 'all':
      default:
        return '1 = 1';
    }
  }

  static async findAllByUserId(userId, filter = 'all', includePayments = true) {
    const filterClause = DebtModel.buildFilterClause(filter);

    const rows = await db.all(
      `
        SELECT
          id,
          user_id,
          person_name,
          type,
          total_amount,
          paid_amount,
          debt_date,
          notes,
          created_at,
          updated_at
        FROM debts
        WHERE user_id = ?
          AND ${filterClause}
        ORDER BY debt_date DESC, created_at DESC;
      `,
      [userId]
    );

    const debts = rows.map(DebtModel.mapRow);

    if (!includePayments) {
      return debts;
    }

    for (const debt of debts) {
      debt.payments = await DebtModel.getPaymentsForDebt(userId, debt.id);
    }

    return debts;
  }

  static async findById(userId, debtId, includePayments = true) {
    const row = await db.get(
      `
        SELECT
          id,
          user_id,
          person_name,
          type,
          total_amount,
          paid_amount,
          debt_date,
          notes,
          created_at,
          updated_at
        FROM debts
        WHERE user_id = ? AND id = ?
        LIMIT 1;
      `,
      [userId, debtId]
    );

    const debt = DebtModel.mapRow(row);
    if (!debt) {
      return null;
    }

    if (includePayments) {
      debt.payments = await DebtModel.getPaymentsForDebt(userId, debtId);
    }

    return debt;
  }

  static async getPaymentsForDebt(userId, debtId) {
    const rows = await db.all(
      `
        SELECT id, debt_id, user_id, amount, payment_date, notes, created_at
        FROM debt_payments
        WHERE user_id = ? AND debt_id = ?
        ORDER BY payment_date DESC, created_at DESC;
      `,
      [userId, debtId]
    );

    return rows.map((row) => ({
      id: row.id,
      amount: row.amount,
      paymentDate: row.payment_date,
      notes: row.notes,
      createdAt: row.created_at,
    }));
  }

  static async create(userId, data) {
    const id = uuidv4();
    const now = new Date().toISOString();
    const paidAmount = data.paidAmount || 0;

    if (paidAmount > data.totalAmount) {
      throw new Error('Paid amount cannot exceed total amount');
    }

    await db.run(
      `
        INSERT INTO debts (
          id,
          user_id,
          person_name,
          type,
          total_amount,
          paid_amount,
          debt_date,
          notes,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      `,
      [
        id,
        userId,
        data.personName.trim(),
        data.type,
        data.totalAmount,
        paidAmount,
        data.debtDate,
        data.notes ? data.notes.trim() : null,
        now,
        now,
      ]
    );

    return DebtModel.findById(userId, id);
  }

  static async update(userId, debtId, data) {
    const existing = await DebtModel.findById(userId, debtId, false);
    if (!existing) {
      return null;
    }

    const nextTotal =
      data.totalAmount !== undefined ? data.totalAmount : existing.totalAmount;
    const nextPaid =
      data.paidAmount !== undefined ? data.paidAmount : existing.paidAmount;

    if (nextPaid > nextTotal) {
      throw new Error('Paid amount cannot exceed total amount');
    }

    const now = new Date().toISOString();

    await db.run(
      `
        UPDATE debts
        SET
          person_name = ?,
          type = ?,
          total_amount = ?,
          paid_amount = ?,
          debt_date = ?,
          notes = ?,
          updated_at = ?
        WHERE user_id = ? AND id = ?;
      `,
      [
        data.personName !== undefined ? data.personName.trim() : existing.personName,
        data.type !== undefined ? data.type : existing.type,
        nextTotal,
        nextPaid,
        data.debtDate !== undefined ? data.debtDate : existing.debtDate,
        data.notes !== undefined ? (data.notes ? data.notes.trim() : null) : existing.notes,
        now,
        userId,
        debtId,
      ]
    );

    return DebtModel.findById(userId, debtId);
  }

  static async delete(userId, debtId) {
    const result = await db.run(
      `
        DELETE FROM debts
        WHERE user_id = ? AND id = ?;
      `,
      [userId, debtId]
    );

    return result.changes > 0;
  }

  static async incrementPaidAmount(userId, debtId, amount) {
    await db.run('BEGIN IMMEDIATE TRANSACTION;');

    try {
      const row = await db.get(
        `
          SELECT id, total_amount, paid_amount
          FROM debts
          WHERE user_id = ? AND id = ?
          LIMIT 1;
        `,
        [userId, debtId]
      );

      if (!row) {
        await db.run('ROLLBACK;');
        return { error: 'NOT_FOUND' };
      }

      const remaining = row.total_amount - row.paid_amount;
      if (amount > remaining) {
        await db.run('ROLLBACK;');
        return { error: 'OVERPAYMENT', remaining };
      }

      const now = new Date().toISOString();
      const newPaidAmount = row.paid_amount + amount;

      await db.run(
        `
          UPDATE debts
          SET paid_amount = ?, updated_at = ?
          WHERE user_id = ? AND id = ?;
        `,
        [newPaidAmount, now, userId, debtId]
      );

      await db.run('COMMIT;');

      const debt = await DebtModel.findById(userId, debtId);
      return { debt };
    } catch (error) {
      await db.run('ROLLBACK;');
      throw error;
    }
  }

  static async getSummary(userId) {
    const rows = await db.all(
      `
        SELECT type, total_amount, paid_amount
        FROM debts
        WHERE user_id = ?;
      `,
      [userId]
    );

    let owedToMe = 0;
    let iOwe = 0;
    let totalLent = 0;
    let totalBorrowed = 0;
    let totalPaid = 0;
    let totalAmount = 0;

    let pending = 0;
    let partial = 0;
    let settled = 0;

    for (const row of rows) {
      const remaining = DebtModel.computeRemaining(row.total_amount, row.paid_amount);
      const status = DebtModel.computeStatus(row.paid_amount, row.total_amount);

      totalAmount += row.total_amount;
      totalPaid += row.paid_amount;

      if (status === 'pending') pending += 1;
      if (status === 'partial') partial += 1;
      if (status === 'settled') settled += 1;

      if (row.type === 'lent') {
        totalLent += row.total_amount;
        if (status !== 'settled') {
          owedToMe += remaining;
        }
      }

      if (row.type === 'borrowed') {
        totalBorrowed += row.total_amount;
        if (status !== 'settled') {
          iOwe += remaining;
        }
      }
    }

    const netPosition = owedToMe - iOwe;
    const recoveryRate = totalAmount > 0 ? totalPaid / totalAmount : 0;

    return {
      owedToMe,
      iOwe,
      netPosition,
      recoveryRate: Number(recoveryRate.toFixed(4)),
      counts: { pending, partial, settled },
      totals: {
        totalLent,
        totalBorrowed,
        outstandingOwedToMe: owedToMe,
        outstandingIOwe: iOwe,
      },
    };
  }

  static async getAnalytics(userId) {
    const summary = await DebtModel.getSummary(userId);

    const activeRows = await db.all(
      `
        SELECT
          id,
          person_name,
          type,
          total_amount,
          paid_amount
        FROM debts
        WHERE user_id = ?
          AND paid_amount < total_amount
        ORDER BY person_name COLLATE NOCASE ASC;
      `,
      [userId]
    );

    const activeBalancesByPerson = activeRows.map((row) => {
      const remaining = DebtModel.computeRemaining(row.total_amount, row.paid_amount);
      const status = DebtModel.computeStatus(row.paid_amount, row.total_amount);
      const balance = row.type === 'lent' ? remaining : -remaining;

      return {
        debtId: row.id,
        personName: row.person_name,
        type: row.type,
        balance,
        remaining,
        status,
      };
    });

    return {
      statusBreakdown: summary.counts,
      totals: summary.totals,
      activeBalancesByPerson,
    };
  }
}

module.exports = DebtModel;
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const DebtModel = require('./Debt.model');

const DEBT_PAYMENTS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS debt_payments (
    id TEXT PRIMARY KEY,
    debt_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    payment_date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

class DebtPaymentModel {
  static async createTable() {
    await db.run(DEBT_PAYMENTS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_id ON debt_payments(debt_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_user_id ON debt_payments(user_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_payment_date ON debt_payments(user_id, payment_date);'
    );
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      debtId: row.debt_id,
      userId: row.user_id,
      amount: row.amount,
      paymentDate: row.payment_date,
      notes: row.notes,
      createdAt: row.created_at,
    };
  }

  static async findByDebtId(userId, debtId) {
    const rows = await db.all(
      `
        SELECT id, debt_id, user_id, amount, payment_date, notes, created_at
        FROM debt_payments
        WHERE user_id = ? AND debt_id = ?
        ORDER BY payment_date DESC, created_at DESC;
      `,
      [userId, debtId]
    );

    return rows.map(DebtPaymentModel.mapRow);
  }

  static async findById(userId, paymentId) {
    const row = await db.get(
      `
        SELECT id, debt_id, user_id, amount, payment_date, notes, created_at
        FROM debt_payments
        WHERE user_id = ? AND id = ?
        LIMIT 1;
      `,
      [userId, paymentId]
    );

    return DebtPaymentModel.mapRow(row);
  }

  static async createAndApply(userId, debtId, data) {
    await db.run('BEGIN IMMEDIATE TRANSACTION;');

    try {
      const incrementResult = await DebtModel.incrementPaidAmount(
        userId,
        debtId,
        data.amount
      );

      if (incrementResult.error === 'NOT_FOUND') {
        await db.run('ROLLBACK;');
        return { error: 'DEBT_NOT_FOUND' };
      }

      if (incrementResult.error === 'OVERPAYMENT') {
        await db.run('ROLLBACK;');
        return {
          error: 'OVERPAYMENT',
          remaining: incrementResult.remaining,
        };
      }

      const id = uuidv4();
      const now = new Date().toISOString();
      const paymentDate = data.paymentDate || now.slice(0, 10);

      await db.run(
        `
          INSERT INTO debt_payments (
            id,
            debt_id,
            user_id,
            amount,
            payment_date,
            notes,
            created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?);
        `,
        [
          id,
          debtId,
          userId,
          data.amount,
          paymentDate,
          data.notes ? data.notes.trim() : null,
          now,
        ]
      );

      await db.run('COMMIT;');

      const payment = await DebtPaymentModel.findById(userId, id);
      const debt = await DebtModel.findById(userId, debtId);

      return { debt, payment };
    } catch (error) {
      await db.run('ROLLBACK;');
      throw error;
    }
  }
}

module.exports = DebtPaymentModel;
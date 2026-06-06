const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');


const TRANSACTIONS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Income', 'Expense')),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    transaction_date TEXT NOT NULL,
    account_id TEXT,
    note TEXT,
    icon_key TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES payment_accounts(id) ON DELETE SET NULL
  );
`;


const TRANSACTION_TYPES = ['Income', 'Expense'];

const INCOME_CATEGORIES = [
  'Salary',
  'Freelance',
  'Investment',
  'Business',
  'Allowance',
  'Bonus',
];

const EXPENSE_CATEGORIES = [
  'Food',
  'Transport',
  'Education',
  'Entertainment',
  'Shopping',
  'Bills',
  'Housing',
  'Health',
  'Travel',
];

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class TransactionModel {
  static get allowedTypes() {
    return TRANSACTION_TYPES;
  }

  static get incomeCategories() {
    return INCOME_CATEGORIES;
  }

  static get expenseCategories() {
    return EXPENSE_CATEGORIES;
  }

  static async createTable() {
    await db.run(TRANSACTIONS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_type ON transactions(user_id, type);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_category ON transactions(user_id, category);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_account ON transactions(user_id, account_id);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_transactions_active ON transactions(user_id, deleted_at);'
    );
  }

  static isValidCategory(type, category) {
    if (type === 'Income') {
      return INCOME_CATEGORIES.includes(category);
    }
    if (type === 'Expense') {
      return EXPENSE_CATEGORIES.includes(category);
    }
    return false;
  }

  static formatDisplayDate(isoDate) {
    const date = new Date(`${isoDate}T00:00:00.000Z`);
    const month = MONTH_LABELS[date.getUTCMonth()];
    const day = date.getUTCDate();
    return `${month} ${day}`;
  }

  static formatMonthLabel(isoDate) {
    const date = new Date(`${isoDate}T00:00:00.000Z`);
    return MONTH_LABELS[date.getUTCMonth()];
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      userId: row.user_id,
      type: row.type,
      title: row.title,
      category: row.category,
      amount: row.amount,
      transactionDate: row.transaction_date,
      displayDate: TransactionModel.formatDisplayDate(row.transaction_date),
      month: TransactionModel.formatMonthLabel(row.transaction_date),
      accountId: row.account_id,
      accountName: row.account_name || null,
      note: row.note,
      iconKey: row.icon_key,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      deletedAt: row.deleted_at,
    };
  }

  static buildFilterClause(filters) {
    const conditions = ['t.user_id = ?', 't.deleted_at IS NULL'];
    const params = [filters.userId];

    if (filters.type) {
      conditions.push('t.type = ?');
      params.push(filters.type);
    }

    if (filters.category) {
      conditions.push('t.category = ?');
      params.push(filters.category);
    }

    if (filters.accountId) {
      conditions.push('t.account_id = ?');
      params.push(filters.accountId);
    }

    if (filters.from) {
      conditions.push('date(t.transaction_date) >= date(?)');
      params.push(filters.from);
    }

    if (filters.to) {
      conditions.push('date(t.transaction_date) <= date(?)');
      params.push(filters.to);
    }

    if (filters.q) {
      conditions.push(
        "(t.title LIKE ? OR t.category LIKE ? OR IFNULL(t.note, \'\') LIKE ?)"
      );
      const term = `%${filters.q}%`;
      params.push(term, term, term);
    }

    return {
      whereSql: conditions.join(' AND '),
      params,
    };
  }

  static resolveSort(sort) {
    switch (sort) {
      case 'date_asc':
        return 't.transaction_date ASC, t.created_at ASC';
      case 'amount_desc':
        return 't.amount DESC, t.transaction_date DESC';
      case 'amount_asc':
        return 't.amount ASC, t.transaction_date DESC';
      case 'date_desc':
      default:
        return 't.transaction_date DESC, t.created_at DESC';
    }
  }

  static async findWithFilters(filters) {
    const { whereSql, params } = TransactionModel.buildFilterClause(filters);
    const sortSql = TransactionModel.resolveSort(filters.sort || 'date_desc');
    const limit = filters.limit || 20;
    const offset = filters.offset || 0;

    const rows = await db.all(
      `
        SELECT
          t.id,
          t.user_id,
          t.type,
          t.title,
          t.category,
          t.amount,
          t.transaction_date,
          t.account_id,
          t.note,
          t.icon_key,
          t.created_at,
          t.updated_at,
          t.deleted_at,
          pa.name AS account_name
        FROM transactions t
        LEFT JOIN payment_accounts pa
          ON pa.id = t.account_id AND pa.user_id = t.user_id
        WHERE ${whereSql}
        ORDER BY ${sortSql}
        LIMIT ? OFFSET ?;
      `,
      [...params, limit, offset]
    );

    return rows.map(TransactionModel.mapRow);
  }

  static async countWithFilters(filters) {
    const { whereSql, params } = TransactionModel.buildFilterClause(filters);

    const row = await db.get(
      `
        SELECT COUNT(*) AS total
        FROM transactions t
        WHERE ${whereSql};
      `,
      params
    );

    return row ? row.total : 0;
  }

  static async findById(userId, transactionId, includeDeleted = false) {
    const deletedClause = includeDeleted ? '' : 'AND t.deleted_at IS NULL';

    const row = await db.get(
      `
        SELECT
          t.id,
          t.user_id,
          t.type,
          t.title,
          t.category,
          t.amount,
          t.transaction_date,
          t.account_id,
          t.note,
          t.icon_key,
          t.created_at,
          t.updated_at,
          t.deleted_at,
          pa.name AS account_name
        FROM transactions t
        LEFT JOIN payment_accounts pa
          ON pa.id = t.account_id AND pa.user_id = t.user_id
        WHERE t.user_id = ? AND t.id = ?
        ${deletedClause}
        LIMIT 1;
      `,
      [userId, transactionId]
    );

    return TransactionModel.mapRow(row);
  }

  static async create(userId, data) {
    const id = uuidv4();
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO transactions (
          id,
          user_id,
          type,
          title,
          category,
          amount,
          transaction_date,
          account_id,
          note,
          icon_key,
          created_at,
          updated_at,
          deleted_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL);
      `,
      [
        id,
        userId,
        data.type,
        data.title.trim(),
        data.category,
        data.amount,
        data.transactionDate,
        data.accountId || null,
        data.note ? data.note.trim() : null,
        data.iconKey || null,
        now,
        now,
      ]
    );

    return TransactionModel.findById(userId, id);
  }

  static async update(userId, transactionId, data) {
    const existing = await TransactionModel.findById(userId, transactionId);
    if (!existing) {
      return null;
    }

    const now = new Date().toISOString();

    await db.run(
      `
        UPDATE transactions
        SET
          type = ?,
          title = ?,
          category = ?,
          amount = ?,
          transaction_date = ?,
          account_id = ?,
          note = ?,
          icon_key = ?,
          updated_at = ?
        WHERE user_id = ? AND id = ? AND deleted_at IS NULL;
      `,
      [
        data.type !== undefined ? data.type : existing.type,
        data.title !== undefined ? data.title.trim() : existing.title,
        data.category !== undefined ? data.category : existing.category,
        data.amount !== undefined ? data.amount : existing.amount,
        data.transactionDate !== undefined ? data.transactionDate : existing.transactionDate,
        data.accountId !== undefined ? data.accountId : existing.accountId,
        data.note !== undefined ? (data.note ? data.note.trim() : null) : existing.note,
        data.iconKey !== undefined ? data.iconKey : existing.iconKey,
        now,
        userId,
        transactionId,
      ]
    );

    return TransactionModel.findById(userId, transactionId);
  }

  static async softDelete(userId, transactionId) {
    const now = new Date().toISOString();
    const result = await db.run(
      `
        UPDATE transactions
        SET deleted_at = ?, updated_at = ?
        WHERE user_id = ? AND id = ? AND deleted_at IS NULL;
      `,
      [now, now, userId, transactionId]
    );

    return result.changes > 0;
  }

  static async getSummary(userId, from, to) {
    const params = [userId];
    let dateClause = '';

    if (from) {
      dateClause += ' AND date(transaction_date) >= date(?)';
      params.push(from);
    }

    if (to) {
      dateClause += ' AND date(transaction_date) <= date(?)';
      params.push(to);
    }

    const incomeRow = await db.get(
      `
        SELECT IFNULL(SUM(amount), 0) AS total
        FROM transactions
        WHERE user_id = ?
          AND type = 'Income'
          AND deleted_at IS NULL
          ${dateClause};
      `,
      params
    );

    const expenseRow = await db.get(
      `
        SELECT IFNULL(SUM(amount), 0) AS total
        FROM transactions
        WHERE user_id = ?
          AND type = 'Expense'
          AND deleted_at IS NULL
          ${dateClause};
      `,
      params
    );

    const totalIncome = incomeRow ? incomeRow.total : 0;
    const totalExpense = expenseRow ? expenseRow.total : 0;
    const balance = totalIncome - totalExpense;
    const savingRate = totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0;

    return {
      totalIncome,
      totalExpense,
      balance,
      savingRate: Number(savingRate.toFixed(4)),
    };
  }

  static resolveRangeMonths(range) {
    const now = new Date();
    let monthsBack = 1;

    switch (range) {
      case '3m':
        monthsBack = 3;
        break;
      case '6m':
        monthsBack = 6;
        break;
      case '1y':
        monthsBack = 12;
        break;
      case '1m':
      default:
        monthsBack = 1;
        break;
    }

    const fromDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - (monthsBack - 1), 1));
    const from = fromDate.toISOString().slice(0, 10);

    return { from, monthsBack };
  }

  static async getAnalytics(userId, options) {
    const { from } = TransactionModel.resolveRangeMonths(options.range || '1m');
    const params = [userId, from];

    let typeClause = '';
    if (options.type === 'Income' || options.type === 'Expense') {
      typeClause = ' AND type = ?';
      params.push(options.type);
    }

    const rows = await db.all(
      `
        SELECT
          type,
          category,
          strftime('%Y-%m', transaction_date) AS year_month,
          transaction_date,
          SUM(amount) AS total_amount
        FROM transactions
        WHERE user_id = ?
          AND deleted_at IS NULL
          AND date(transaction_date) >= date(?)
          ${typeClause}
        GROUP BY type, category, year_month
        ORDER BY year_month ASC, category ASC;
      `,
      params
    );

    const incomeByMonth = {};
    const expenseByMonth = {};
    const categoryTotals = {};
    const monthSet = new Set();

    for (const row of rows) {
      const monthLabel = TransactionModel.formatMonthLabel(`${row.year_month}-01`);
      monthSet.add(monthLabel);

      if (row.type === 'Income') {
        incomeByMonth[monthLabel] = incomeByMonth[monthLabel] || {};
        incomeByMonth[monthLabel][row.category] =
          (incomeByMonth[monthLabel][row.category] || 0) + row.total_amount;
      }

      if (row.type === 'Expense') {
        expenseByMonth[monthLabel] = expenseByMonth[monthLabel] || {};
        expenseByMonth[monthLabel][row.category] =
          (expenseByMonth[monthLabel][row.category] || 0) + row.total_amount;
      }

      categoryTotals[row.category] = (categoryTotals[row.category] || 0) + row.total_amount;
    }

    const months = Array.from(monthSet);

    return {
      months,
      incomeByMonth,
      expenseByMonth,
      categoryTotals,
    };
  }

  static async getRecent(userId, limit = 5) {
    return TransactionModel.findWithFilters({
      userId,
      limit,
      offset: 0,
      sort: 'date_desc',
    });
  }
}

module.exports = TransactionModel;

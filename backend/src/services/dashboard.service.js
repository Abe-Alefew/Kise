const UserModel = require('../models/User.model');
const TransactionModel = require('../models/Transaction.model');
const AllowanceModel = require('../models/Allowance.model');

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function getCurrentMonthRange(referenceDate = new Date()) {
  const year = referenceDate.getUTCFullYear();
  const month = referenceDate.getUTCMonth();
  const fromDate = new Date(Date.UTC(year, month, 1));
  const toDate = new Date(Date.UTC(year, month + 1, 0));

  return {
    from: fromDate.toISOString().slice(0, 10),
    to: toDate.toISOString().slice(0, 10),
  };
}

function determineSpendingPersonality({ savingRate, spendRatio, totalIncome, totalExpense }) {
  if (totalIncome === 0 && totalExpense === 0) {
    return {
      personality: 'Getting Started',
      tip: 'Log your first transaction to unlock personalized spending insights.',
    };
  }

  if (savingRate >= 0.35 && spendRatio <= 0.65) {
    return {
      personality: 'Thrifty',
      tip: 'Excellent savings discipline. Consider moving surplus funds into your goals.',
    };
  }

  if (savingRate >= 0.15 && spendRatio <= 0.8) {
    return {
      personality: 'Balanced',
      tip: 'Good balance between spending and saving. Try to push your savings a bit higher.',
    };
  }

  if (spendRatio > 0.9) {
    return {
      personality: 'Heavy Spender',
      tip: 'You are close to or above your allowance this cycle. Review recent expenses.',
    };
  }

  return {
    personality: 'Spender',
    tip: 'Your spending rate is elevated this cycle. Tighten discretionary purchases.',
  };
}

function buildTrendSeries(analytics) {
  const months = analytics.months || [];
  const trend = [];

  for (const month of months) {
    const incomeMap = analytics.incomeByMonth[month] || {};
    const expenseMap = analytics.expenseByMonth[month] || {};

    const income = Object.values(incomeMap).reduce((sum, value) => sum + value, 0);
    const expense = Object.values(expenseMap).reduce((sum, value) => sum + value, 0);

    trend.push({
      month,
      income: Number(income.toFixed(2)),
      expense: Number(expense.toFixed(2)),
    });
  }

  return trend;
}

function buildCategorySpending(expenseRows) {
  const totals = {};

  for (const row of expenseRows) {
    totals[row.category] = (totals[row.category] || 0) + row.total_amount;
  }

  const grandTotal = Object.values(totals).reduce((sum, value) => sum + value, 0);

  if (grandTotal <= 0) {
    return [];
  }

  return Object.entries(totals)
    .map(([category, amount]) => ({
      category,
      amount: Number(amount.toFixed(2)),
      percentage: Number((amount / grandTotal).toFixed(4)),
    }))
    .sort((a, b) => b.amount - a.amount);
}

function mapRecentTransaction(transaction) {
  return {
    id: transaction.id,
    type: transaction.type,
    title: transaction.title,
    category: transaction.category,
    amount: transaction.amount,
    transactionDate: transaction.transactionDate,
    displayDate: transaction.displayDate,
    month: transaction.month,
    accountId: transaction.accountId,
    accountName: transaction.accountName,
    note: transaction.note,
    iconKey: transaction.iconKey,
  };
}

class DashboardService {
  static async getHomeBundle(userId, options = {}) {
    const user = await UserModel.findById(userId);
    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      error.code = 'NOT_FOUND';
      throw error;
    }

    const monthRange = getCurrentMonthRange();
    const range = options.range || '6m';

    const [
      monthSummary,
      allowance,
      analytics,
      recentTransactions,
      cycleExpenseRow,
    ] = await Promise.all([
      TransactionModel.getSummary(userId, monthRange.from, monthRange.to),
      AllowanceModel.findByUserId(userId),
      TransactionModel.getAnalytics(userId, { range, type: 'all' }),
      TransactionModel.getRecent(userId, 5),
      DashboardService.getCycleExpenseTotal(userId, allowance),
    ]);

    const monthlyAmount = allowance ? allowance.monthlyAmount : 0;
    const cycleStartDay = allowance ? allowance.cycleStartDay : 1;
    const cycleExpense = cycleExpenseRow;
    const spendRatio =
      monthlyAmount > 0
        ? Number(Math.min(cycleExpense / monthlyAmount, 1).toFixed(4))
        : 0;

    const personality = determineSpendingPersonality({
      savingRate: monthSummary.savingRate,
      spendRatio,
      totalIncome: monthSummary.totalIncome,
      totalExpense: monthSummary.totalExpense,
    });

    const categorySpending = await DashboardService.getCurrentMonthCategorySpending(
      userId,
      monthRange.from,
      monthRange.to
    );

    return {
      user: {
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        currency: user.currency,
      },
      balance: {
        total: Number(monthSummary.balance.toFixed(2)),
        income: Number(monthSummary.totalIncome.toFixed(2)),
        expenses: Number(monthSummary.totalExpense.toFixed(2)),
        currency: user.currency || 'ETB',
      },
      allowance: {
        monthlyAmount,
        cycleStartDay,
        isConfigured: monthlyAmount > 0,
        cycleSpend: Number(cycleExpense.toFixed(2)),
        cycleFrom: cycleExpenseRow.cycleFrom,
        cycleTo: cycleExpenseRow.cycleTo,
      },
      budgetStatus: {
        spendRatio,
        personality: personality.personality,
        tip: personality.tip,
      },
      trend: buildTrendSeries(analytics),
      categorySpending,
      recentTransactions: recentTransactions.map(mapRecentTransaction),
    };
  }

  static async getCycleExpenseTotal(userId, allowance) {
    const cycleStartDay = allowance ? allowance.cycleStartDay : 1;
    const cycleRange = AllowanceModel.getCycleDateRange(cycleStartDay);
    const db = require('../config/database');

    const row = await db.get(
      `
        SELECT IFNULL(SUM(amount), 0) AS total
        FROM transactions
        WHERE user_id = ?
          AND type = 'Expense'
          AND deleted_at IS NULL
          AND date(transaction_date) >= date(?)
          AND date(transaction_date) <= date(?);
      `,
      [userId, cycleRange.from, cycleRange.to]
    );

    return {
      total: row ? row.total : 0,
      cycleFrom: cycleRange.from,
      cycleTo: cycleRange.to,
    };
  }

  static async getCurrentMonthCategorySpending(userId, from, to) {
    const db = require('../config/database');

    const rows = await db.all(
      `
        SELECT category, SUM(amount) AS total_amount
        FROM transactions
        WHERE user_id = ?
          AND type = 'Expense'
          AND deleted_at IS NULL
          AND date(transaction_date) >= date(?)
          AND date(transaction_date) <= date(?)
        GROUP BY category
        ORDER BY total_amount DESC;
      `,
      [userId, from, to]
    );

    return buildCategorySpending(rows);
  }
}

module.exports = DashboardService;
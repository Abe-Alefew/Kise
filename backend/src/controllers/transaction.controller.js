const TransactionModel = require('../models/Transaction.model');
const PaymentAccountModel = require('../models/PaymentAccount.model');
const UserModel = require('../models/User.model');
const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}

function mapTransactionResponse(transaction) {
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
    createdAt: transaction.createdAt,
    updatedAt: transaction.updatedAt,
  };
}

async function validateAccountOwnership(userId, accountId) {
  if (!accountId) {
    return null;
  }

  const account = await PaymentAccountModel.findById(userId, accountId);
  if (!account) {
    throw createHttpError(422, 'BUSINESS_RULE', 'Selected payment account does not exist');
  }

  return account;
}

function validateCategoryForType(type, category) {
  if (!TransactionModel.isValidCategory(type, category)) {
    throw createHttpError(
      422,
      'BUSINESS_RULE',
      `Category "${category}" is not valid for transaction type "${type}"`
    );
  }
}

class TransactionController {
  static async listTransactions(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const offset = (page - 1) * limit;

      const filters = {
        userId: req.user.id,
        type: req.query.type,
        category: req.query.category,
        accountId: req.query.accountId,
        from: req.query.from,
        to: req.query.to,
        q: req.query.q,
        sort: req.query.sort || 'date_desc',
        limit,
        offset,
      };

      const [items, total] = await Promise.all([
        TransactionModel.findWithFilters(filters),
        TransactionModel.countWithFilters(filters),
      ]);

      return sendSuccess(res, 200, {
        items: items.map(mapTransactionResponse),
        pagination: {
          page,
          limit,
          total,
          hasMore: offset + items.length < total,
        },
      });
    } catch (error) {
      return next(error);
    }
  }

  static async getTransaction(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const transaction = await TransactionModel.findById(
        req.user.id,
        req.params.transactionId
      );

      if (!transaction) {
        throw createHttpError(404, 'NOT_FOUND', 'Transaction not found');
      }

      return sendSuccess(res, 200, mapTransactionResponse(transaction));
    } catch (error) {
      return next(error);
    }
  }

  static async createTransaction(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      validateCategoryForType(req.body.type, req.body.category);
      await validateAccountOwnership(req.user.id, req.body.accountId);

      const transaction = await TransactionModel.create(req.user.id, {
        type: req.body.type,
        title: req.body.title,
        category: req.body.category,
        amount: Number(req.body.amount),
        transactionDate: req.body.transactionDate,
        accountId: req.body.accountId || null,
        note: req.body.note,
        iconKey: req.body.iconKey,
      });

      return sendSuccess(res, 201, mapTransactionResponse(transaction));
    } catch (error) {
      return next(error);
    }
  }

  static async updateTransaction(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const existing = await TransactionModel.findById(
        req.user.id,
        req.params.transactionId
      );

      if (!existing) {
        throw createHttpError(404, 'NOT_FOUND', 'Transaction not found');
      }

      const nextType = req.body.type !== undefined ? req.body.type : existing.type;
      const nextCategory =
        req.body.category !== undefined ? req.body.category : existing.category;

      validateCategoryForType(nextType, nextCategory);

      if (req.body.accountId !== undefined) {
        await validateAccountOwnership(req.user.id, req.body.accountId);
      }

      const transaction = await TransactionModel.update(
        req.user.id,
        req.params.transactionId,
        {
          type: req.body.type,
          title: req.body.title,
          category: req.body.category,
          amount:
            req.body.amount !== undefined ? Number(req.body.amount) : undefined,
          transactionDate: req.body.transactionDate,
          accountId: req.body.accountId,
          note: req.body.note,
          iconKey: req.body.iconKey,
        }
      );

      return sendSuccess(res, 200, mapTransactionResponse(transaction));
    } catch (error) {
      return next(error);
    }
  }

  static async deleteTransaction(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const deleted = await TransactionModel.softDelete(
        req.user.id,
        req.params.transactionId
      );

      if (!deleted) {
        throw createHttpError(404, 'NOT_FOUND', 'Transaction not found');
      }

      return sendSuccess(res, 200, { message: 'Transaction deleted successfully' });
    } catch (error) {
      return next(error);
    }
  }

  static async getSummary(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const summary = await TransactionModel.getSummary(
        req.user.id,
        req.query.from,
        req.query.to
      );

      const user = await UserModel.findById(req.user.id);

      return sendSuccess(res, 200, {
        ...summary,
        currency: user ? user.currency : 'ETB',
      });
    } catch (error) {
      return next(error);
    }
  }

  static async getAnalytics(req, res, next) {
    try {
      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const analytics = await TransactionModel.getAnalytics(req.user.id, {
        range: req.query.range || '1m',
        type:
          req.query.type === 'Income' || req.query.type === 'Expense'
            ? req.query.type
            : 'all',
      });

      return sendSuccess(res, 200, analytics);
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = TransactionController;
const express = require('express');
const { body, param, query } = require('express-validator');
const TransactionController = require('../controllers/transaction.controller');
const TransactionModel = require('../models/Transaction.model');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

const allCategories = [
  ...TransactionModel.incomeCategories,
  ...TransactionModel.expenseCategories,
];

const listTransactionsValidation = [
  query('type')
    .optional()
    .isIn(TransactionModel.allowedTypes)
    .withMessage('Type must be Income or Expense'),
  query('category')
    .optional()
    .isIn(allCategories)
    .withMessage('Category is invalid'),
  query('accountId')
    .optional()
    .isUUID()
    .withMessage('accountId must be a valid UUID'),
  query('from')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('from must be a valid ISO date (YYYY-MM-DD)'),
  query('to')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('to must be a valid ISO date (YYYY-MM-DD)'),
  query('q')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Search query must be at most 100 characters'),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('limit must be between 1 and 100'),
  query('sort')
    .optional()
    .isIn(['date_desc', 'date_asc', 'amount_desc', 'amount_asc'])
    .withMessage('sort is invalid'),
];

const summaryValidation = [
  query('from')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('from must be a valid ISO date (YYYY-MM-DD)'),
  query('to')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('to must be a valid ISO date (YYYY-MM-DD)'),
];

const analyticsValidation = [
  query('range')
    .optional()
    .isIn(['1m', '3m', '6m', '1y'])
    .withMessage('range must be one of: 1m, 3m, 6m, 1y'),
  query('type')
    .optional()
    .isIn(['all', 'Income', 'Expense'])
    .withMessage('type must be all, Income, or Expense'),
];

const transactionIdValidation = [
  param('transactionId')
    .trim()
    .notEmpty()
    .withMessage('Transaction id is required')
    .isUUID()
    .withMessage('Transaction id must be a valid UUID'),
];

const createTransactionValidation = [
  body('type')
    .trim()
    .notEmpty()
    .withMessage('Transaction type is required')
    .isIn(TransactionModel.allowedTypes)
    .withMessage('Type must be Income or Expense'),
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 150 })
    .withMessage('Title must be at most 150 characters'),
  body('category')
    .trim()
    .notEmpty()
    .withMessage('Category is required')
    .isLength({ max: 100 })
    .withMessage('Category must be at most 100 characters')
    .custom((value, { req }) => {
      if (!TransactionModel.isValidCategory(req.body.type, value)) {
        throw new Error(`Category "${value}" is invalid for type "${req.body.type}"`);
      }
      return true;
    }),
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ gt: 0 })
    .withMessage('Amount must be greater than 0'),
  body('transactionDate')
    .trim()
    .notEmpty()
    .withMessage('Transaction date is required')
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('transactionDate must be YYYY-MM-DD'),
  body('accountId')
    .optional({ values: 'falsy' })
    .isUUID()
    .withMessage('accountId must be a valid UUID'),
  body('note')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Note must be at most 500 characters'),
  body('iconKey')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 80 })
    .withMessage('iconKey must be at most 80 characters'),
];

const updateTransactionValidation = [
  ...transactionIdValidation,
  body('type')
    .optional()
    .isIn(TransactionModel.allowedTypes)
    .withMessage('Type must be Income or Expense'),
  body('title')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Title cannot be empty')
    .isLength({ max: 150 })
    .withMessage('Title must be at most 150 characters'),
  body('category')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Category cannot be empty')
    .isLength({ max: 100 })
    .withMessage('Category must be at most 100 characters')
    .custom((value, { req }) => {
      if (req.body.type && !TransactionModel.isValidCategory(req.body.type, value)) {
        throw new Error(`Category "${value}" is invalid for type "${req.body.type}"`);
      }
      return true;
    }),
  body('amount')
    .optional()
    .isFloat({ gt: 0 })
    .withMessage('Amount must be greater than 0'),
  body('transactionDate')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('transactionDate must be YYYY-MM-DD'),
  body('accountId')
    .optional({ nullable: true })
    .custom((value) => value === null || typeof value === 'string')
    .withMessage('accountId must be a UUID string or null'),
  body('note')
    .optional({ nullable: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Note must be at most 500 characters'),
  body('iconKey')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 80 })
    .withMessage('iconKey must be at most 80 characters'),
];

router.get(
  '/summary',
  summaryValidation,
  asyncHandler(TransactionController.getSummary)
);

router.get(
  '/analytics',
  analyticsValidation,
  asyncHandler(TransactionController.getAnalytics)
);

router.get(
  '/',
  listTransactionsValidation,
  asyncHandler(TransactionController.listTransactions)
);

router.get(
  '/:transactionId',
  transactionIdValidation,
  asyncHandler(TransactionController.getTransaction)
);

router.post(
  '/',
  createTransactionValidation,
  asyncHandler(TransactionController.createTransaction)
);

router.patch(
  '/:transactionId',
  updateTransactionValidation,
  asyncHandler(TransactionController.updateTransaction)
);

router.delete(
  '/:transactionId',
  transactionIdValidation,
  asyncHandler(TransactionController.deleteTransaction)
);

module.exports = router;

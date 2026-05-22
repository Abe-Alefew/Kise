const { body, param, query } = require('express-validator');
const DebtModel = require('../models/Debt.model');

const debtIdValidation = [
  param('debtId')
    .trim()
    .notEmpty()
    .withMessage('Debt id is required')
    .isUUID()
    .withMessage('Debt id must be a valid UUID'),
];

const listDebtsValidation = [
  query('filter')
    .optional()
    .isIn(['all', 'active', 'lent', 'borrowed', 'settled'])
    .withMessage('filter must be one of: all, active, lent, borrowed, settled'),
];

const createDebtValidation = [
  body('personName')
    .trim()
    .notEmpty()
    .withMessage("Person's name is required")
    .isLength({ max: 120 })
    .withMessage("Person's name must be at most 120 characters"),
  body('type')
    .trim()
    .notEmpty()
    .withMessage('Debt type is required')
    .isIn(DebtModel.allowedTypes)
    .withMessage(`type must be one of: ${DebtModel.allowedTypes.join(', ')}`),
  body('totalAmount')
    .notEmpty()
    .withMessage('Total amount is required')
    .isFloat({ min: 0 })
    .withMessage('Total amount cannot be negative'),
  body('paidAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Paid amount cannot be negative')
    .custom((value, { req }) => {
      if (value !== undefined && Number(value) > Number(req.body.totalAmount)) {
        throw new Error('Paid amount cannot exceed total amount');
      }
      return true;
    }),
  body('debtDate')
    .trim()
    .notEmpty()
    .withMessage('Debt date is required')
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('debtDate must be YYYY-MM-DD'),
  body('notes')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be at most 500 characters'),
];

const updateDebtValidation = [
  ...debtIdValidation,
  body('personName')
    .optional()
    .trim()
    .notEmpty()
    .withMessage("Person's name cannot be empty")
    .isLength({ max: 120 })
    .withMessage("Person's name must be at most 120 characters"),
  body('type')
    .optional()
    .isIn(DebtModel.allowedTypes)
    .withMessage(`type must be one of: ${DebtModel.allowedTypes.join(', ')}`),
  body('totalAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Total amount cannot be negative'),
  body('paidAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Paid amount cannot be negative'),
  body('debtDate')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('debtDate must be YYYY-MM-DD'),
  body('notes')
    .optional({ nullable: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be at most 500 characters'),
];

const createPaymentValidation = [
  ...debtIdValidation,
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ gt: 0 })
    .withMessage('Amount must be greater than 0'),
  body('paymentDate')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('paymentDate must be YYYY-MM-DD'),
  body('notes')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be at most 500 characters'),
];

module.exports = {
  debtIdValidation,
  listDebtsValidation,
  createDebtValidation,
  updateDebtValidation,
  createPaymentValidation,
};

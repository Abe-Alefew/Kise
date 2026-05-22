const { body, param, query } = require('express-validator');
const GoalModel = require('../models/Goal.model');

const goalIdValidation = [
  param('goalId')
    .trim()
    .notEmpty()
    .withMessage('Goal id is required')
    .isUUID()
    .withMessage('Goal id must be a valid UUID'),
];

const listGoalsValidation = [
  query('status')
    .optional()
    .isIn(['all', 'active', 'completed', 'canceled'])
    .withMessage('status must be one of: all, active, completed, canceled'),
];

const createGoalValidation = [
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 150 })
    .withMessage('Title must be at most 150 characters'),
  body('period')
    .trim()
    .notEmpty()
    .withMessage('Period is required')
    .isIn(GoalModel.allowedPeriods)
    .withMessage(
      `Period must be one of: ${GoalModel.allowedPeriods.join(', ')}`
    ),
  body('targetAmount')
    .notEmpty()
    .withMessage('Target amount is required')
    .isFloat({ gt: 0 })
    .withMessage('Target amount must be greater than 0'),
  body('currentAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Current amount cannot be negative'),
  body('dueDate')
    .trim()
    .notEmpty()
    .withMessage('Due date is required')
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('dueDate must be YYYY-MM-DD'),
  body('note')
    .optional({ values: 'falsy' })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Note must be at most 500 characters'),
  body('isLocked')
    .optional()
    .isBoolean()
    .withMessage('isLocked must be a boolean'),
  body('status')
    .optional()
    .isIn(GoalModel.allowedStatuses)
    .withMessage(
      `status must be one of: ${GoalModel.allowedStatuses.join(', ')}`
    ),
];

const updateGoalValidation = [
  ...goalIdValidation,
  body('title')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Title cannot be empty')
    .isLength({ max: 150 })
    .withMessage('Title must be at most 150 characters'),
  body('period')
    .optional()
    .isIn(GoalModel.allowedPeriods)
    .withMessage(
      `Period must be one of: ${GoalModel.allowedPeriods.join(', ')}`
    ),
  body('targetAmount')
    .optional()
    .isFloat({ gt: 0 })
    .withMessage('Target amount must be greater than 0'),
  body('currentAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Current amount cannot be negative'),
  body('dueDate')
    .optional()
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('dueDate must be YYYY-MM-DD'),
  body('note')
    .optional({ nullable: true })
    .trim()
    .isLength({ max: 500 })
    .withMessage('Note must be at most 500 characters'),
  body('isLocked')
    .optional()
    .isBoolean()
    .withMessage('isLocked must be a boolean'),
  body('status')
    .optional()
    .isIn(GoalModel.allowedStatuses)
    .withMessage(
      `status must be one of: ${GoalModel.allowedStatuses.join(', ')}`
    ),
];

const toggleLockValidation = [
  ...goalIdValidation,
  body('isLocked')
    .notEmpty()
    .withMessage('isLocked is required')
    .isBoolean()
    .withMessage('isLocked must be a boolean'),
];

const createDepositValidation = [
  ...goalIdValidation,
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ gt: 0 })
    .withMessage('Amount must be greater than 0'),
  body('source')
    .trim()
    .notEmpty()
    .withMessage('Source is required')
    .isLength({ max: 100 })
    .withMessage('Source must be at most 100 characters'),
  body('accountId')
    .optional({ values: 'falsy' })
    .isUUID()
    .withMessage('accountId must be a valid UUID'),
  body('depositedAt')
    .optional()
    .isISO8601()
    .withMessage('depositedAt must be a valid ISO-8601 datetime'),
];

module.exports = {
  goalIdValidation,
  listGoalsValidation,
  createGoalValidation,
  updateGoalValidation,
  toggleLockValidation,
  createDepositValidation,
};

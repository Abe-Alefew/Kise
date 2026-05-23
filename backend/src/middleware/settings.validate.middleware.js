const { body, param, query } = require('express-validator');
const UserPreferenceModel = require('../models/UserPreference.model');

const accountIdValidation = [
  param('accountId')
    .trim()
    .notEmpty()
    .withMessage('Account id is required')
    .isUUID()
    .withMessage('Account id must be a valid UUID'),
];

const createAccountValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Account name is required')
    .isLength({ max: 100 })
    .withMessage('Account name must be at most 100 characters'),
  body('type')
    .trim()
    .notEmpty()
    .withMessage('Account type is required')
    .isLength({ max: 50 })
    .withMessage('Account type must be at most 50 characters'),
];

const updateAllowanceValidation = [
  body('monthlyAmount')
    .notEmpty()
    .withMessage('monthlyAmount is required')
    .isFloat({ min: 0 })
    .withMessage('monthlyAmount cannot be negative'),
  body('cycleStartDay')
    .notEmpty()
    .withMessage('cycleStartDay is required')
    .isInt({ min: 1, max: 28 })
    .withMessage('cycleStartDay must be between 1 and 28'),
];

const updatePreferencesValidation = [
  body('preferredLanguage')
    .optional()
    .isIn(UserPreferenceModel.allowedLanguages)
    .withMessage('preferredLanguage must be English or Amharic'),
  body('themeMode')
    .optional()
    .isIn(UserPreferenceModel.allowedThemeModes)
    .withMessage('themeMode must be light, dark, or system'),
];

module.exports = {
  accountIdValidation,
  createAccountValidation,
  updateAllowanceValidation,
  updatePreferencesValidation,
};

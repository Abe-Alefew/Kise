const express = require('express');
<<<<<<< HEAD
const { body } = require('express-validator');
const SettingsController = require('../controllers/settings.controller');
const UserPreferenceModel = require('../models/UserPreference.model');
=======
const { body, param } = require('express-validator');
const SettingsController = require('../controllers/settings.controller');
const PaymentAccountModel = require('../models/PaymentAccount.model');
>>>>>>> 9f5909d5ffab0a7c07304ed16c57780b578c4a77
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

<<<<<<< HEAD
router.get('/allowance', asyncHandler(SettingsController.getAllowance));

router.put(
  '/allowance',
  [
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
  ],
  asyncHandler(SettingsController.updateAllowance)
);

router.get('/preferences', asyncHandler(SettingsController.getPreferences));

router.patch(
  '/preferences',
  [
    body('preferredLanguage')
      .optional()
      .isIn(UserPreferenceModel.allowedLanguages)
      .withMessage('preferredLanguage must be English or Amharic'),
    body('themeMode')
      .optional()
      .isIn(UserPreferenceModel.allowedThemeModes)
      .withMessage('themeMode must be light, dark, or system'),
  ],
  asyncHandler(SettingsController.updatePreferences)
);

module.exports = router;
=======
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
    .isIn(PaymentAccountModel.allowedTypes)
    .withMessage(
      `Account type must be one of: ${PaymentAccountModel.allowedTypes.join(', ')}`
    ),
];

const accountIdValidation = [
  param('accountId')
    .trim()
    .notEmpty()
    .withMessage('Account id is required')
    .isUUID()
    .withMessage('Account id must be a valid UUID'),
];

router.get('/accounts', asyncHandler(SettingsController.listAccounts));

router.post(
  '/accounts',
  createAccountValidation,
  asyncHandler(SettingsController.createAccount)
);

router.delete(
  '/accounts/:accountId',
  accountIdValidation,
  asyncHandler(SettingsController.deleteAccount)
);

module.exports = router;
>>>>>>> 9f5909d5ffab0a7c07304ed16c57780b578c4a77

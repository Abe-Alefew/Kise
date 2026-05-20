const express = require('express');
const { body } = require('express-validator');
const SettingsController = require('../controllers/settings.controller');
const UserPreferenceModel = require('../models/UserPreference.model');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

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
const express = require("express");
const router = express.Router();
const settingsController = require("../controllers/settings.controller");
const settingsValidator = require("../validators/settings.validator");
const authMiddleware = require("../middleware/auth.middleware");
const validateMiddleware = require("../middleware/validate.middleware");

router.use(authMiddleware);

// Allowance
router.get("/allowance", settingsController.getAllowance);
router.put(
  "/allowance",
  settingsValidator.updateAllowanceValidator,
  validateMiddleware,
  settingsController.updateAllowance
);

// Payment Accounts
router.get("/accounts", settingsController.getAccounts);
router.post(
  "/accounts",
  settingsValidator.createAccountValidator,
  validateMiddleware,
  settingsController.createAccount
);
router.delete("/accounts/:accountId", settingsController.deleteAccount);

// Preferences
router.patch(
  "/preferences",
  settingsValidator.updatePreferencesValidator,
  validateMiddleware,
  settingsController.updatePreferences
);

module.exports = router;

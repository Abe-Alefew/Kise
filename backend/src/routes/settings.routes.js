const express = require('express');
const SettingsController = require('../controllers/settings.controller');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const {
  accountIdValidation,
  createAccountValidation,
  updateAllowanceValidation,
  updatePreferencesValidation,
} = require('../middleware/settings.validate.middleware');

const router = express.Router();

router.use(authenticate);

// Payment accounts
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

// Allowance
router.get('/allowance', asyncHandler(SettingsController.getAllowance));

router.put(
  '/allowance',
  updateAllowanceValidation,
  asyncHandler(SettingsController.updateAllowance)
);

// Preferences
router.get('/preferences', asyncHandler(SettingsController.getPreferences));

router.patch(
  '/preferences',
  updatePreferencesValidation,
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

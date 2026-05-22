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

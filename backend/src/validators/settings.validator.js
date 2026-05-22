const { body } = require("express-validator");

exports.updateAllowanceValidator = [
  body("monthlyAmount")
    .isFloat({ min: 0 })
    .withMessage("Monthly amount must be a positive number"),
  body("cycleStartDay")
    .isInt({ min: 1, max: 28 })
    .withMessage("Cycle start day must be between 1 and 28")
];

exports.createAccountValidator = [
  body("name").trim().notEmpty().withMessage("Account name is required"),
  body("type")
    .trim()
    .notEmpty()
    .withMessage("Account type is required")
    .isIn(["Bank", "Mobile Money", "Wallet", "Other"])
    .withMessage("Type must be Bank, Mobile Money, Wallet, or Other")
];

exports.updatePreferencesValidator = [
  body("preferredLanguage")
    .optional()
    .trim()
    .isIn(["English", "Amharic"])
    .withMessage("Language must be English or Amharic"),
  body("themeMode")
    .optional()
    .trim()
    .isIn(["light", "dark", "system"])
    .withMessage("Theme mode must be light, dark, or system")
];

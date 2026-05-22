const { body } = require("express-validator");

exports.createGoalValidator = [
  body("title").trim().notEmpty().withMessage("Title is required"),
  body("targetAmount").isFloat({ min: 1 }).withMessage("Target amount must be greater than 0"),
  body("period")
    .trim()
    .isIn(["daily", "weekly", "monthly", "yearly", "one-time"])
    .withMessage("Invalid period"),
  body("dueDate").isISO8601().withMessage("Valid due date (ISO) is required"),
  body("currentAmount").optional().isFloat({ min: 0 })
];

exports.updateGoalValidator = [
  body("title").optional().trim().notEmpty(),
  body("targetAmount").optional().isFloat({ min: 1 }),
  body("period").optional().isIn(["daily", "weekly", "monthly", "yearly", "one-time"]),
  body("dueDate").optional().isISO8601(),
  body("status").optional().isIn(["active", "completed", "canceled"]),
  body("isLocked").optional().isBoolean()
];

exports.depositValidator = [
  body("amount").isFloat({ min: 1 }).withMessage("Amount must be greater than 0"),
  body("source").trim().notEmpty().withMessage("Source is required"),
  body("accountId").optional().isUUID()
];

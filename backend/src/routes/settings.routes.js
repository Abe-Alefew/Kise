const express = require('express');
const { body, param } = require('express-validator');
const SettingsController = require('../controllers/settings.controller');
const PaymentAccountModel = require('../models/PaymentAccount.model');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

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
const express = require('express');
const { body } = require('express-validator');
const UserController = require('../controllers/user.controller');
const UserPreferenceModel = require('../models/UserPreference.model');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// Apply the authentication guard across all profile management pathways
router.use(authenticate);

// GET /api/v1/users/me -> Retrieve logged-in user's profile info
router.get('/me', asyncHandler(UserController.getProfile));

// PATCH /api/v1/users/me -> Update profile fields and UI configurations safely
router.patch(
  '/me',
  [
    body('firstName').optional().trim().isLength({ min: 1, max: 100 }).withMessage('First name must be between 1 and 100 characters'),
    body('lastName').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Last name must be between 1 and 100 characters'),
    body('phone').optional({ values: 'falsy' }).trim().isLength({ max: 30 }).withMessage('Phone number is too long'),
    body('preferredLanguage')
      .optional()
      .isIn(UserPreferenceModel.allowedLanguages)
      .withMessage('Language must be either English or Amharic'),
    body('currency').optional().isIn(['ETB', 'USD']).withMessage('Currency must be ETB or USD'),
  ],
  asyncHandler(UserController.updateProfile)
);

// DELETE /api/v1/users/me -> Wipe out user record completely from the system
router.delete('/me', asyncHandler(UserController.deleteAccount));

module.exports = router;
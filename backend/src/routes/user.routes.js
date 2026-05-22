const express = require('express');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const UserController = require('../controllers/user.controller');

const router = express.Router();

router.get('/me', authenticate, asyncHandler(UserController.getProfile));
router.delete('/me', authenticate, asyncHandler(UserController.deleteAccount));

module.exports = router;
const express = require('express');
const { body } = require('express-validator');
const UserModel = require('../models/User.model');
const UserPreferenceModel = require('../models/UserPreference.model');
const RefreshTokenModel = require('../models/RefreshToken.model');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');

const router = express.Router();

router.use(authenticate);

function createHttpError(statusCode, code, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  return error;
}

router.get(
  '/me',
  asyncHandler(async (req, res) => {
    const user = await UserModel.findPublicById(req.user.id);
    if (!user) {
      throw createHttpError(404, 'NOT_FOUND', 'User not found');
    }

    const preferences = await UserPreferenceModel.findByUserId(req.user.id);

    return sendSuccess(res, 200, {
      ...user,
      preferredLanguage: preferences
        ? preferences.preferredLanguage
        : 'English',
      themeMode: preferences ? preferences.themeMode : 'system',
    });
  })
);

router.patch(
  '/me',
  [
    body('firstName').optional().trim().isLength({ min: 1, max: 100 }),
    body('lastName').optional().trim().isLength({ min: 1, max: 100 }),
    body('phone').optional({ values: 'falsy' }).trim().isLength({ max: 30 }),
    body('preferredLanguage')
      .optional()
      .isIn(UserPreferenceModel.allowedLanguages),
    body('currency').optional().isIn(['ETB', 'USD']),
  ],
  asyncHandler(async (req, res, next) => {
    const user = await UserModel.findById(req.user.id);
    if (!user) {
      throw createHttpError(404, 'NOT_FOUND', 'User not found');
    }

    const db = require('../config/database');
    const now = new Date().toISOString();

    await db.run(
      `
        UPDATE users
        SET
          first_name = ?,
          last_name = ?,
          phone = ?,
          currency = ?,
          updated_at = ?
        WHERE id = ?;
      `,
      [
        req.body.firstName !== undefined ? req.body.firstName.trim() : user.firstName,
        req.body.lastName !== undefined ? req.body.lastName.trim() : user.lastName,
        req.body.phone !== undefined ? req.body.phone : user.phone,
        req.body.currency !== undefined ? req.body.currency : user.currency,
        now,
        req.user.id,
      ]
    );

    if (req.body.preferredLanguage !== undefined) {
      await UserPreferenceModel.update(req.user.id, {
        preferredLanguage: req.body.preferredLanguage,
      });
    }

    const updatedUser = await UserModel.findPublicById(req.user.id);
    const preferences = await UserPreferenceModel.findByUserId(req.user.id);

    return sendSuccess(res, 200, {
      ...updatedUser,
      preferredLanguage: preferences
        ? preferences.preferredLanguage
        : 'English',
      themeMode: preferences ? preferences.themeMode : 'system',
    });
  })
);

router.delete(
  '/me',
  asyncHandler(async (req, res) => {
    await RefreshTokenModel.revokeAllForUser(req.user.id);

    const db = require('../config/database');
    await db.run('DELETE FROM users WHERE id = ?;', [req.user.id]);

    return sendSuccess(res, 200, { message: 'Account deleted successfully' });
  })
);

module.exports = router;
const db = require('../config/database');
const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const UserService = require('../services/user.service');
const UserPreferenceModel = require('../models/UserPreference.model');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}


class UserController {
  static async getProfile(req, res, next) {
    try {
      if (!req.user || !req.user.id) {
        return sendError(res, 401, 'UNAUTHORIZED', 'Authentication required');
      }

      const profile = await UserService.getUserProfile(req.user.id);
      return sendSuccess(res, 200, { user: profile });
    } catch (error) {
      return next(error);
    }
  }

  static async updateProfile(req, res, next) {
    try {
      if (!req.user || !req.user.id) {
        return sendError(res, 401, 'UNAUTHORIZED', 'Authentication required');
      }

      const validationErrors = collectValidationErrors(req);
      if (validationErrors) {
        return sendError(
          res,
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          validationErrors
        );
      }

      const updates = [];
      const values = [];

      if (req.body.firstName !== undefined) {
        updates.push('first_name = ?');
        values.push(req.body.firstName.trim());
      }

      if (req.body.lastName !== undefined) {
        updates.push('last_name = ?');
        values.push(req.body.lastName.trim());
      }

      if (req.body.phone !== undefined) {
        updates.push('phone = ?');
        values.push(req.body.phone ? req.body.phone.trim() : null);
      }

      if (req.body.currency !== undefined) {
        updates.push('currency = ?');
        values.push(req.body.currency);
      }

      if (updates.length === 0 && req.body.preferredLanguage === undefined) {
        throw createHttpError(400, 'BAD_REQUEST', 'No profile fields were provided');
      }

      const userExists = await db.get('SELECT id FROM users WHERE id = ? LIMIT 1;', [req.user.id]);
      if (!userExists) {
        throw createHttpError(404, 'NOT_FOUND', 'User not found');
      }

      const now = new Date().toISOString();

      await db.run('BEGIN IMMEDIATE TRANSACTION;');

      try {
        if (updates.length > 0) {
          updates.push('updated_at = ?');
          values.push(now, req.user.id);

          await db.run(
            `
              UPDATE users
              SET ${updates.join(', ')}
              WHERE id = ?;
            `,
            values
          );
        }

        if (req.body.preferredLanguage !== undefined) {
          const existingPreferences = await UserPreferenceModel.findByUserId(req.user.id);
          if (existingPreferences) {
            await UserPreferenceModel.update(req.user.id, {
              preferredLanguage: req.body.preferredLanguage,
            });
          } else {
            await UserPreferenceModel.createDefault(req.user.id, req.body.preferredLanguage);
          }
        }

        await db.run('COMMIT;');
      } catch (error) {
        await db.run('ROLLBACK;');
        throw error;
      }

      const profile = await UserService.getUserProfile(req.user.id);
      return sendSuccess(res, 200, { user: profile });
    } catch (error) {
      return next(error);
    }
  }

  static async deleteAccount(req, res, next) {
    try {
      if (!req.user || !req.user.id) {
        return sendError(res, 401, 'UNAUTHORIZED', 'Authentication required');
      }

      await UserService.deleteUserAccount(req.user.id);
      return sendSuccess(res, 200, { message: 'Account deleted successfully' });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = UserController;

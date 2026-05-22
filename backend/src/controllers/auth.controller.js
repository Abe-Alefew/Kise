const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const AuthService = require('../services/auth.service');

class AuthController {
  static async register(req, res, next) {
    try {
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

      const result = await AuthService.register(req.body);
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  }

  static async login(req, res, next) {
    try {
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

      const result = await AuthService.login(req.body);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }

  static async refresh(req, res, next) {
    try {
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

      const result = await AuthService.refresh(req.body.refreshToken);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }

  static async logout(req, res, next) {
    try {
      await AuthService.logout(req.body.refreshToken);
      return sendSuccess(res, 200, { message: 'Logged out successfully' });
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = AuthController;
const PaymentAccountModel = require('../models/PaymentAccount.model');
const AllowanceModel = require('../models/Allowance.model');
const UserPreferenceModel = require('../models/UserPreference.model');
const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}

function mapAccountResponse(account) {
  return {
    id: account.id,
    name: account.name,
    type: account.type,
    createdAt: account.createdAt,
    updatedAt: account.updatedAt,
  };
}

function normalizeAccountType(type) {
  if (typeof type !== 'string') {
    return null;
  }

  const normalized = type.trim().toLowerCase();
  return PaymentAccountModel.allowedTypes.find(
    (allowedType) => allowedType.toLowerCase() === normalized
  );
}

function mapAllowanceResponse(allowance) {
  return {
    monthlyAmount: allowance.monthlyAmount,
    cycleStartDay: allowance.cycleStartDay,
    isConfigured: allowance.monthlyAmount > 0,
    updatedAt: allowance.updatedAt,
  };
}

function mapPreferencesResponse(preferences) {
  return {
    preferredLanguage: preferences.preferredLanguage,
    themeMode: preferences.themeMode,
    updatedAt: preferences.updatedAt,
  };
}

class SettingsController {
  static async listAccounts(req, res, next) {
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

      const accounts = await PaymentAccountModel.findAllByUserId(req.user.id);
      return sendSuccess(res, 200, accounts.map(mapAccountResponse));
    } catch (error) {
      return next(error);
    }
  }

  static async createAccount(req, res, next) {
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

      const duplicate = await PaymentAccountModel.findByName(req.user.id, req.body.name);
      if (duplicate) {
        throw createHttpError(
          409,
          'CONFLICT',
          'A payment account with this name already exists'
        );
      }

      const accountType = normalizeAccountType(req.body.type);
      if (!accountType) {
        throw createHttpError(
          400,
          'VALIDATION_ERROR',
          'Invalid payment account type',
          {
            type: 'type must be one of Bank, Mobile Money, Wallet, or Other',
          }
        );
      }

      const account = await PaymentAccountModel.create(req.user.id, {
        name: req.body.name,
        type: accountType,
      });

      return sendSuccess(res, 201, mapAccountResponse(account));
    } catch (error) {
      return next(error);
    }
  }

  static async deleteAccount(req, res, next) {
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

      const account = await PaymentAccountModel.findById(req.user.id, req.params.accountId);
      if (!account) {
        throw createHttpError(404, 'NOT_FOUND', 'Payment account not found');
      }

      const linkedCount = await PaymentAccountModel.countTransactionsLinked(
        req.user.id,
        req.params.accountId
      );

      if (linkedCount > 0) {
        throw createHttpError(
          409,
          'CONFLICT',
          'Cannot delete an account that is linked to existing transactions'
        );
      }

      await PaymentAccountModel.delete(req.user.id, req.params.accountId);
      return sendSuccess(res, 200, { message: 'Payment account deleted successfully' });
    } catch (error) {
      return next(error);
    }
  }

  static async getAllowance(req, res, next) {
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

      let allowance = await AllowanceModel.findByUserId(req.user.id);
      if (!allowance) {
        allowance = await AllowanceModel.createDefault(req.user.id);
      }

      return sendSuccess(res, 200, mapAllowanceResponse(allowance));
    } catch (error) {
      return next(error);
    }
  }

  static async updateAllowance(req, res, next) {
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

      const allowance = await AllowanceModel.upsert(req.user.id, {
        monthlyAmount: Number(req.body.monthlyAmount),
        cycleStartDay: Number(req.body.cycleStartDay),
      });

      return sendSuccess(res, 200, mapAllowanceResponse(allowance));
    } catch (error) {
      return next(error);
    }
  }

  static async getPreferences(req, res, next) {
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

      let preferences = await UserPreferenceModel.findByUserId(req.user.id);
      if (!preferences) {
        preferences = await UserPreferenceModel.createDefault(req.user.id, 'English');
      }

      return sendSuccess(res, 200, mapPreferencesResponse(preferences));
    } catch (error) {
      return next(error);
    }
  }

  static async updatePreferences(req, res, next) {
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

      const preferences = await UserPreferenceModel.update(req.user.id, {
        preferredLanguage: req.body.preferredLanguage,
        themeMode: req.body.themeMode,
      });

      return sendSuccess(res, 200, mapPreferencesResponse(preferences));
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = SettingsController;

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

      const account = await PaymentAccountModel.create(req.user.id, {
        name: req.body.name,
        type: req.body.type,
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
}

module.exports = SettingsController;
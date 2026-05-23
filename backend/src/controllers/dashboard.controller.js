const DashboardService = require('../services/dashboard.service');
const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendSuccess, sendError } = require('../utils/apiResponse');

class DashboardController {
  static async getHome(req, res, next) {
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
      

      const bundle = await DashboardService.getHomeBundle(req.user.id, {
        range: req.query.range || '6m',
      });

      return sendSuccess(res, 200, bundle);
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = DashboardController;
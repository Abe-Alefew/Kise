const { sendSuccess, sendError } = require('../utils/apiResponse');
const UserService = require('../services/user.service');

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

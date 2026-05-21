const jwt = require('jsonwebtoken');
const config = require('../config');
const UserModel = require('../models/User.model');
const { sendError } = require('../utils/apiResponse');

async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(
      res,
      401,
      'UNAUTHORIZED',
      'Authentication required. Provide a valid Bearer access token.'
    );
  }

  const token = authHeader.slice(7).trim();

  if (!token) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Authentication token is missing.');
  }

  try {
    const payload = jwt.verify(token, config.jwt.accessSecret);

    if (!payload.sub) {
      return sendError(res, 401, 'UNAUTHORIZED', 'Invalid access token payload.');
    }

    const user = await UserModel.findById(payload.sub);

    if (!user) {
      return sendError(res, 401, 'UNAUTHORIZED', 'User no longer exists.');
    }

    req.user = {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    };

    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendError(res, 401, 'UNAUTHORIZED', 'Access token has expired.');
    }

    if (err.name === 'JsonWebTokenError') {
      return sendError(res, 401, 'UNAUTHORIZED', 'Invalid access token.');
    }

    return next(err);
  }
}

module.exports = {
  authenticate,
};
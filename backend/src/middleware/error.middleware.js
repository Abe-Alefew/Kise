const { validationResult } = require('express-validator');
const { sendError } = require('../utils/apiResponse');

function collectValidationErrors(req) {
  const result = validationResult(req);
  if (result.isEmpty()) {
    return null;
  }

  return result.array().map((item) => ({
    field: item.path,
    message: item.msg,
  }));
}

function notFoundHandler(req, res) {
  return sendError(res, 404, 'NOT_FOUND', `Route ${req.method} ${req.originalUrl} not found`);
}

function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  if (err.name === 'ValidationError') {
    return sendError(res, 400, 'VALIDATION_ERROR', err.message, err.details);
  }

  if (err.code === 'SQLITE_CONSTRAINT' && String(err.message).includes('users.email')) {
    return sendError(res, 409, 'CONFLICT', 'An account with this email already exists');
  }

  if (err.statusCode) {
    return sendError(res, err.statusCode, err.code || 'REQUEST_ERROR', err.message, err.details);
  }

  if (process.env.NODE_ENV !== 'production') {
    console.error(err);
  }

  return sendError(res, 500, 'INTERNAL_ERROR', 'An unexpected error occurred');
}

module.exports = {
  collectValidationErrors,
  notFoundHandler,
  errorHandler,
};
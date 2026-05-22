const { collectValidationErrors } = require('../middleware/error.middleware');
const { sendError } = require('./apiResponse');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}

function handleValidation(req, res) {
  const validationErrors = collectValidationErrors(req);
  if (validationErrors) {
    sendError(
      res,
      400,
      'VALIDATION_ERROR',
      'Request validation failed',
      validationErrors
    );
    return true;
  }
  return false;
}

module.exports = {
  createHttpError,
  handleValidation,
};

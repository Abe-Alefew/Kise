const express = require('express');
const AuthController = require('../controllers/auth.controller');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const {
  registerValidation,
  loginValidation,
  refreshValidation,
  logoutValidation,
} = require('../validators/auth.validator');
const { body } = require('express-validator');

const router = express.Router();





router.post('/register', registerValidation, asyncHandler(AuthController.register));
router.post('/login', loginValidation, asyncHandler(AuthController.login));
router.post('/refresh', refreshValidation, asyncHandler(AuthController.refresh));
router.post('/logout', logoutValidation, asyncHandler(AuthController.logout));

router.get('/me', authenticate, asyncHandler(async (req, res) => {
  const UserModel = require('../models/User.model');
  const user = await UserModel.findPublicById(req.user.id);
  const preferences = await UserModel.getPreferences(req.user.id);

  return require('../utils/apiResponse').sendSuccess(res, 200, {
    user: {
      ...user,
      preferredLanguage: preferences ? preferences.preferredLanguage : 'English',
    },
  });
}));

module.exports = router;
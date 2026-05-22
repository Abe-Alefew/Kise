const express = require('express');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const UserController = require('../controllers/user.controller');

const router = express.Router();

router.get('/me', authenticate, asyncHandler(UserController.getProfile));
router.delete('/me', authenticate, asyncHandler(UserController.deleteAccount));

module.exports = router;

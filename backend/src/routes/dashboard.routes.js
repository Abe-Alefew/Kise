const express = require('express');
const { query } = require('express-validator');
const DashboardController = require('../controllers/dashboard.controller');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

const homeValidation = [
  query('range')
    .optional()
    .isIn(['1m', '3m', '6m', '1y'])
    .withMessage('range must be one of: 1m, 3m, 6m, 1y'),
];

router.get('/home', homeValidation, asyncHandler(DashboardController.getHome));

module.exports = router;
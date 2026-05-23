const express = require('express');

const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const settingsRoutes = require('./settings.routes');
const transactionRoutes = require('./transaction.routes');
const goalRoutes = require('./goal.routes');
const debtRoutes = require('./debt.routes');
const dashboardRoutes = require('./dashboard.routes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      timestamp: new Date().toISOString(),
    },
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/settings', settingsRoutes);
// router.use('/transactions', transactionRoutes);
router.use('/goals', goalRoutes);
router.use('/debts', debtRoutes);
router.use('/dashboard', dashboardRoutes);

module.exports = router;
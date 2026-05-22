const express = require('express');
const DebtController = require('../controllers/debt.controller');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { debtIdValidation, listDebtsValidation, createDebtValidation, updateDebtValidation, createPaymentValidation, } = require('../middleware/debt.validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/summary', asyncHandler(DebtController.getSummary));
router.get('/analytics', asyncHandler(DebtController.getAnalytics));
router.get('/', listDebtsValidation, asyncHandler(DebtController.listDebts));

router.get(
  '/:debtId',
  debtIdValidation,
  asyncHandler(DebtController.getDebt)
);

router.post('/', createDebtValidation, asyncHandler(DebtController.createDebt));

router.patch(
  '/:debtId',
  updateDebtValidation,
  asyncHandler(DebtController.updateDebt)
);

router.delete(
  '/:debtId',
  debtIdValidation,
  asyncHandler(DebtController.deleteDebt)
);

router.get(
  '/:debtId/payments',
  debtIdValidation,
  asyncHandler(DebtController.listPayments)
);

router.post(
  '/:debtId/payments',
  createPaymentValidation,
  asyncHandler(DebtController.createPayment)
);

module.exports = router;
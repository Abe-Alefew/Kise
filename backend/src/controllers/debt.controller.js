const DebtModel = require('../models/Debt.model');
const DebtPaymentModel = require('../models/DebtPayment.model');
const { sendSuccess } = require('../utils/apiResponse');
const { createHttpError, handleValidation } = require('../utils/httpError');

function mapPaymentResponse(payment) {
  return {
    id: payment.id,
    amount: payment.amount,
    paymentDate: payment.paymentDate,
    notes: payment.notes,
    createdAt: payment.createdAt,
  };
}

function mapDebtResponse(debt) {
  return {
    id: debt.id,
    personName: debt.personName,
    personInitial: debt.personInitial,
    type: debt.type,
    totalAmount: debt.totalAmount,
    paidAmount: debt.paidAmount,
    remaining: debt.remaining,
    status: debt.status,
    debtDate: debt.debtDate,
    notes: debt.notes,
    payments: (debt.payments || []).map(mapPaymentResponse),
    createdAt: debt.createdAt,
    updatedAt: debt.updatedAt,
  };
}

class DebtController {
  static async listDebts(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const filter = req.query.filter || 'all';
      const debts = await DebtModel.findAllByUserId(req.user.id, filter, true);

      return sendSuccess(res, 200, debts.map(mapDebtResponse));
    } catch (error) {
      return next(error);
    }
  }

  static async getDebt(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const debt = await DebtModel.findById(req.user.id, req.params.debtId, true);
      if (!debt) {
        throw createHttpError(404, 'NOT_FOUND', 'Debt record not found');
      }

      return sendSuccess(res, 200, mapDebtResponse(debt));
    } catch (error) {
      return next(error);
    }
  }

  static async createDebt(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const debt = await DebtModel.create(req.user.id, {
        personName: req.body.personName,
        type: req.body.type,
        totalAmount: Number(req.body.totalAmount),
        paidAmount:
          req.body.paidAmount !== undefined ? Number(req.body.paidAmount) : 0,
        debtDate: req.body.debtDate,
        notes: req.body.notes,
      });

      return sendSuccess(res, 201, mapDebtResponse(debt));
    } catch (error) {
      if (String(error.message).includes('Paid amount cannot exceed')) {
        return next(
          createHttpError(
            422,
            'BUSINESS_RULE',
            'Paid amount cannot exceed total amount'
          )
        );
      }
      return next(error);
    }
  }

  static async updateDebt(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const existing = await DebtModel.findById(req.user.id, req.params.debtId, false);
      if (!existing) {
        throw createHttpError(404, 'NOT_FOUND', 'Debt record not found');
      }

      const debt = await DebtModel.update(req.user.id, req.params.debtId, {
        personName: req.body.personName,
        type: req.body.type,
        totalAmount:
          req.body.totalAmount !== undefined
            ? Number(req.body.totalAmount)
            : undefined,
        paidAmount:
          req.body.paidAmount !== undefined
            ? Number(req.body.paidAmount)
            : undefined,
        debtDate: req.body.debtDate,
        notes: req.body.notes,
      });

      return sendSuccess(res, 200, mapDebtResponse(debt));
    } catch (error) {
      if (String(error.message).includes('Paid amount cannot exceed')) {
        return next(
          createHttpError(
            422,
            'BUSINESS_RULE',
            'Paid amount cannot exceed total amount'
          )
        );
      }
      return next(error);
    }
  }

  static async deleteDebt(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const deleted = await DebtModel.delete(req.user.id, req.params.debtId);
      if (!deleted) {
        throw createHttpError(404, 'NOT_FOUND', 'Debt record not found');
      }

      return sendSuccess(res, 200, { message: 'Debt record deleted successfully' });
    } catch (error) {
      return next(error);
    }
  }

  static async getSummary(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const summary = await DebtModel.getSummary(req.user.id);
      return sendSuccess(res, 200, summary);
    } catch (error) {
      return next(error);
    }
  }

  static async getAnalytics(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const analytics = await DebtModel.getAnalytics(req.user.id);
      return sendSuccess(res, 200, analytics);
    } catch (error) {
      return next(error);
    }
  }

  static async createPayment(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const result = await DebtPaymentModel.createAndApply(
        req.user.id,
        req.params.debtId,
        {
          amount: Number(req.body.amount),
          paymentDate: req.body.paymentDate,
          notes: req.body.notes,
        }
      );

      if (result.error === 'DEBT_NOT_FOUND') {
        throw createHttpError(404, 'NOT_FOUND', 'Debt record not found');
      }

      if (result.error === 'OVERPAYMENT') {
        throw createHttpError(
          422,
          'BUSINESS_RULE',
          `Payment exceeds remaining balance of ${result.remaining} ETB`
        );
      }

      return sendSuccess(res, 200, {
        debt: mapDebtResponse(result.debt),
        payment: mapPaymentResponse(result.payment),
      });
    } catch (error) {
      return next(error);
    }
  }

  static async listPayments(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const debt = await DebtModel.findById(req.user.id, req.params.debtId, false);
      if (!debt) {
        throw createHttpError(404, 'NOT_FOUND', 'Debt record not found');
      }

      const payments = await DebtPaymentModel.findByDebtId(
        req.user.id,
        req.params.debtId
      );

      return sendSuccess(res, 200, payments.map(mapPaymentResponse));
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = DebtController;
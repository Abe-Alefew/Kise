const GoalModel = require('../models/Goal.model');
const GoalDepositModel = require('../models/GoalDeposit.model');
const PaymentAccountModel = require('../models/PaymentAccount.model');
const { sendSuccess } = require('../utils/apiResponse');
const { createHttpError, handleValidation } = require('../utils/httpError');

function mapGoalResponse(goal) {
  return {
    id: goal.id,
    title: goal.title,
    period: goal.period,
    dueDate: goal.dueDate,
    dueDateDisplay: goal.dueDateDisplay,
    currentAmount: goal.currentAmount,
    targetAmount: goal.targetAmount,
    progress: goal.progress,
    isCompleted: goal.isCompleted,
    isLocked: goal.isLocked,
    status: goal.status,
    note: goal.note,
    completedAt: goal.completedAt,
    createdAt: goal.createdAt,
    updatedAt: goal.updatedAt,
  };
}

function mapDepositResponse(deposit) {
  return {
    id: deposit.id,
    goalId: deposit.goalId,
    amount: deposit.amount,
    source: deposit.source,
    accountId: deposit.accountId,
    depositedAt: deposit.depositedAt,
    createdAt: deposit.createdAt,
  };
}

async function validateAccountOwnership(userId, accountId) {
  if (!accountId) {
    return null;
  }

  const account = await PaymentAccountModel.findById(userId, accountId);
  if (!account) {
    throw createHttpError(422, 'BUSINESS_RULE', 'Selected payment account does not exist');
  }

  return account;
}

class GoalController {
  static async listGoals(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const status = req.query.status || 'all';
      const goals = await GoalModel.findAllByUserId(req.user.id, status);

      return sendSuccess(res, 200, goals.map(mapGoalResponse));
    } catch (error) {
      return next(error);
    }
  }

  static async getGoal(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const goal = await GoalModel.findById(req.user.id, req.params.goalId);
      if (!goal) {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      const deposits = await GoalDepositModel.findByGoalId(req.user.id, goal.id);

      return sendSuccess(res, 200, {
        ...mapGoalResponse(goal),
        deposits: deposits.map(mapDepositResponse),
      });
    } catch (error) {
      return next(error);
    }
  }

  static async createGoal(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const goal = await GoalModel.create(req.user.id, {
        title: req.body.title,
        period: req.body.period,
        targetAmount: Number(req.body.targetAmount),
        currentAmount:
          req.body.currentAmount !== undefined
            ? Number(req.body.currentAmount)
            : 0,
        dueDate: req.body.dueDate,
        note: req.body.note,
        isLocked: req.body.isLocked || false,
        status: req.body.status,
      });

      return sendSuccess(res, 201, mapGoalResponse(goal));
    } catch (error) {
      return next(error);
    }
  }

  static async updateGoal(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const existing = await GoalModel.findById(req.user.id, req.params.goalId);
      if (!existing) {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      if (existing.isLocked && req.body.isLocked !== false) {
        const restrictedFields = ['title', 'targetAmount', 'currentAmount', 'period', 'dueDate'];
        const attemptedRestrictedUpdate = restrictedFields.some(
          (field) => req.body[field] !== undefined
        );

        if (attemptedRestrictedUpdate) {
          throw createHttpError(
            422,
            'BUSINESS_RULE',
            'This goal is locked and cannot be edited'
          );
        }
      }

      const goal = await GoalModel.update(req.user.id, req.params.goalId, {
        title: req.body.title,
        period: req.body.period,
        targetAmount:
          req.body.targetAmount !== undefined
            ? Number(req.body.targetAmount)
            : undefined,
        currentAmount:
          req.body.currentAmount !== undefined
            ? Number(req.body.currentAmount)
            : undefined,
        dueDate: req.body.dueDate,
        note: req.body.note,
        status: req.body.status,
        isLocked: req.body.isLocked,
      });

      return sendSuccess(res, 200, mapGoalResponse(goal));
    } catch (error) {
      return next(error);
    }
  }

  static async toggleLock(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const existing = await GoalModel.findById(req.user.id, req.params.goalId);
      if (!existing) {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      const goal = await GoalModel.setLocked(
        req.user.id,
        req.params.goalId,
        req.body.isLocked
      );

      return sendSuccess(res, 200, mapGoalResponse(goal));
    } catch (error) {
      return next(error);
    }
  }

  static async deleteGoal(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const deleted = await GoalModel.delete(req.user.id, req.params.goalId);
      if (!deleted) {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      return sendSuccess(res, 200, { message: 'Goal deleted successfully' });
    } catch (error) {
      return next(error);
    }
  }

  static async createDeposit(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      await validateAccountOwnership(req.user.id, req.body.accountId);

      const result = await GoalDepositModel.createAndApply(
        req.user.id,
        req.params.goalId,
        {
          amount: Number(req.body.amount),
          source: req.body.source,
          accountId: req.body.accountId || null,
          depositedAt: req.body.depositedAt,
        }
      );

      if (result.error === 'GOAL_NOT_FOUND') {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      if (result.error === 'GOAL_LOCKED') {
        throw createHttpError(
          422,
          'BUSINESS_RULE',
          'Deposits cannot be added to a locked goal'
        );
      }

      if (result.error === 'GOAL_CANCELED') {
        throw createHttpError(
          422,
          'BUSINESS_RULE',
          'Deposits cannot be added to a canceled goal'
        );
      }

      return sendSuccess(res, 201, {
        goal: mapGoalResponse(result.goal),
        deposit: mapDepositResponse(result.deposit),
      });
    } catch (error) {
      return next(error);
    }
  }

  static async listDeposits(req, res, next) {
    try {
      if (handleValidation(req, res)) return;

      const goal = await GoalModel.findById(req.user.id, req.params.goalId);
      if (!goal) {
        throw createHttpError(404, 'NOT_FOUND', 'Goal not found');
      }

      const deposits = await GoalDepositModel.findByGoalId(
        req.user.id,
        req.params.goalId
      );

      return sendSuccess(res, 200, deposits.map(mapDepositResponse));
    } catch (error) {
      return next(error);
    }
  }
}

module.exports = GoalController;
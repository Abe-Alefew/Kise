const express = require('express');
const GoalController = require('../controllers/goal.controller');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { goalIdValidation, listGoalsValidation, createGoalValidation, updateGoalValidation, toggleLockValidation, createDepositValidation, } = require('../middleware/goal.validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', listGoalsValidation, asyncHandler(GoalController.listGoals));

router.get(
  '/:goalId',
  goalIdValidation,
  asyncHandler(GoalController.getGoal)
);

router.post('/', createGoalValidation, asyncHandler(GoalController.createGoal));

router.patch(
  '/:goalId',
  updateGoalValidation,
  asyncHandler(GoalController.updateGoal)
);

router.patch(
  '/:goalId/lock',
  toggleLockValidation,
  asyncHandler(GoalController.toggleLock)
);

router.delete(
  '/:goalId',
  goalIdValidation,
  asyncHandler(GoalController.deleteGoal)
);

router.get(
  '/:goalId/deposits',
  goalIdValidation,
  asyncHandler(GoalController.listDeposits)
);

router.post(
  '/:goalId/deposits',
  createDepositValidation,
  asyncHandler(GoalController.createDeposit)
);

module.exports = router;
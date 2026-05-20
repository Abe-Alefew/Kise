const express = require("express");
const router = express.Router();
const goalController = require("../controllers/goal.controller");
const goalValidator = require("../validators/goal.validator");
const authMiddleware = require("../middleware/auth.middleware");
const validateMiddleware = require("../middleware/validate.middleware");

router.use(authMiddleware);

router.get("/", goalController.getGoals);
router.post(
  "/",
  goalValidator.createGoalValidator,
  validateMiddleware,
  goalController.createGoal
);

router.patch(
  "/:id",
  goalValidator.updateGoalValidator,
  validateMiddleware,
  goalController.updateGoal
);

router.delete("/:id", goalController.deleteGoal);

router.post(
  "/:id/deposits",
  goalValidator.depositValidator,
  validateMiddleware,
  goalController.addDeposit
);

module.exports = router;

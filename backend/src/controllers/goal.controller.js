const goalService = require("../services/goal.service");
const { validationResult } = require("express-validator");
const { successResponse, errorResponse } = require("../utils/apiResponse");

exports.getGoals = async (req, res, next) => {
  try {
    const status = req.query.status || 'all';
    const goals = await goalService.getGoals(req.user.id, status);
    res.status(200).json(successResponse(goals));
  } catch (error) {
    next(error);
  }
};

exports.createGoal = async (req, res, next) => {
  try {
    const goal = await goalService.createGoal(req.user.id, req.body);
    res.status(201).json(successResponse(goal));
  } catch (error) {
    next(error);
  }
};

exports.updateGoal = async (req, res, next) => {
  try {
    const goal = await goalService.updateGoal(req.params.id, req.user.id, req.body);
    res.status(200).json(successResponse(goal));
  } catch (error) {
    if (error.code === "NOT_FOUND") {
      return res.status(404).json(errorResponse("NOT_FOUND", error.message));
    }
    next(error);
  }
};

exports.deleteGoal = async (req, res, next) => {
  try {
    const deleted = await goalService.deleteGoal(req.params.id, req.user.id);
    if (!deleted) {
      return res.status(404).json(errorResponse("NOT_FOUND", "Goal not found"));
    }
    res.status(200).json(successResponse({ message: "Deleted" }));
  } catch (error) {
    next(error);
  }
};

exports.addDeposit = async (req, res, next) => {
  try {
    const data = await goalService.addDeposit(req.params.id, req.user.id, req.body);
    res.status(200).json(successResponse(data));
  } catch (error) {
    if (error.code === "NOT_FOUND") {
      return res.status(404).json(errorResponse("NOT_FOUND", error.message));
    }
    if (error.code === "BUSINESS_RULE") {
      return res.status(422).json(errorResponse("BUSINESS_RULE", error.message));
    }
    next(error);
  }
};

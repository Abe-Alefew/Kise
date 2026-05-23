const GoalModel = require("../models/Goal.model");
const GoalDepositModel = require("../models/GoalDeposit.model");
const { v4: uuidv4 } = require("uuid");

class GoalService {
  async getGoals(userId, status) {
    const goals = await GoalModel.findAllByUserId(userId, status);
    
    // Add computed properties
    return goals.map(g => {
      const isCompleted = g.current_amount >= g.target_amount || g.status === 'completed';
      const progress = g.target_amount > 0 ? (g.current_amount / g.target_amount) : 0;
      
      return {
        id: g.id,
        title: g.title,
        period: g.period,
        targetAmount: g.target_amount,
        currentAmount: g.current_amount,
        dueDate: g.due_date,
        note: g.note,
        status: isCompleted && g.status !== 'completed' ? 'completed' : g.status,
        isLocked: g.is_locked === 1,
        progress: Math.min(progress, 1.0),
        isCompleted
      };
    });
  }

  async createGoal(userId, data) {
    const id = uuidv4();
    const newGoal = await GoalModel.create(userId, { id, ...data });
    return this._formatGoal(newGoal);
  }

  async updateGoal(id, userId, data) {
    // Before updating, check if it exists
    const existing = await GoalModel.findById(id, userId);
    if (!existing) {
      throw { code: "NOT_FOUND", message: "Goal not found" };
    }

    // Map camelCase to snake_case for the model
    const updateData = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.period !== undefined) updateData.period = data.period;
    if (data.targetAmount !== undefined) updateData.target_amount = data.targetAmount;
    if (data.dueDate !== undefined) updateData.due_date = data.dueDate;
    if (data.note !== undefined) updateData.note = data.note;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.isLocked !== undefined) updateData.is_locked = data.isLocked ? 1 : 0;

    const updated = await GoalModel.update(id, userId, updateData);
    return this._formatGoal(updated);
  }

  async deleteGoal(id, userId) {
    return GoalModel.delete(id, userId);
  }

  async addDeposit(goalId, userId, data) {
    const goal = await GoalModel.findById(goalId, userId);
    
    if (!goal) {
      throw { code: "NOT_FOUND", message: "Goal not found" };
    }
    
    if (goal.is_locked || goal.status === 'canceled') {
      throw { code: "BUSINESS_RULE", message: "Goal is locked or canceled" };
    }

    // Create deposit
    const deposit = await GoalDepositModel.create(userId, goalId, data);
    
    // Update goal current amount
    const newAmount = goal.current_amount + deposit.amount;
    const isCompleted = newAmount >= goal.target_amount;
    const newStatus = isCompleted ? 'completed' : goal.status;

    const updatedGoal = await GoalModel.update(goalId, userId, {
      current_amount: newAmount,
      status: newStatus
    });

    return {
      goal: this._formatGoal(updatedGoal),
      deposit: {
        id: deposit.id,
        amount: deposit.amount,
        source: deposit.source,
        depositedAt: deposit.deposited_at
      }
    };
  }

  _formatGoal(g) {
    if (!g) return null;
    const isCompleted = g.current_amount >= g.target_amount || g.status === 'completed';
    const progress = g.target_amount > 0 ? (g.current_amount / g.target_amount) : 0;

    return {
        id: g.id,
        title: g.title,
        period: g.period,
        targetAmount: g.target_amount,
        currentAmount: g.current_amount,
        dueDate: g.due_date,
        note: g.note,
        status: isCompleted && g.status !== 'completed' ? 'completed' : g.status,
        isLocked: g.is_locked === 1,
        progress: Math.min(progress, 1.0),
        isCompleted
    };
  }
}

module.exports = new GoalService();

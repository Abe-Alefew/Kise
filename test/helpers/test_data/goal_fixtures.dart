import 'package:kise/features/goals/domain/goal_entity.dart';

GoalEntity makeGoal({
  String id = 'goal-fixture-001',
  String title = 'Emergency Fund',
  String period = 'monthly',
  String dueDate = '2025-12-31',
  String dueDateDisplay = 'Due Wed Dec 31 2025',
  double currentAmount = 300.0,
  double targetAmount = 1000.0,
  double? progress,
  bool isCompleted = false,
  bool isLocked = false,
  String status = 'active',
  String? note,
  bool isDirty = false,
}) {
  final p = progress ?? ((targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0);
  return GoalEntity(
    id: id,
    title: title,
    period: period,
    dueDate: dueDate,
    dueDateDisplay: dueDateDisplay,
    currentAmount: currentAmount,
    targetAmount: targetAmount,
    progress: p,
    isCompleted: isCompleted,
    isLocked: isLocked,
    status: status,
    note: note,
    isDirty: isDirty,
  );
}

final activeGoal = makeGoal(
  id: 'goal-active',
  title: 'Laptop Fund',
  currentAmount: 400,
  targetAmount: 1000,
  status: 'active',
);

final completedGoal = makeGoal(
  id: 'goal-completed',
  title: 'Trip to Awash',
  currentAmount: 2000,
  targetAmount: 2000,
  isCompleted: true,
  status: 'completed',
);

final lockedGoal = makeGoal(
  id: 'goal-locked',
  title: 'Investment fund',
  currentAmount: 500,
  targetAmount: 5000,
  isLocked: true,
  status: 'active',
);

final canceledGoal = makeGoal(
  id: 'goal-canceled',
  title: 'Old goal',
  currentAmount: 0,
  targetAmount: 500,
  status: 'canceled',
);
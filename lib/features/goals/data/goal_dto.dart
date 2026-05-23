import 'package:kise/features/goals/domain/goal_entity.dart';
import 'package:kise/features/goals/domain/goal_inputs.dart';

class GoalDto {
  final String id;
  final String title;
  final String period;
  final String dueDate;
  final String dueDateDisplay;
  final double currentAmount;
  final double targetAmount;
  final double progress;
  final bool isCompleted;
  final bool isLocked;
  final String status;
  final String? note;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  const GoalDto({
    required this.id,
    required this.title,
    required this.period,
    required this.dueDate,
    required this.dueDateDisplay,
    required this.currentAmount,
    required this.targetAmount,
    required this.progress,
    required this.isCompleted,
    required this.isLocked,
    required this.status,
    this.note,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  static double computeProgress(double current, double target) {
    if (target <= 0) {
      return 0;
    }
    return (current / target).clamp(0.0, 1.0);
  }

  static List<GoalDto> listFromEnvelope(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(GoalDto.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(GoalDto.fromJson)
            .toList();
      }
    }

    return const [];
  }

  factory GoalDto.fromJson(Map<String, dynamic> json) {
    final current = _asDouble(json['currentAmount']);
    final target = _asDouble(json['targetAmount']);

    return GoalDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      period: GoalDateParser.normalizePeriod(json['period']?.toString() ?? 'monthly'),
      dueDate: json['dueDate']?.toString() ?? '',
      dueDateDisplay: json['dueDateDisplay']?.toString() ?? '',
      currentAmount: current,
      targetAmount: target,
      progress: json['progress'] != null
          ? _asDouble(json['progress'])
          : computeProgress(current, target),
      isCompleted: json['isCompleted'] == true,
      isLocked: json['isLocked'] == true,
      status: json['status']?.toString() ?? 'active',
      note: json['note']?.toString(),
      completedAt: json['completedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  factory GoalDto.fromCacheRow(Map<String, dynamic> row) {
    return GoalDto(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      period: row['period']?.toString() ?? 'monthly',
      dueDate: row['due_date']?.toString() ?? '',
      dueDateDisplay: row['due_date_display']?.toString() ?? '',
      currentAmount: _asDouble(row['current_amount']),
      targetAmount: _asDouble(row['target_amount']),
      progress: _asDouble(row['progress']),
      isCompleted: (row['is_completed'] as int? ?? 0) == 1,
      isLocked: (row['is_locked'] as int? ?? 0) == 1,
      status: row['status']?.toString() ?? 'active',
      note: row['note']?.toString(),
      completedAt: row['completed_at']?.toString(),
      createdAt: row['created_at']?.toString(),
      updatedAt: row['updated_at']?.toString(),
    );
  }

  factory GoalDto.fromCreateInput({
    required String id,
    required CreateGoalInput input,
    required DateTime createdAt,
  }) {
    final parsedDue =
        DateTime.tryParse('${input.dueDate}T00:00:00.000Z') ?? createdAt;
    final display = GoalDateParser.formatDueDateDisplay(parsedDue.toLocal());
    final progress = computeProgress(input.currentAmount, input.targetAmount);
    final completed =
        input.currentAmount >= input.targetAmount || progress >= 1.0;

    return GoalDto(
      id: id,
      title: input.title.trim(),
      period: GoalDateParser.normalizePeriod(input.period),
      dueDate: input.dueDate,
      dueDateDisplay: display,
      currentAmount: input.currentAmount,
      targetAmount: input.targetAmount,
      progress: progress,
      isCompleted: completed,
      isLocked: input.isLocked,
      status: completed ? 'completed' : 'active',
      note: input.note,
      createdAt: createdAt.toUtc().toIso8601String(),
      updatedAt: createdAt.toUtc().toIso8601String(),
    );
  }

  GoalDto applyUpdate(UpdateGoalInput input, {required DateTime updatedAt}) {
    final nextTarget = input.targetAmount ?? targetAmount;
    final nextCurrent = currentAmount;
    final nextProgress = computeProgress(nextCurrent, nextTarget);

    var nextDueDate = dueDate;
    var nextDisplay = dueDateDisplay;

    if (input.dueDate != null) {
      nextDueDate = input.dueDate!;
      final parsed =
          DateTime.tryParse('${input.dueDate}T00:00:00.000Z') ?? updatedAt;
      nextDisplay = GoalDateParser.formatDueDateDisplay(parsed.toLocal());
    }

    final nextStatus = input.status ??
        (nextCurrent >= nextTarget ? 'completed' : status);
    final nextCompleted =
        input.status == 'completed' || nextCurrent >= nextTarget;

    return GoalDto(
      id: id,
      title: input.title ?? title,
      period: input.period != null
          ? GoalDateParser.normalizePeriod(input.period!)
          : period,
      dueDate: nextDueDate,
      dueDateDisplay: nextDisplay,
      currentAmount: nextCurrent,
      targetAmount: nextTarget,
      progress: nextProgress,
      isCompleted: nextCompleted,
      isLocked: input.isLocked ?? isLocked,
      status: nextStatus,
      note: input.note ?? note,
      completedAt: nextCompleted ? (completedAt ?? updatedAt.toIso8601String()) : completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc().toIso8601String(),
    );
  }

  GoalDto applyDeposit({
    required double amount,
    required DateTime updatedAt,
  }) {
    final nextCurrent = currentAmount + amount;
    final nextProgress = computeProgress(nextCurrent, targetAmount);
    final nextCompleted = nextCurrent >= targetAmount;

    return GoalDto(
      id: id,
      title: title,
      period: period,
      dueDate: dueDate,
      dueDateDisplay: dueDateDisplay,
      currentAmount: nextCurrent,
      targetAmount: targetAmount,
      progress: nextProgress,
      isCompleted: nextCompleted,
      isLocked: isLocked,
      status: nextCompleted ? 'completed' : status,
      note: note,
      completedAt: nextCompleted ? updatedAt.toUtc().toIso8601String() : completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt.toUtc().toIso8601String(),
    );
  }

  GoalEntity toEntity({bool isDirty = false, String? syncError}) {
    return GoalEntity(
      id: id,
      title: title,
      period: period,
      dueDate: dueDate,
      dueDateDisplay: dueDateDisplay,
      currentAmount: currentAmount,
      targetAmount: targetAmount,
      progress: progress,
      isCompleted: isCompleted,
      isLocked: isLocked,
      status: status,
      note: note,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDirty: isDirty,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toCacheRow({
    required String userId,
    required DateTime syncedAt,
    required bool isDirty,
    bool isDeleted = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'period': period,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'due_date': dueDate,
      'due_date_display': dueDateDisplay,
      'note': note,
      'status': status,
      'is_locked': isLocked ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'progress': progress,
      'completed_at': completedAt,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': updatedAt ?? now,
      'synced_at': syncedAt.toUtc().toIso8601String(),
      'created_at': createdAt ?? now,
      'updated_at': updatedAt ?? now,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class GoalDepositDto {
  final String id;
  final String goalId;
  final double amount;
  final String source;
  final String? accountId;
  final String depositedAt;
  final String? createdAt;

  const GoalDepositDto({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.source,
    this.accountId,
    required this.depositedAt,
    this.createdAt,
  });

  factory GoalDepositDto.fromJson(Map<String, dynamic> json) {
    return GoalDepositDto(
      id: json['id']?.toString() ?? '',
      goalId: json['goalId']?.toString() ?? '',
      amount: GoalDto._asDouble(json['amount']),
      source: json['source']?.toString() ?? '',
      accountId: json['accountId']?.toString(),
      depositedAt: json['depositedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  factory GoalDepositDto.fromCacheRow(Map<String, dynamic> row) {
    return GoalDepositDto(
      id: row['id']?.toString() ?? '',
      goalId: row['goal_id']?.toString() ?? '',
      amount: GoalDto._asDouble(row['amount']),
      source: row['source']?.toString() ?? '',
      accountId: row['account_id']?.toString(),
      depositedAt: row['deposited_at']?.toString() ?? '',
      createdAt: row['created_at']?.toString(),
    );
  }

  factory GoalDepositDto.fromLocalLog({
    required String id,
    required String goalId,
    required LogDepositInput input,
    required DateTime createdAt,
  }) {
    return GoalDepositDto(
      id: id,
      goalId: goalId,
      amount: input.amount,
      source: input.source,
      accountId: input.accountId,
      depositedAt: input.depositedAt ?? createdAt.toUtc().toIso8601String(),
      createdAt: createdAt.toUtc().toIso8601String(),
    );
  }

  GoalDepositEntity toEntity({bool isDirty = false, String? syncError}) {
    return GoalDepositEntity(
      id: id,
      goalId: goalId,
      amount: amount,
      source: source,
      accountId: accountId,
      depositedAt: depositedAt,
      createdAt: createdAt,
      isDirty: isDirty,
      syncError: syncError,
    );
  }

  Map<String, dynamic> toCacheRow({
    required String userId,
    required DateTime syncedAt,
    required bool isDirty,
    bool isDeleted = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();

    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'source': source,
      'account_id': accountId,
      'deposited_at': depositedAt,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': createdAt,
      'synced_at': syncedAt.toUtc().toIso8601String(),
      'created_at': createdAt ?? now,
    };
  }
}
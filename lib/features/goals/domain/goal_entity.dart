import 'package:flutter/foundation.dart';

@immutable
class GoalEntity {
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
  final bool isDirty;
  final String? syncError;

  const GoalEntity({
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
    this.isDirty = false,
    this.syncError,
  });

  /// Drop-in for legacy `Goal.dueDate` display text on cards.
  String get dueDateLabel => dueDateDisplay;

  /// Drop-in for legacy `Goal.period` pill/card labels.
  String get periodLabel {
    if (period.isEmpty) {
      return period;
    }
    if (period == 'one-time') {
      return 'One-time';
    }
    return '${period[0].toUpperCase()}${period.substring(1)}';
  }

  double get progressPercentage => progress.clamp(0.0, 1.0);

  factory GoalEntity.fromJson(Map<String, dynamic> json) {
    final current = _readDouble(json['currentAmount']);
    final target = _readDouble(json['targetAmount']);
    final progressValue = json['progress'] != null
        ? _readDouble(json['progress'])
        : _computeProgress(current, target);

    return GoalEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      period: _normalizePeriod(json['period']?.toString() ?? 'monthly'),
      dueDate: json['dueDate']?.toString() ?? '',
      dueDateDisplay: json['dueDateDisplay']?.toString() ?? '',
      currentAmount: current,
      targetAmount: target,
      progress: progressValue,
      isCompleted: json['isCompleted'] == true,
      isLocked: json['isLocked'] == true,
      status: json['status']?.toString() ?? 'active',
      note: json['note']?.toString(),
      completedAt: json['completedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isDirty: json['isDirty'] == true,
      syncError: json['syncError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'period': period,
      'dueDate': dueDate,
      'dueDateDisplay': dueDateDisplay,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'progress': progress,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
      'status': status,
      if (note != null) 'note': note,
      if (completedAt != null) 'completedAt': completedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'isDirty': isDirty,
      if (syncError != null) 'syncError': syncError,
    };
  }

  GoalEntity copyWith({
    String? id,
    String? title,
    String? period,
    String? dueDate,
    String? dueDateDisplay,
    double? currentAmount,
    double? targetAmount,
    double? progress,
    bool? isCompleted,
    bool? isLocked,
    String? status,
    String? note,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
    bool? isDirty,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      period: period ?? this.period,
      dueDate: dueDate ?? this.dueDate,
      dueDateDisplay: dueDateDisplay ?? this.dueDateDisplay,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      status: status ?? this.status,
      note: note ?? this.note,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty: isDirty ?? this.isDirty,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _computeProgress(double current, double target) {
    if (target <= 0) {
      return 0;
    }
    return (current / target).clamp(0.0, 1.0);
  }

  static String _normalizePeriod(String period) {
    return period.trim().toLowerCase();
  }
}

@immutable
class GoalDepositEntity {
  final String id;
  final String goalId;
  final double amount;
  final String source;
  final String? accountId;
  final String depositedAt;
  final String? createdAt;
  final bool isDirty;
  final String? syncError;

  const GoalDepositEntity({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.source,
    this.accountId,
    required this.depositedAt,
    this.createdAt,
    this.isDirty = false,
    this.syncError,
  });

  factory GoalDepositEntity.fromJson(Map<String, dynamic> json) {
    return GoalDepositEntity(
      id: json['id']?.toString() ?? '',
      goalId: json['goalId']?.toString() ?? '',
      amount: GoalEntity._readDouble(json['amount']),
      source: json['source']?.toString() ?? '',
      accountId: json['accountId']?.toString(),
      depositedAt: json['depositedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      isDirty: json['isDirty'] == true,
      syncError: json['syncError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'source': source,
      if (accountId != null) 'accountId': accountId,
      'depositedAt': depositedAt,
      if (createdAt != null) 'createdAt': createdAt,
      'isDirty': isDirty,
      if (syncError != null) 'syncError': syncError,
    };
  }

  GoalDepositEntity copyWith({
    String? id,
    String? goalId,
    double? amount,
    String? source,
    String? accountId,
    String? depositedAt,
    String? createdAt,
    bool? isDirty,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return GoalDepositEntity(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      accountId: accountId ?? this.accountId,
      depositedAt: depositedAt ?? this.depositedAt,
      createdAt: createdAt ?? this.createdAt,
      isDirty: isDirty ?? this.isDirty,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }
}
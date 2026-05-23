class GoalDateParser {
  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String toIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatDueDateDisplay(DateTime date) {
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return 'Due $weekday $month ${date.day} ${date.year}';
  }

  static DateTime? parseDueDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      return DateTime.tryParse('${trimmed}T00:00:00.000Z')?.toLocal();
    }

    final withoutPrefix =
        trimmed.startsWith('Due ') ? trimmed.substring(4).trim() : trimmed;

    final parts = withoutPrefix.split(RegExp(r'\s+'));
    if (parts.length < 4) {
      return null;
    }

    final monthIndex = months.indexOf(parts[1]);
    final day = int.tryParse(parts[2]);
    final year = int.tryParse(parts[3]);

    if (monthIndex < 0 || day == null || year == null) {
      return null;
    }

    return DateTime(year, monthIndex + 1, day);
  }

  static String normalizePeriod(String period) {
    final normalized = period.trim().toLowerCase();
    switch (normalized) {
      case 'daily':
      case 'weekly':
      case 'monthly':
      case 'yearly':
      case 'one-time':
        return normalized;
      case 'one time':
        return 'one-time';
      default:
        return normalized.isEmpty ? 'monthly' : normalized;
    }
  }
}

class CreateGoalInput {
  final String title;
  final String period;
  final double targetAmount;
  final double currentAmount;
  final String dueDate;
  final String? note;
  final bool isLocked;

  const CreateGoalInput({
    required this.title,
    required this.period,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.dueDate,
    this.note,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'period': GoalDateParser.normalizePeriod(period),
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'dueDate': dueDate,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (isLocked) 'isLocked': true,
    };
  }
}

class LogDepositInput {
  final double amount;
  final String source;
  final String? accountId;
  final String? depositedAt;

  const LogDepositInput({
    required this.amount,
    required this.source,
    this.accountId,
    this.depositedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'source': source,
      if (accountId != null && accountId!.isNotEmpty) 'accountId': accountId,
      if (depositedAt != null && depositedAt!.isNotEmpty) 'depositedAt': depositedAt,
    };
  }
}

class UpdateGoalInput {
  final String? title;
  final String? period;
  final double? targetAmount;
  final String? dueDate;
  final String? status;
  final bool? isLocked;
  final String? note;

  const UpdateGoalInput({
    this.title,
    this.period,
    this.targetAmount,
    this.dueDate,
    this.status,
    this.isLocked,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (period != null) 'period': GoalDateParser.normalizePeriod(period!),
      if (targetAmount != null) 'targetAmount': targetAmount,
      if (dueDate != null) 'dueDate': dueDate,
      if (status != null) 'status': status,
      if (isLocked != null) 'isLocked': isLocked,
      if (note != null) 'note': note,
    };
  }

  bool get isEmpty =>
      title == null &&
      period == null &&
      targetAmount == null &&
      dueDate == null &&
      status == null &&
      isLocked == null &&
      note == null;
}
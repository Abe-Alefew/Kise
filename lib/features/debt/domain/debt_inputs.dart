import 'package:kise/features/debt/domain/debt_entity.dart';

class DebtDateParser {
  static String toIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? parseIsoDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse('${trimmed}T00:00:00.000Z')?.toLocal() ??
        DateTime.tryParse(trimmed)?.toLocal();
  }
}

class CreateDebtInput {
  final String personName;
  final DebtType type;
  final double totalAmount;
  final String debtDate;
  final String? notes;

  const CreateDebtInput({
    required this.personName,
    required this.type,
    required this.totalAmount,
    required this.debtDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'personName': personName.trim(),
      'type': type == DebtType.lent ? 'lent' : 'borrowed',
      'totalAmount': totalAmount,
      'debtDate': debtDate,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}

class RecordPaymentInput {
  final double amount;
  final String paymentDate;
  final String? notes;

  const RecordPaymentInput({
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentDate': paymentDate,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}

class UpdateDebtInput {
  final String? personName;
  final DebtType? type;
  final double? totalAmount;
  final String? debtDate;
  final String? notes;

  const UpdateDebtInput({
    this.personName,
    this.type,
    this.totalAmount,
    this.debtDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (personName != null) 'personName': personName!.trim(),
      if (type != null) 'type': type == DebtType.lent ? 'lent' : 'borrowed',
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (debtDate != null) 'debtDate': debtDate,
      if (notes != null) 'notes': notes,
    };
  }

  bool get isEmpty =>
      personName == null &&
      type == null &&
      totalAmount == null &&
      debtDate == null &&
      notes == null;
}
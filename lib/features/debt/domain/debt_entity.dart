import 'package:flutter/foundation.dart';

enum DebtStatus { pending, partial, settled }

enum DebtType { lent, borrowed }

@immutable
class PaymentRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });
}

@immutable
class DebtEntity {
  final String id;
  final String personName;
  final DebtType type;
  final double totalAmount;
  final double paidAmount;
  final DateTime date;
  final List<PaymentRecord> payments;

  const DebtEntity({
    required this.id,
    required this.personName,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.date,
    this.payments = const [],
  });

  double get remaining => totalAmount - paidAmount;

  String get personInitial =>
      personName.isNotEmpty ? personName[0].toUpperCase() : '?';

  DebtStatus get status {
    if (paidAmount >= totalAmount) return DebtStatus.settled;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.pending;
  }

  DebtEntity copyWith({
    double? paidAmount,
    List<PaymentRecord>? payments,
  }) {
    return DebtEntity(
      id: id,
      personName: personName,
      type: type,
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      date: date,
      payments: payments ?? this.payments,
    );
  }
}

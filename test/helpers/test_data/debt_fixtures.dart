import 'package:kise/features/debt/domain/debt_entity.dart';

DebtEntity makeDebt({
  String id = 'debt-fixture-001',
  String personName = 'Alice',
  DebtType type = DebtType.lent,
  double totalAmount = 1000.0,
  double paidAmount = 0.0,
  DebtStatus? status,
  List<PaymentRecord> payments = const [],
  String? notes,
  bool isDirty = false,
}) {
  return DebtEntity(
    id: id,
    personName: personName,
    type: type,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    date: DateTime(2025, 6, 1),
    payments: payments,
    status: status,
    notes: notes,
    isDirty: isDirty,
  );
}

PaymentRecord makePayment({
  String id = 'pay-001',
  double amount = 200.0,
  DateTime? date,
  String? notes,
}) {
  return PaymentRecord(
    id: id,
    amount: amount,
    date: date ?? DateTime(2025, 7, 1),
    notes: notes,
  );
}

final pendingLentDebt = makeDebt(
  id: 'debt-pending-lent',
  personName: 'Bob',
  type: DebtType.lent,
  totalAmount: 500,
  paidAmount: 0,
);

final partialBorrowedDebt = makeDebt(
  id: 'debt-partial-borrowed',
  personName: 'Carol',
  type: DebtType.borrowed,
  totalAmount: 1000,
  paidAmount: 400,
);

final settledLentDebt = makeDebt(
  id: 'debt-settled-lent',
  personName: 'Dave',
  type: DebtType.lent,
  totalAmount: 300,
  paidAmount: 300,
  status: DebtStatus.settled,
);

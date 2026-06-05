import 'package:kise/features/transactions/domain/transaction_entity.dart';

TransactionEntity makeTransaction({
  String id = 'tx-fixture-001',
  String title = 'Coffee',
  String category = 'Food',
  double amount = 50.0,
  String type = 'expense',
  String transactionDate = '2025-06-01',
  String displayDate = 'Jun 1',
  String month = 'Jun',
  String iconKey = 'shoppingCart',
  bool isDirty = false,
  String? note,
}) {
  return TransactionEntity(
    id: id,
    title: title,
    category: category,
    amount: amount,
    type: type,
    transactionDate: transactionDate,
    displayDate: displayDate,
    month: month,
    iconKey: iconKey,
    isDirty: isDirty,
    note: note,
  );
}

final incomeTransaction = makeTransaction(
  id: 'tx-income',
  title: 'Salary',
  category: 'Salary',
  amount: 5000,
  type: 'income',
  iconKey: 'briefcase',
);

final expenseTransaction = makeTransaction(
  id: 'tx-expense',
  title: 'Grocery',
  category: 'Food',
  amount: 200,
  type: 'expense',
  iconKey: 'shoppingCart',
);

final dirtyTransaction = makeTransaction(
  id: 'tx-dirty',
  title: 'Pending sync',
  category: 'Transport',
  amount: 30,
  type: 'expense',
  isDirty: true,
);

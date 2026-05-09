import '../data/transaction_repository.dart';
import 'transaction_entity.dart';

class TransactionUseCases {

  final TransactionRepository repository;

  TransactionUseCases(this.repository);

  /// GET ALL TRANSACTIONS
  List<TransactionEntity> getAllTransactions() {

    return repository.getTransactions();
  }

  /// GET INCOME TRANSACTIONS
  List<TransactionEntity> getIncomeTransactions() {

    return repository
        .getTransactions()
        .where((transaction) =>
            transaction.type == "Income")
        .toList();
  }

  /// GET EXPENSE TRANSACTIONS
  List<TransactionEntity> getExpenseTransactions() {

    return repository
        .getTransactions()
        .where((transaction) =>
            transaction.type == "Expense")
        .toList();
  }

  /// TOTAL INCOME
  double calculateTotalIncome() {

    return getIncomeTransactions()
        .fold(0, (sum, item) => sum + item.amount);
  }

  /// TOTAL EXPENSE
  double calculateTotalExpense() {

    return getExpenseTransactions()
        .fold(0, (sum, item) => sum + item.amount);
  }

  /// TOTAL BALANCE
  double calculateBalance() {

    return calculateTotalIncome()
        - calculateTotalExpense();
  }
}
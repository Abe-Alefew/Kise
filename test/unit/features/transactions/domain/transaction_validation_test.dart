import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/domain/transaction_entity.dart';

/// Helper class to validate transaction rules
class TransactionValidator {
  /// Check if an expense transaction would result in negative balance
  /// Returns true if the transaction is VALID (allowed)
  /// Returns false if the transaction would create negative balance (not allowed)
  static bool canPerformExpense({
    required double totalIncome,
    required double totalExpenses,
    required double expenseAmount,
  }) {
    final projectedBalance = totalIncome - (totalExpenses + expenseAmount);
    return projectedBalance >= 0;
  }

  /// Check if an expense can be made from a specific account
  /// Returns true if the transaction is VALID (allowed)
  /// Returns false if account doesn't have enough funds
  static bool canExpenseFromAccount({
    required double accountBalance,
    required double expenseAmount,
  }) {
    return accountBalance >= expenseAmount;
  }

  /// Calculate account balance from transactions
  static double calculateAccountBalance(
    List<TransactionEntity> transactions, {
    required String accountId,
  }) {
    double balance = 0;
    for (final tx in transactions) {
      if (tx.accountId == accountId) {
        if (tx.type.toLowerCase() == 'income') {
          balance += tx.amount;
        } else if (tx.type.toLowerCase() == 'expense') {
          balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  /// Calculate dashboard balance from all transactions
  static double calculateDashboardBalance(
    List<TransactionEntity> transactions,
  ) {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in transactions) {
      if (tx.type.toLowerCase() == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type.toLowerCase() == 'expense') {
        totalExpenses += tx.amount;
      }
    }

    return totalIncome - totalExpenses;
  }
}

void main() {
  group('TransactionValidator - Dashboard Balance (No Negative Balance)', () {
    test(
      'should allow expense when total income equals total expenses after expense',
      () {
        // Arrange
        const totalIncome = 5000.0;
        const currentExpenses = 2000.0;
        const newExpenseAmount = 3000.0;

        // Act & Assert
        final result = TransactionValidator.canPerformExpense(
          totalIncome: totalIncome,
          totalExpenses: currentExpenses,
          expenseAmount: newExpenseAmount,
        );

        expect(
          result,
          isTrue,
          reason: 'Should allow expense when balance remains at 0',
        );
      },
    );

    test('should allow expense when balance remains positive', () {
      // Arrange
      const totalIncome = 10000.0;
      const currentExpenses = 4000.0;
      const newExpenseAmount = 3000.0;

      // Act & Assert
      final result = TransactionValidator.canPerformExpense(
        totalIncome: totalIncome,
        totalExpenses: currentExpenses,
        expenseAmount: newExpenseAmount,
      );

      expect(
        result,
        isTrue,
        reason: 'Should allow expense when balance remains positive',
      );
    });

    test('should NOT allow expense if it would create negative balance', () {
      // Arrange: Total income 5000, current expenses 2000, trying to spend 4000
      // Result would be: 5000 - (2000 + 4000) = -1000 (NEGATIVE)
      const totalIncome = 5000.0;
      const currentExpenses = 2000.0;
      const newExpenseAmount = 4000.0;

      // Act & Assert
      final result = TransactionValidator.canPerformExpense(
        totalIncome: totalIncome,
        totalExpenses: currentExpenses,
        expenseAmount: newExpenseAmount,
      );

      expect(
        result,
        isFalse,
        reason: 'Should NOT allow expense that would create negative balance',
      );
    });

    test(
      'should NOT allow expense when balance is already 0 and trying to add expense',
      () {
        // Arrange: Total income 5000, expenses 5000 (balance = 0), trying to spend 1000
        const totalIncome = 5000.0;
        const currentExpenses = 5000.0;
        const newExpenseAmount = 1000.0;

        // Act & Assert
        final result = TransactionValidator.canPerformExpense(
          totalIncome: totalIncome,
          totalExpenses: currentExpenses,
          expenseAmount: newExpenseAmount,
        );

        expect(
          result,
          isFalse,
          reason: 'Should NOT allow expense when balance is already 0',
        );
      },
    );

    test('should handle zero amount expenses', () {
      // Arrange
      const totalIncome = 1000.0;
      const currentExpenses = 500.0;
      const newExpenseAmount = 0.0;

      // Act & Assert
      final result = TransactionValidator.canPerformExpense(
        totalIncome: totalIncome,
        totalExpenses: currentExpenses,
        expenseAmount: newExpenseAmount,
      );

      expect(result, isTrue, reason: 'Zero expense should always be allowed');
    });

    test(
      'should calculate correct dashboard balance from transaction list',
      () {
        // Arrange
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'Salary',
            category: 'Salary',
            amount: 5000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
          ),
          const TransactionEntity(
            id: 'tx2',
            title: 'Food',
            category: 'Food',
            amount: 500,
            type: 'Expense',
            transactionDate: '2025-01-02',
            displayDate: 'Jan 2',
            month: 'Jan',
          ),
          const TransactionEntity(
            id: 'tx3',
            title: 'Transport',
            category: 'Transport',
            amount: 300,
            type: 'Expense',
            transactionDate: '2025-01-03',
            displayDate: 'Jan 3',
            month: 'Jan',
          ),
        ];

        // Act
        final balance = TransactionValidator.calculateDashboardBalance(
          transactions,
        );

        // Assert
        expect(
          balance,
          4200,
          reason: 'Balance should be 5000 - 500 - 300 = 4200',
        );
      },
    );

    test(
      'should prevent transaction if new expense would make dashboard negative',
      () {
        // Arrange
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'Salary',
            category: 'Salary',
            amount: 3000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
          ),
          const TransactionEntity(
            id: 'tx2',
            title: 'Rent',
            category: 'Housing',
            amount: 2000,
            type: 'Expense',
            transactionDate: '2025-01-02',
            displayDate: 'Jan 2',
            month: 'Jan',
          ),
        ];

        // Current balance: 3000 - 2000 = 1000
        final currentBalance = TransactionValidator.calculateDashboardBalance(
          transactions,
        );
        expect(currentBalance, 1000);

        // Try to spend 2000 (more than available)
        const newExpense = 2000.0;
        final canSpend = TransactionValidator.canPerformExpense(
          totalIncome: 3000,
          totalExpenses: 2000,
          expenseAmount: newExpense,
        );

        // Assert
        expect(
          canSpend,
          isFalse,
          reason: 'Cannot spend 2000 when only 1000 is available',
        );
      },
    );
  });

  group('TransactionValidator - Account Balance (No Over-spending from Account)', () {
    test('should allow expense when account has exact amount', () {
      // Arrange: Account has 2000, expense is 2000
      const accountBalance = 2000.0;
      const expenseAmount = 2000.0;

      // Act & Assert
      final result = TransactionValidator.canExpenseFromAccount(
        accountBalance: accountBalance,
        expenseAmount: expenseAmount,
      );

      expect(
        result,
        isTrue,
        reason: 'Should allow expense when account has exact amount',
      );
    });

    test('should allow expense when account has more than required', () {
      // Arrange: Account (CBE) has 5000, expense is 2000
      const accountBalance = 5000.0;
      const expenseAmount = 2000.0;

      // Act & Assert
      final result = TransactionValidator.canExpenseFromAccount(
        accountBalance: accountBalance,
        expenseAmount: expenseAmount,
      );

      expect(
        result,
        isTrue,
        reason: 'Should allow expense when account balance is sufficient',
      );
    });

    test(
      'should NOT allow expense when account has less than required (CBE example)',
      () {
        // Arrange: Account (CBE) has 2000, trying to expense 3000
        const accountBalance = 2000.0;
        const expenseAmount = 3000.0;

        // Act & Assert
        final result = TransactionValidator.canExpenseFromAccount(
          accountBalance: accountBalance,
          expenseAmount: expenseAmount,
        );

        expect(
          result,
          isFalse,
          reason: 'Should NOT allow expense (3000) from account with only 2000',
        );
      },
    );

    test('should NOT allow expense when account balance is 0', () {
      // Arrange: Account has 0, trying to expense 100
      const accountBalance = 0.0;
      const expenseAmount = 100.0;

      // Act & Assert
      final result = TransactionValidator.canExpenseFromAccount(
        accountBalance: accountBalance,
        expenseAmount: expenseAmount,
      );

      expect(
        result,
        isFalse,
        reason: 'Should NOT allow expense from empty account',
      );
    });

    test('should calculate account balance from transactions', () {
      // Arrange: Two deposits (1000 + 500) and one expense (300) from "CBE" account
      final transactions = [
        const TransactionEntity(
          id: 'tx1',
          title: 'Deposit CBE',
          category: 'Salary',
          amount: 1000,
          type: 'Income',
          transactionDate: '2025-01-01',
          displayDate: 'Jan 1',
          month: 'Jan',
          accountId: 'cbe-account-123',
        ),
        const TransactionEntity(
          id: 'tx2',
          title: 'Deposit CBE',
          category: 'Freelance',
          amount: 500,
          type: 'Income',
          transactionDate: '2025-01-02',
          displayDate: 'Jan 2',
          month: 'Jan',
          accountId: 'cbe-account-123',
        ),
        const TransactionEntity(
          id: 'tx3',
          title: 'Food expense',
          category: 'Food',
          amount: 300,
          type: 'Expense',
          transactionDate: '2025-01-03',
          displayDate: 'Jan 3',
          month: 'Jan',
          accountId: 'cbe-account-123',
        ),
      ];

      // Act
      final cbeBalance = TransactionValidator.calculateAccountBalance(
        transactions,
        accountId: 'cbe-account-123',
      );

      // Assert
      expect(
        cbeBalance,
        1200,
        reason: 'CBE balance should be 1000 + 500 - 300 = 1200',
      );
    });

    test('should calculate separate balances for different accounts', () {
      // Arrange: Two accounts with different transactions
      final transactions = [
        const TransactionEntity(
          id: 'tx1',
          title: 'Deposit CBE',
          category: 'Salary',
          amount: 2000,
          type: 'Income',
          transactionDate: '2025-01-01',
          displayDate: 'Jan 1',
          month: 'Jan',
          accountId: 'cbe-account-123',
        ),
        const TransactionEntity(
          id: 'tx2',
          title: 'Deposit Telebirr',
          category: 'Salary',
          amount: 1000,
          type: 'Income',
          transactionDate: '2025-01-01',
          displayDate: 'Jan 1',
          month: 'Jan',
          accountId: 'telebirr-account-456',
        ),
        const TransactionEntity(
          id: 'tx3',
          title: 'Expense from CBE',
          category: 'Food',
          amount: 300,
          type: 'Expense',
          transactionDate: '2025-01-02',
          displayDate: 'Jan 2',
          month: 'Jan',
          accountId: 'cbe-account-123',
        ),
      ];

      // Act
      final cbeBalance = TransactionValidator.calculateAccountBalance(
        transactions,
        accountId: 'cbe-account-123',
      );
      final telebirrBalance = TransactionValidator.calculateAccountBalance(
        transactions,
        accountId: 'telebirr-account-456',
      );

      // Assert
      expect(
        cbeBalance,
        1700,
        reason: 'CBE balance should be 2000 - 300 = 1700',
      );
      expect(
        telebirrBalance,
        1000,
        reason: 'Telebirr balance should be 1000 (no expenses)',
      );
    });

    test(
      'should prevent expense from specific account when insufficient funds (CBE example)',
      () {
        // Arrange: CBE account has only 2000, user tries to expense 3000 from CBE
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'Deposit CBE',
            category: 'Salary',
            amount: 2000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
            accountId: 'cbe-account-123',
          ),
        ];

        // Act
        final cbeBalance = TransactionValidator.calculateAccountBalance(
          transactions,
          accountId: 'cbe-account-123',
        );
        final canExpense = TransactionValidator.canExpenseFromAccount(
          accountBalance: cbeBalance,
          expenseAmount: 3000,
        );

        // Assert
        expect(cbeBalance, 2000);
        expect(
          canExpense,
          isFalse,
          reason: 'Cannot expense 3000 from CBE account with only 2000',
        );
      },
    );

    test(
      'should allow multiple expenses from account until balance is depleted',
      () {
        // Arrange
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'Deposit',
            category: 'Salary',
            amount: 5000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
            accountId: 'account-001',
          ),
          const TransactionEntity(
            id: 'tx2',
            title: 'Expense 1',
            category: 'Food',
            amount: 1000,
            type: 'Expense',
            transactionDate: '2025-01-02',
            displayDate: 'Jan 2',
            month: 'Jan',
            accountId: 'account-001',
          ),
          const TransactionEntity(
            id: 'tx3',
            title: 'Expense 2',
            category: 'Transport',
            amount: 2000,
            type: 'Expense',
            transactionDate: '2025-01-03',
            displayDate: 'Jan 3',
            month: 'Jan',
            accountId: 'account-001',
          ),
        ];

        // Act: Calculate remaining balance after previous expenses
        final currentBalance = TransactionValidator.calculateAccountBalance(
          transactions,
          accountId: 'account-001',
        );
        expect(currentBalance, 2000);

        // Try another 1500 expense (should succeed)
        final canExpense1 = TransactionValidator.canExpenseFromAccount(
          accountBalance: currentBalance,
          expenseAmount: 1500,
        );

        // Try 2500 expense (should fail)
        final canExpense2 = TransactionValidator.canExpenseFromAccount(
          accountBalance: currentBalance,
          expenseAmount: 2500,
        );

        // Assert
        expect(
          canExpense1,
          isTrue,
          reason: 'Can expense 1500 when balance is 2000',
        );
        expect(
          canExpense2,
          isFalse,
          reason: 'Cannot expense 2500 when balance is 2000',
        );
      },
    );
  });

  group('TransactionValidator - Combined Scenarios', () {
    test(
      'should prevent expense that violates both dashboard and account balance rules',
      () {
        // Scenario: User has 5000 total income, 4500 expenses (balance 500)
        // CBE account has only 2000 deposit, 1500 already spent (balance 500)
        // User tries to expense 600 from CBE → should fail on both counts

        // Dashboard state
        const dashboardTotalIncome = 5000.0;
        const dashboardCurrentExpenses = 4500.0;

        // Account state
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'CBE Deposit',
            category: 'Salary',
            amount: 2000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
            accountId: 'cbe-account',
          ),
          const TransactionEntity(
            id: 'tx2',
            title: 'CBE Expense',
            category: 'Food',
            amount: 1500,
            type: 'Expense',
            transactionDate: '2025-01-02',
            displayDate: 'Jan 2',
            month: 'Jan',
            accountId: 'cbe-account',
          ),
        ];

        const newExpense = 600.0;

        // Act
        final accountBalance = TransactionValidator.calculateAccountBalance(
          transactions,
          accountId: 'cbe-account',
        );
        final canExpenseFromDashboard = TransactionValidator.canPerformExpense(
          totalIncome: dashboardTotalIncome,
          totalExpenses: dashboardCurrentExpenses,
          expenseAmount: newExpense,
        );
        final canExpenseFromAccount =
            TransactionValidator.canExpenseFromAccount(
              accountBalance: accountBalance,
              expenseAmount: newExpense,
            );

        // Assert
        expect(
          accountBalance,
          500,
          reason: 'Account balance should be 2000 - 1500 = 500',
        );
        expect(
          canExpenseFromDashboard,
          isFalse,
          reason: 'Dashboard would go negative: 500 - 600 = -100',
        );
        expect(
          canExpenseFromAccount,
          isFalse,
          reason: 'Account balance is insufficient: 500 < 600',
        );
      },
    );

    test(
      'should allow expense that satisfies both dashboard and account balance rules',
      () {
        // Scenario: User has 10000 total income, 4000 expenses (balance 6000)
        // CBE account has 5000 deposit, 1000 expenses (balance 4000)
        // User tries to expense 2000 from CBE → should succeed on both counts

        // Dashboard state
        const dashboardTotalIncome = 10000.0;
        const dashboardCurrentExpenses = 4000.0;

        // Account state
        final transactions = [
          const TransactionEntity(
            id: 'tx1',
            title: 'CBE Deposit',
            category: 'Salary',
            amount: 5000,
            type: 'Income',
            transactionDate: '2025-01-01',
            displayDate: 'Jan 1',
            month: 'Jan',
            accountId: 'cbe-account',
          ),
          const TransactionEntity(
            id: 'tx2',
            title: 'CBE Expense',
            category: 'Food',
            amount: 1000,
            type: 'Expense',
            transactionDate: '2025-01-02',
            displayDate: 'Jan 2',
            month: 'Jan',
            accountId: 'cbe-account',
          ),
        ];

        const newExpense = 2000.0;

        // Act
        final accountBalance = TransactionValidator.calculateAccountBalance(
          transactions,
          accountId: 'cbe-account',
        );
        final canExpenseFromDashboard = TransactionValidator.canPerformExpense(
          totalIncome: dashboardTotalIncome,
          totalExpenses: dashboardCurrentExpenses,
          expenseAmount: newExpense,
        );
        final canExpenseFromAccount =
            TransactionValidator.canExpenseFromAccount(
              accountBalance: accountBalance,
              expenseAmount: newExpense,
            );

        // Assert
        expect(
          accountBalance,
          4000,
          reason: 'Account balance should be 5000 - 1000 = 4000',
        );
        expect(
          canExpenseFromDashboard,
          isTrue,
          reason: 'Dashboard stays positive: 6000 - 2000 = 4000',
        );
        expect(
          canExpenseFromAccount,
          isTrue,
          reason: 'Account has sufficient balance: 4000 >= 2000',
        );
      },
    );
  });
}

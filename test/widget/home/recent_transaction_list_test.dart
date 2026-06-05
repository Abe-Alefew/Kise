import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';
import 'package:kise/features/home/presentation/widgets/recent_transaction_list.dart';

import '../../helpers/widget_helper.dart';

const _expenseTx = HomeRecentTransaction(
  id: 'rt-1',
  type: 'expense',
  title: 'Coffee',
  category: 'Food',
  amount: 45.0,
  displayDate: 'Jun 1',
);

const _incomeTx = HomeRecentTransaction(
  id: 'rt-2',
  type: 'income',
  title: 'Salary',
  category: 'Salary',
  amount: 5000.0,
  displayDate: 'Jun 1',
);

void main() {
  group('RecentTransactionsList', () {
    // ── Empty state ────────────────────────────────────────────────
    group('empty state', () {
      testWidgets('shows "No recent transactions" when list is empty',
          (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: []),
        ));
        expect(find.text('No recent transactions'), findsOneWidget);
      });

      testWidgets('shows "Recent transactions" header', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: []),
        ));
        expect(find.text('Recent transactions'), findsOneWidget);
      });

      testWidgets('shows "View all" button', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: []),
        ));
        expect(find.text('View all'), findsOneWidget);
      });
    });

    // ── Non-empty state ────────────────────────────────────────────
    group('with transactions', () {
      testWidgets('renders expense transaction title', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: [_expenseTx]),
        ));
        expect(find.text('Coffee'), findsOneWidget);
      });

      testWidgets('shows "+" prefix for income amount', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: [_incomeTx]),
        ));
        expect(find.textContaining('+'), findsAtLeast(1));
      });

      testWidgets('shows "-" prefix for expense amount', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(transactions: [_expenseTx]),
        ));
        expect(find.textContaining('-'), findsAtLeast(1));
      });

      testWidgets('renders multiple transactions without error', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(
            transactions: [_expenseTx, _incomeTx],
          ),
        ));
        expect(find.byType(ListTile), findsNWidgets(2));
      });

      testWidgets('shows amount with currency', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          const RecentTransactionsList(
            transactions: [_expenseTx],
            currency: 'ETB',
          ),
        ));
        expect(find.textContaining('ETB'), findsAtLeast(1));
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(
        buildWithRouter(
          const RecentTransactionsList(transactions: [_expenseTx]),
        ),
      );
      expect(find.byType(RecentTransactionsList), findsOneWidget);
    });
  });
}

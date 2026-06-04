import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/home/presentation/widgets/balance_card.dart';

import '../helpers/widget_helper.dart';

void main() {
  group('BalanceCard', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('shows "TOTAL BALANCE" label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 4800, income: 5000, expenses: 200),
        ));
        expect(find.text('TOTAL BALANCE'), findsOneWidget);
      });

      testWidgets('displays totalBalance with 2 decimal places', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 4800, income: 5000, expenses: 200),
        ));
        expect(find.textContaining('4800.00'), findsOneWidget);
      });

      testWidgets('displays currency symbol', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(
            totalBalance: 1000,
            income: 2000,
            expenses: 1000,
            currency: 'ETB',
          ),
        ));
        expect(find.textContaining('ETB'), findsWidgets);
      });

      testWidgets('shows "Income" stat label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 5000, expenses: 0),
        ));
        expect(find.text('Income'), findsOneWidget);
      });

      testWidgets('shows "Expenses" stat label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 0, expenses: 1000),
        ));
        expect(find.text('Expenses'), findsOneWidget);
      });

      testWidgets('displays income amount formatted', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 5000, expenses: 0),
        ));
        expect(find.textContaining('5000.00'), findsOneWidget);
      });

      testWidgets('displays expenses amount formatted', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 0, expenses: 200),
        ));
        expect(find.textContaining('200.00'), findsOneWidget);
      });

      testWidgets('shows trending_up icon for income', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 0, expenses: 0),
        ));
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });

      testWidgets('shows trending_down icon for expenses', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BalanceCard(totalBalance: 0, income: 0, expenses: 0),
        ));
        expect(find.byIcon(Icons.trending_down), findsOneWidget);
      });
    });

    // ── Custom currency ────────────────────────────────────────────
    testWidgets('defaults currency to "ETB"', (tester) async {
      await tester.pumpWidget(buildSimple(
        const BalanceCard(totalBalance: 100, income: 200, expenses: 100),
      ));
      final card =
          tester.widget<BalanceCard>(find.byType(BalanceCard));
      expect(card.currency, 'ETB');
    });

    testWidgets('accepts a custom currency symbol', (tester) async {
      await tester.pumpWidget(buildSimple(
        const BalanceCard(
          totalBalance: 100,
          income: 200,
          expenses: 100,
          currency: 'USD',
        ),
      ));
      expect(find.textContaining('USD'), findsWidgets);
    });

    // ── Negative balance ───────────────────────────────────────────
    testWidgets('renders negative balance without error', (tester) async {
      await tester.pumpWidget(buildSimple(
        const BalanceCard(
          totalBalance: -500,
          income: 500,
          expenses: 1000,
        ),
      ));
      expect(find.textContaining('-500.00'), findsOneWidget);
    });

    // ── Zero values ────────────────────────────────────────────────
    testWidgets('renders all zeros without error', (tester) async {
      await tester.pumpWidget(buildSimple(
        const BalanceCard(totalBalance: 0, income: 0, expenses: 0),
      ));
      expect(find.byType(BalanceCard), findsOneWidget);
    });
  });
}

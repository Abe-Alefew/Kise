import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/transactions/presentation/widgets/transaction_tile.dart';

import '../helpers/test_data/transaction_fixtures.dart';
import '../helpers/widget_helper.dart';

void main() {
  group('TransactionTile', () {
    // ── Basic rendering ────────────────────────────────────────────
    group('rendering', () {
      testWidgets('displays transaction title', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: incomeTransaction),
        ));
        expect(find.text('Salary'), findsOneWidget);
      });

      testWidgets('displays category and date separated by "•"', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: incomeTransaction),
        ));
        // "Salary • Jun 1"
        expect(find.textContaining('Salary'), findsWidgets);
        expect(find.textContaining('Jun 1'), findsOneWidget);
      });

      testWidgets('displays amount with currency "ETB"', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: incomeTransaction),
        ));
        expect(find.textContaining('ETB'), findsOneWidget);
      });

      testWidgets('income amount shows "+" prefix', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: incomeTransaction),
        ));
        expect(find.textContaining('+'), findsOneWidget);
      });

      testWidgets('expense amount shows "-" prefix', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: expenseTransaction),
        ));
        expect(find.textContaining('-'), findsOneWidget);
      });

      testWidgets('renders a circular icon container', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: incomeTransaction),
        ));
        // Icon is inside a circle Container
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(Icon), findsOneWidget);
      });
    });

    // ── Edit and Delete buttons ────────────────────────────────────
    group('edit/delete callbacks', () {
      testWidgets('edit button shown when onEdit is provided', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onEdit: () {},
          ),
        ));
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('delete button shown when onDelete is provided',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onDelete: () {},
          ),
        ));
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('no edit icon when onEdit is null', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: expenseTransaction),
        ));
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });

      testWidgets('no delete icon when onDelete is null', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(transaction: expenseTransaction),
        ));
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('tapping edit calls onEdit callback', (tester) async {
        int editCount = 0;
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onEdit: () => editCount++,
          ),
        ));
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pump();
        expect(editCount, 1);
      });

      testWidgets('tapping delete calls onDelete callback', (tester) async {
        int deleteCount = 0;
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onDelete: () => deleteCount++,
          ),
        ));
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();
        expect(deleteCount, 1);
      });
    });

    // ── Loading / deleting state ───────────────────────────────────
    group('isDeleting state', () {
      testWidgets('shows CircularProgressIndicator when isDeleting=true',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onDelete: () {},
            isDeleting: true,
          ),
        ));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Delete icon is replaced by spinner
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('hides edit icon when isDeleting=true', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onEdit: () {},
            onDelete: () {},
            isDeleting: true,
          ),
        ));
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });

      testWidgets('shows icons normally when isDeleting=false', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionTile(
            transaction: expenseTransaction,
            onEdit: () {},
            onDelete: () {},
          ),
        ));
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        TransactionTile(transaction: expenseTransaction),
      ));
      expect(find.byType(TransactionTile), findsOneWidget);
    });
  });
}

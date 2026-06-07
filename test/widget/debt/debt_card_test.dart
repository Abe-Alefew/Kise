import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/widgets/debt_cart.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

import '../../helpers/test_data/debt_fixtures.dart';
import '../../helpers/widget_helper.dart';

void main() {
  group('DebtCard', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('shows person name', (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: pendingLentDebt, onTap: () {}),
        ));
        expect(find.text('Bob'), findsOneWidget);
      });

      testWidgets('contains a StatusBadge', (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: pendingLentDebt, onTap: () {}),
        ));
        expect(find.byType(StatusBadge), findsOneWidget);
      });

      testWidgets('StatusBadge shows "pending" for a pending debt',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: pendingLentDebt, onTap: () {}),
        ));
        expect(find.text('pending'), findsOneWidget);
      });

      testWidgets('StatusBadge shows "partial" for a partial debt',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: partialBorrowedDebt, onTap: () {}),
        ));
        expect(find.text('partial'), findsOneWidget);
      });

      testWidgets('StatusBadge shows "settled" for a settled debt',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: settledLentDebt, onTap: () {}),
        ));
        expect(find.text('settled'), findsOneWidget);
      });

      testWidgets('shows "You lent" label for lent debts', (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: pendingLentDebt, onTap: () {}),
        ));
        expect(
          find.textContaining('You lent'),
          findsOneWidget,
        );
      });

      testWidgets('shows "You borrowed" label for borrowed debts',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: partialBorrowedDebt, onTap: () {}),
        ));
        expect(find.textContaining('You borrowed'), findsOneWidget);
      });

      testWidgets('shows the remaining amount for non-settled debt',
          (tester) async {
        // pendingLentDebt: total=500, paid=0, remaining=500
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: pendingLentDebt, onTap: () {}),
        ));
        // Amount formatted as "#,##0.00" → "500.00 ETB"
        expect(find.textContaining('500.00 ETB'), findsWidgets);
      });

      testWidgets('shows total amount (not remaining) for settled debt',
          (tester) async {
        // settledLentDebt: total=300, paid=300 → mainAmount=totalAmount=300
        await tester.pumpWidget(buildSimple(
          DebtCard(debt: settledLentDebt, onTap: () {}),
        ));
        expect(find.textContaining('300.00 ETB'), findsWidgets);
      });
    });

    // ── Tap interaction ────────────────────────────────────────────
    group('onTap', () {
      testWidgets('fires onTap when the card is tapped', (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(buildSimple(
          DebtCard(
            debt: pendingLentDebt,
            onTap: () => tapCount++,
          ),
        ));
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        expect(tapCount, 1);
      });
    });

    // ── All debt types render ──────────────────────────────────────
    group('all DebtType variants', () {
      testWidgets('lent debt renders without error', (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(
            debt: makeDebt(type: DebtType.lent),
            onTap: () {},
          ),
        ));
        expect(find.byType(DebtCard), findsOneWidget);
      });

      testWidgets('borrowed debt renders without error', (tester) async {
        await tester.pumpWidget(buildSimple(
          DebtCard(
            debt: makeDebt(type: DebtType.borrowed),
            onTap: () {},
          ),
        ));
        expect(find.byType(DebtCard), findsOneWidget);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        DebtCard(debt: pendingLentDebt, onTap: () {}),
      ));
      expect(find.byType(DebtCard), findsOneWidget);
    });
  });
}

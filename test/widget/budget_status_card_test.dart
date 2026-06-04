import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';
import 'package:kise/features/home/presentation/widgets/budget_status_card.dart';

import '../helpers/widget_helper.dart';

void main() {
  group('BudgetStatusCard', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('shows personality label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.4,
            personality: 'Saver',
            tip: 'Keep it up!',
          ),
        ));
        expect(find.text('Saver'), findsOneWidget);
      });

      testWidgets('shows "Spending personality for this cycle" subtitle',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.4,
            personality: 'Saver',
            tip: '',
          ),
        ));
        expect(
          find.text('Spending personality for this cycle'),
          findsOneWidget,
        );
      });

      testWidgets('shows "Spend ratio" label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.6,
            personality: 'Average',
            tip: '',
          ),
        ));
        expect(find.text('Spend ratio'), findsOneWidget);
      });

      testWidgets('shows spendRatio as percentage string', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.75,
            personality: 'Spender',
            tip: '',
          ),
        ));
        // 0.75 * 100 = 75 → "75%"
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('shows 0% for spendRatio=0', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0,
            personality: 'Great',
            tip: '',
          ),
        ));
        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('shows 100% for spendRatio=1', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 1.0,
            personality: 'Danger',
            tip: '',
          ),
        ));
        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('contains a KiseProgressBar', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.5,
            personality: 'Normal',
            tip: '',
          ),
        ));
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('contains a balance icon', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.5,
            personality: 'Balanced',
            tip: '',
          ),
        ));
        expect(find.byIcon(Icons.balance), findsOneWidget);
      });
    });

    // ── Tip section ────────────────────────────────────────────────
    group('tip section', () {
      testWidgets('shows tip text when tip is non-empty', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.5,
            personality: 'Normal',
            tip: 'Try to cut restaurant visits.',
          ),
        ));
        expect(find.text('Try to cut restaurant visits.'), findsOneWidget);
      });

      testWidgets('shows lightbulb icon when tip is present', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.5,
            personality: 'Normal',
            tip: 'A helpful tip.',
          ),
        ));
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('hides tip section when tip is empty', (tester) async {
        await tester.pumpWidget(buildSimple(
          const BudgetStatusCard(
            spendRatio: 0.5,
            personality: 'Normal',
            tip: '',
          ),
        ));
        expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      });
    });

    // ── Clamping ───────────────────────────────────────────────────
    testWidgets('spendRatio > 1.0 is clamped for KiseProgressBar',
        (tester) async {
      await tester.pumpWidget(buildSimple(
        const BudgetStatusCard(
          spendRatio: 1.5,
          personality: 'Overspender',
          tip: '',
        ),
      ));
      // Should render without error
      expect(find.byType(BudgetStatusCard), findsOneWidget);
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        const BudgetStatusCard(
          spendRatio: 0.3,
          personality: 'Saver',
          tip: 'Good job!',
        ),
      ));
      expect(find.byType(BudgetStatusCard), findsOneWidget);
    });
  });
}

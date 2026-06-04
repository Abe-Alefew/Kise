import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_pill_filter.dart';
import 'package:kise/features/transactions/presentation/widgets/transaction_filter_bar.dart';

import '../helpers/widget_helper.dart';

void main() {
  const filters = ['All', 'Income', 'Expense'];

  group('TransactionsFilterBar', () {
    // ── Delegation to KisePillFilter ──────────────────────────────
    group('delegates to KisePillFilter', () {
      testWidgets('renders a KisePillFilter', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionsFilterBar(
            filters: filters,
            selectedFilter: 'All',
            onSelected: (_) {},
          ),
        ));
        expect(find.byType(KisePillFilter), findsOneWidget);
      });

      testWidgets('passes options to KisePillFilter', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionsFilterBar(
            filters: filters,
            selectedFilter: 'All',
            onSelected: (_) {},
          ),
        ));
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expense'), findsOneWidget);
      });

      testWidgets('passes selected value to KisePillFilter', (tester) async {
        await tester.pumpWidget(buildSimple(
          TransactionsFilterBar(
            filters: filters,
            selectedFilter: 'Income',
            onSelected: (_) {},
          ),
        ));
        final pill = tester.widget<KisePillFilter>(find.byType(KisePillFilter));
        expect(pill.selected, 'Income');
      });
    });

    // ── onSelected forwarding ──────────────────────────────────────
    group('onSelected callback', () {
      testWidgets('tapping a filter fires onSelected with its value',
          (tester) async {
        String? selected;
        await tester.pumpWidget(buildSimple(
          TransactionsFilterBar(
            filters: filters,
            selectedFilter: 'All',
            onSelected: (v) => selected = v,
          ),
        ));
        await tester.tap(find.text('Expense'));
        await tester.pump();
        expect(selected, 'Expense');
      });

      testWidgets('tapping Income fires onSelected with "Income"',
          (tester) async {
        String? selected;
        await tester.pumpWidget(buildSimple(
          TransactionsFilterBar(
            filters: filters,
            selectedFilter: 'All',
            onSelected: (v) => selected = v,
          ),
        ));
        await tester.tap(find.text('Income'));
        await tester.pump();
        expect(selected, 'Income');
      });
    });

    // ── Empty filters ──────────────────────────────────────────────
    testWidgets('handles empty filters list without error', (tester) async {
      await tester.pumpWidget(buildSimple(
        TransactionsFilterBar(
          filters: const [],
          selectedFilter: '',
          onSelected: (_) {},
        ),
      ));
      expect(find.byType(TransactionsFilterBar), findsOneWidget);
    });
  });
}

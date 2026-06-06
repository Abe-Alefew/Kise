import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_pill_filter.dart';

Widget _buildSubject({
  required List<String> options,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      body: KisePillFilter(
        options: options,
        selected: selected,
        onSelected: onSelected,
      ),
    ),
  );
}

void main() {
  group('KisePillFilter', () {
    // ────────────────────────────────────────────────────
    // Rendering
    // ────────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('renders all option labels', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const ['All', 'Income', 'Expense'],
            selected: 'All',
            onSelected: (_) {},
          ),
        );
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expense'), findsOneWidget);
      });

      testWidgets('renders single option', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const ['Only'],
            selected: 'Only',
            onSelected: (_) {},
          ),
        );
        expect(find.text('Only'), findsOneWidget);
      });

      testWidgets('renders inside a horizontal scroll view', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const ['A', 'B', 'C'],
            selected: 'A',
            onSelected: (_) {},
          ),
        );
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('each option has a ValueKey', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const ['All', 'Active'],
            selected: 'All',
            onSelected: (_) {},
          ),
        );
        expect(find.byKey(const ValueKey('All')), findsOneWidget);
        expect(find.byKey(const ValueKey('Active')), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Interaction — onSelected callback
    // ────────────────────────────────────────────────────
    group('onSelected callback', () {
      testWidgets('tapping an option fires onSelected with that value',
          (tester) async {
        String? tapped;
        await tester.pumpWidget(
          _buildSubject(
            options: const ['All', 'Income', 'Expense'],
            selected: 'All',
            onSelected: (v) => tapped = v,
          ),
        );

        await tester.tap(find.text('Income'));
        await tester.pump();

        expect(tapped, 'Income');
      });

      testWidgets('tapping the already-selected option still fires onSelected',
          (tester) async {
        int callCount = 0;
        await tester.pumpWidget(
          _buildSubject(
            options: const ['All', 'Income'],
            selected: 'All',
            onSelected: (_) => callCount++,
          ),
        );

        await tester.tap(find.text('All'));
        await tester.pump();

        expect(callCount, 1);
      });

      testWidgets('onSelected is called with correct option string',
          (tester) async {
        final tapped = <String>[];
        await tester.pumpWidget(
          _buildSubject(
            options: const ['One', 'Two', 'Three'],
            selected: 'One',
            onSelected: tapped.add,
          ),
        );

        await tester.tap(find.text('Three'));
        await tester.pump();
        await tester.tap(find.text('Two'));
        await tester.pump();

        expect(tapped, ['Three', 'Two']);
      });
    });

    // ────────────────────────────────────────────────────
    // State — selected pill highlight
    // ────────────────────────────────────────────────────
    group('selected pill appearance', () {
      testWidgets('rebuilds correctly when selected prop changes',
          (tester) async {
        String selected = 'All';

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return KisePillFilter(
                    options: const ['All', 'Income', 'Expense'],
                    selected: selected,
                    onSelected: (v) => setState(() => selected = v),
                  );
                },
              ),
            ),
          ),
        );

        // Tap Income
        await tester.tap(find.text('Income'));
        await tester.pump();

        // After rebuild, Income should be the selected value
        expect(selected, 'Income');
      });
    });

    // ────────────────────────────────────────────────────
    // Edge cases
    // ────────────────────────────────────────────────────
    group('edge cases', () {
      testWidgets('handles empty options list without crashing', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const [],
            selected: '',
            onSelected: (_) {},
          ),
        );
        // Should render without throwing
        expect(find.byType(KisePillFilter), findsOneWidget);
      });

      testWidgets('handles selected value not in options list', (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            options: const ['A', 'B'],
            selected: 'C', // not in list
            onSelected: (_) {},
          ),
        );
        // All options still render, no crash
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_empty_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../helpers/widget_helper.dart';

void main() {
  group('KiseEmptyIndicator', () {
    // ── Required title ─────────────────────────────────────────────
    group('title rendering', () {
      testWidgets('displays the required title', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'No transactions yet'),
        ));
        await tester.pumpAndSettle();
        expect(find.text('No transactions yet'), findsOneWidget);
      });

      testWidgets('title renders for different strings', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Nothing here'),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Nothing here'), findsOneWidget);
      });
    });

    // ── Optional subtitle ──────────────────────────────────────────
    group('subtitle rendering', () {
      testWidgets('subtitle shown when provided', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(
            title: 'Empty',
            subtitle: 'Add your first item to get started.',
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Add your first item to get started.'), findsOneWidget);
      });

      testWidgets('no extra Text when subtitle is null', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Empty'),
        ));
        await tester.pumpAndSettle();
        // Only the title text should appear
        expect(find.byType(Text), findsOneWidget);
      });
    });

    // ── Icon ───────────────────────────────────────────────────────
    group('icon', () {
      testWidgets('default icon is LucideIcons.packageOpen', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Empty'),
        ));
        await tester.pumpAndSettle();
        final widget =
            tester.widget<KiseEmptyIndicator>(find.byType(KiseEmptyIndicator));
        expect(widget.icon, LucideIcons.packageOpen);
      });

      testWidgets('custom icon is accepted', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(
            title: 'No debts',
            icon: LucideIcons.landmark,
          ),
        ));
        await tester.pumpAndSettle();
        final widget =
            tester.widget<KiseEmptyIndicator>(find.byType(KiseEmptyIndicator));
        expect(widget.icon, LucideIcons.landmark);
      });

      testWidgets('an Icon widget is present in the tree', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Empty'),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(Icon), findsOneWidget);
      });
    });

    // ── Animation ─────────────────────────────────────────────────
    group('animation', () {
      testWidgets('FadeTransition and ScaleTransition are in the tree',
          (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Empty'),
        ));
        // Let all animation frames complete before checking widget tree.
        await tester.pumpAndSettle();
        // MaterialApp adds its own transitions, so check at least one of each.
        expect(find.byType(FadeTransition), findsAtLeast(1));
        expect(find.byType(ScaleTransition), findsAtLeast(1));
      });

      testWidgets('animation completes without error', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseEmptyIndicator(title: 'Empty'),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(KiseEmptyIndicator), findsOneWidget);
      });
    });

    // ── Theme variants ─────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        const KiseEmptyIndicator(
          title: 'No goals',
          subtitle: 'Create one to start saving.',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No goals'), findsOneWidget);
    });
  });
}

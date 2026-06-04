import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/debt/domain/debt_entity.dart';
import 'package:kise/features/debt/presentation/widgets/status_badge.dart';

import '../helpers/widget_helper.dart';

void main() {
  group('StatusBadge', () {
    // ── Label text per status ──────────────────────────────────────
    group('label text', () {
      testWidgets('shows "pending" for DebtStatus.pending', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.pending),
        ));
        expect(find.text('pending'), findsOneWidget);
      });

      testWidgets('shows "partial" for DebtStatus.partial', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.partial),
        ));
        expect(find.text('partial'), findsOneWidget);
      });

      testWidgets('shows "settled" for DebtStatus.settled', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.settled),
        ));
        expect(find.text('settled'), findsOneWidget);
      });
    });

    // ── Widget structure ───────────────────────────────────────────
    group('widget structure', () {
      testWidgets('renders a Container (pill shape)', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.pending),
        ));
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('contains a Text widget with correct label', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.settled),
        ));
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.data, 'settled');
      });

      testWidgets('label font size is 11', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.pending),
        ));
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.style?.fontSize, 11);
      });

      testWidgets('font weight is w500', (tester) async {
        await tester.pumpWidget(buildSimple(
          const StatusBadge(status: DebtStatus.partial),
        ));
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.style?.fontWeight, FontWeight.w500);
      });
    });

    // ── Each status renders without error ──────────────────────────
    group('all statuses render cleanly', () {
      for (final status in DebtStatus.values) {
        testWidgets('${status.name} renders without error', (tester) async {
          await tester.pumpWidget(buildSimple(StatusBadge(status: status)));
          expect(find.byType(StatusBadge), findsOneWidget);
        });
      }
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        const StatusBadge(status: DebtStatus.settled),
      ));
      expect(find.text('settled'), findsOneWidget);
    });
  });
}

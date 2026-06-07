import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_card_holder.dart';

import '../../../helpers/widget_helper.dart';

void main() {
  group('KiseCardHolder', () {
    // ── Rendering ──────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('renders its child', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(child: Text('Hello card')),
        ));
        expect(find.text('Hello card'), findsOneWidget);
      });

      testWidgets('renders a Container with full width', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(child: SizedBox()),
        ));
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(SizedBox),
            matching: find.byType(Container),
          ).first,
        );
        expect(container.constraints?.maxWidth, double.infinity);
      });

      testWidgets('default border radius is 16', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(child: SizedBox()),
        ));
        final card = tester.widget<KiseCardHolder>(find.byType(KiseCardHolder));
        expect(card.borderRadius, 16.0);
      });

      testWidgets('default padding is 16 on all sides', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(child: SizedBox()),
        ));
        final card = tester.widget<KiseCardHolder>(find.byType(KiseCardHolder));
        expect(card.padding, isNull); // null means default EdgeInsets.all(16)
      });

      testWidgets('default showShadow is true', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(child: SizedBox()),
        ));
        final card = tester.widget<KiseCardHolder>(find.byType(KiseCardHolder));
        expect(card.showShadow, isTrue);
      });
    });

    // ── Custom properties ──────────────────────────────────────────
    group('custom properties', () {
      testWidgets('custom borderRadius is applied', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(borderRadius: 24, child: SizedBox()),
        ));
        final card = tester.widget<KiseCardHolder>(find.byType(KiseCardHolder));
        expect(card.borderRadius, 24.0);
      });

      testWidgets('showShadow=false accepted without error', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(showShadow: false, child: SizedBox()),
        ));
        expect(find.byType(KiseCardHolder), findsOneWidget);
      });

      testWidgets('custom backgroundColor accepted', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(
            backgroundColor: Colors.blue,
            child: SizedBox(),
          ),
        ));
        expect(find.byType(KiseCardHolder), findsOneWidget);
      });

      testWidgets('custom padding overrides default', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(
            padding: EdgeInsets.all(8),
            child: SizedBox(),
          ),
        ));
        final card = tester.widget<KiseCardHolder>(find.byType(KiseCardHolder));
        expect(card.padding, const EdgeInsets.all(8));
      });

      testWidgets('custom borderColor accepted', (tester) async {
        await tester.pumpWidget(buildSimple(
          const KiseCardHolder(
            borderColor: Colors.red,
            child: SizedBox(),
          ),
        ));
        expect(find.byType(KiseCardHolder), findsOneWidget);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(buildSimpleDark(
        const KiseCardHolder(child: Text('dark mode')),
      ));
      expect(find.text('dark mode'), findsOneWidget);
    });
  });
}

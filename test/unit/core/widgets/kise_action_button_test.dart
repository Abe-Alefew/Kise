import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_action_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KiseActionButton', () {
    // ────────────────────────────────────────────────────
    // Rendering — Primary variant (default)
    // ────────────────────────────────────────────────────
    group('primary variant', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(label: 'Sign In', onPressed: () {})),
        );
        expect(find.text('Sign In'), findsOneWidget);
      });

      testWidgets('renders ElevatedButton for primary variant', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Go',
            onPressed: () {},
            variant: KiseButtonVariant.primary,
          )),
        );
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('is full-width by default (expanded=true)', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(label: 'Submit', onPressed: () {})),
        );
        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(ElevatedButton),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == double.infinity,
            ),
          ).first,
        );
        expect(sizedBox.width, double.infinity);
      });
    });

    // ────────────────────────────────────────────────────
    // Rendering — Outline variant
    // ────────────────────────────────────────────────────
    group('outline variant', () {
      testWidgets('renders OutlinedButton for outline variant', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Cancel',
            onPressed: () {},
            variant: KiseButtonVariant.outline,
          )),
        );
        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Rendering — Ghost variant
    // ────────────────────────────────────────────────────
    group('ghost variant', () {
      testWidgets('renders TextButton for ghost variant', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Skip',
            onPressed: () {},
            variant: KiseButtonVariant.ghost,
          )),
        );
        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Loading state
    // ────────────────────────────────────────────────────
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator when isLoading=true',
          (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: true,
          )),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Submit'), findsNothing);
      });

      testWidgets('shows label when isLoading=false', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: false,
          )),
        );
        expect(find.text('Submit'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('tap does nothing when isLoading=true', (tester) async {
        int taps = 0;
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Go',
            onPressed: () => taps++,
            isLoading: true,
          )),
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(taps, 0);
      });
    });

    // ────────────────────────────────────────────────────
    // onPressed callback
    // ────────────────────────────────────────────────────
    group('onPressed', () {
      testWidgets('fires callback when tapped and not loading', (tester) async {
        int taps = 0;
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Click Me',
            onPressed: () => taps++,
          )),
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(taps, 1);
      });

      testWidgets('null onPressed makes button disabled', (tester) async {
        await tester.pumpWidget(
          _wrap(
            const KiseActionButton(label: 'Disabled', onPressed: null),
          ),
        );
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });
    });

    // ────────────────────────────────────────────────────
    // Leading icon
    // ────────────────────────────────────────────────────
    group('leading icon', () {
      testWidgets('renders icon when leadingIcon is provided', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Add',
            onPressed: () {},
            leadingIcon: Icons.add,
          )),
        );
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });

      testWidgets('no icon widget when leadingIcon is null', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(label: 'Plain', onPressed: () {})),
        );
        expect(find.byType(Icon), findsNothing);
      });
    });

    // ────────────────────────────────────────────────────
    // Width / expanded behaviour
    // ────────────────────────────────────────────────────
    group('width behaviour', () {
      testWidgets('fixed width renders SizedBox with that width', (tester) async {
        await tester.pumpWidget(
          _wrap(KiseActionButton(
            label: 'Fixed',
            onPressed: () {},
            expanded: false,
            width: 120,
          )),
        );
        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(ElevatedButton),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 120,
            ),
          ).first,
        );
        expect(sizedBox.width, 120.0);
      });
    });
  });
}

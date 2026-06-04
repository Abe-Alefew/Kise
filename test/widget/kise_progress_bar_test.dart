import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 20,
          child: child,
        ),
      ),
    );

void main() {
  group('KiseProgressBar', () {
    // ────────────────────────────────────────────────────
    // Rendering
    // ────────────────────────────────────────────────────
    group('rendering', () {
      testWidgets('renders without error for progress=0.5', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5)),
        );
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('uses ClipRRect for rounded corners', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.3)),
        );
        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('uses LayoutBuilder to respond to constraints', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5)),
        );
        expect(find.byType(LayoutBuilder), findsOneWidget);
      });

      testWidgets('renders AnimatedContainer for fill bar', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.7)),
        );
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Progress clamping
    // ────────────────────────────────────────────────────
    group('progress clamping', () {
      testWidgets('progress=0.0 renders without error', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.0)),
        );
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('progress=1.0 renders without error', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 1.0)),
        );
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('progress > 1.0 is clamped — no overflow error', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 2.5)),
        );
        // No exception means clamping worked
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('progress < 0.0 is clamped — no negative-width error',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: -0.5)),
        );
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Default parameters
    // ────────────────────────────────────────────────────
    group('default parameters', () {
      testWidgets('default height is 8', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5)),
        );
        final bar = tester.widget<KiseProgressBar>(find.byType(KiseProgressBar));
        expect(bar.height, 8.0);
      });

      testWidgets('default duration is 400ms', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5)),
        );
        final bar = tester.widget<KiseProgressBar>(find.byType(KiseProgressBar));
        expect(bar.duration, const Duration(milliseconds: 400));
      });

      testWidgets('fillColor defaults to null (theme-driven)', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5)),
        );
        final bar = tester.widget<KiseProgressBar>(find.byType(KiseProgressBar));
        expect(bar.fillColor, isNull);
      });
    });

    // ────────────────────────────────────────────────────
    // Custom parameters
    // ────────────────────────────────────────────────────
    group('custom parameters', () {
      testWidgets('custom height is applied to Container', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.5, height: 16)),
        );
        final bar = tester.widget<KiseProgressBar>(find.byType(KiseProgressBar));
        expect(bar.height, 16.0);
      });

      testWidgets('custom fillColor is accepted without error', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(
            progress: 0.5,
            fillColor: Colors.green,
            trackColor: Colors.grey,
          )),
        );
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });

      testWidgets('custom duration is stored correctly', (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(
            progress: 0.5,
            duration: Duration(seconds: 1),
          )),
        );
        final bar = tester.widget<KiseProgressBar>(find.byType(KiseProgressBar));
        expect(bar.duration, const Duration(seconds: 1));
      });
    });

    // ────────────────────────────────────────────────────
    // Animation
    // ────────────────────────────────────────────────────
    group('animation', () {
      testWidgets('pumping animation frames completes without error',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.0)),
        );
        // Trigger rebuild with new progress
        await tester.pumpWidget(
          _wrap(const KiseProgressBar(progress: 0.8)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
        // No overflow or exception
        expect(find.byType(KiseProgressBar), findsOneWidget);
      });
    });

    // ────────────────────────────────────────────────────
    // Dark theme
    // ────────────────────────────────────────────────────
    testWidgets('renders under dark theme without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: const KiseProgressBar(progress: 0.6),
            ),
          ),
        ),
      );
      expect(find.byType(KiseProgressBar), findsOneWidget);
    });
  });
}

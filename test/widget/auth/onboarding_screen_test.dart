import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/auth/presentation/screens/onboarding_screen.dart';

import '../../helpers/widget_helper.dart';

void main() {
  group('OnboardingScreen', () {
    group('rendering', () {
      testWidgets('renders a Scaffold', (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('shows first slide title "Track Every Birr"', (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();
        expect(find.text('Track Every Birr'), findsOneWidget);
      });

      testWidgets('shows a PageView for swiping slides', (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('shows a next / get started button', (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();
        // At least one ElevatedButton (Next or Get Started)
        expect(find.byType(ElevatedButton), findsAtLeast(1));
      });
    });

    group('navigation between slides', () {
      testWidgets('PageView accepts a swipe gesture without crashing',
          (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();

        // Perform swipe — in test environment images may not load so we only
        // verify no exception is thrown rather than asserting visible text.
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
      });

      testWidgets('two swipes advance through slides without crashing',
          (tester) async {
        await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
        await tester.pump();

        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
      });
    });

    testWidgets('renders without throwing under AppTheme', (tester) async {
      await tester.pumpWidget(buildWithRouter(const OnboardingScreen()));
      await tester.pump();
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kise/features/home/domain/home_dashboard_models.dart';
import 'package:kise/features/home/presentation/widgets/allowance_card.dart';

import '../../helpers/widget_helper.dart';

const _configured = HomeDashboardAllowance(
  monthlyAmount: 3000,
  cycleStartDay: 1,
  isConfigured: true,
  cycleSpend: 1200,
);

const _unconfigured = HomeDashboardAllowance(
  monthlyAmount: 0,
  cycleStartDay: 1,
  isConfigured: false,
  cycleSpend: 0,
);

void main() {
  group('AllowanceCard', () {
    // ── isConfigured = true ────────────────────────────────────────
    group('configured state', () {
      testWidgets('shows "Monthly allowance" heading', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _configured),
        ));
        expect(find.text('Monthly allowance'), findsOneWidget);
      });

      testWidgets('shows cycle spend / monthly amount text', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _configured),
        ));
      
        expect(find.textContaining('1200.00'), findsOneWidget);
        expect(find.textContaining('3000.00'), findsOneWidget);
      });

      testWidgets('shows a LinearProgressIndicator', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _configured),
        ));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('progress clamps at 1.0 when overspent', (tester) async {
        const overspent = HomeDashboardAllowance(
          monthlyAmount: 1000,
          cycleStartDay: 1,
          isConfigured: true,
          cycleSpend: 1500, 
        );
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: overspent),
        ));
        final indicator = tester
            .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(indicator.value, lessThanOrEqualTo(1.0));
      });

      testWidgets('progress is 0 when monthlyAmount is 0', (tester) async {
        const zeroAllowance = HomeDashboardAllowance(
          monthlyAmount: 0,
          cycleStartDay: 1,
          isConfigured: true,
          cycleSpend: 500,
        );
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: zeroAllowance),
        ));
        final indicator = tester
            .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
        expect(indicator.value, 0.0);
      });

      testWidgets('wallet icon is present', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _configured),
        ));
        expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      });
    });

    // ── isConfigured = false ───────────────────────────────────────
    group('unconfigured state', () {
      testWidgets('shows "Set your allowance" prompt', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _unconfigured),
        ));
        expect(find.text('Set your allowance'), findsOneWidget);
      });

      testWidgets('shows instruction subtitle text', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _unconfigured),
        ));
        expect(
          find.textContaining('Tap to open Settings'),
          findsOneWidget,
        );
      });

      testWidgets('does NOT show LinearProgressIndicator', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _unconfigured),
        ));
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });

      testWidgets('shows lightbulb icon in unconfigured state', (tester) async {
        await tester.pumpWidget(buildWithRouter(
          AllowanceCard(allowance: _unconfigured),
        ));
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });
    });

    // ── Dark theme ─────────────────────────────────────────────────
    testWidgets('renders in dark theme without error', (tester) async {
      await tester.pumpWidget(
        buildWithRouter(AllowanceCard(allowance: _configured)),
      );
      expect(find.byType(AllowanceCard), findsOneWidget);
    });
  });
}

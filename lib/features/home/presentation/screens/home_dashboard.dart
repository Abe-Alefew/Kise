import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:kise/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kise/features/home/presentation/providers/home_dashboard_notifier.dart';
import 'package:kise/features/home/presentation/widgets/allowance_card.dart';
import 'package:kise/features/home/presentation/widgets/balance_card.dart';
import 'package:kise/features/home/presentation/widgets/budget_status_card.dart';
import 'package:kise/features/home/presentation/widgets/catagory_spending_chart.dart';
import 'package:kise/features/home/presentation/widgets/recent_transaction_list.dart';
import 'package:kise/features/home/presentation/widgets/trend_chart.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final authUser = ref.watch(authStateProvider)?.user;

    return Scaffold(
      backgroundColor:
          isDark ? AppColorsDark.scaffold : AppColorsLight.scaffold,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DashboardErrorView(
            message: error is ApiException ? error.message : error.toString(),
            onRetry: () => ref.read(homeDashboardProvider.notifier).refresh(),
          ),
          data: (bundle) {
            final displayName = bundle.displayName.isNotEmpty
                ? bundle.displayName
                : authUser?.fullName ?? 'there';

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeDashboardProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textHint
                            : AppColorsLight.textHint,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textHeading
                            : AppColorsLight.textHeading,
                      ),
                    ),
                    const SizedBox(height: 24),
                    BalanceCard(
                      totalBalance: bundle.balance.total,
                      income: bundle.balance.income,
                      expenses: bundle.balance.expenses,
                      currency: bundle.balance.currency,
                    ),
                    const SizedBox(height: 24),
                    AllowanceCard(allowance: bundle.allowance),
                    const SizedBox(height: 16),
                    BudgetStatusCard(
                      spendRatio: bundle.budgetStatus.spendRatio,
                      personality: bundle.budgetStatus.personality,
                      tip: bundle.budgetStatus.tip,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '6-month trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textHeading
                            : AppColorsLight.textHeading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: TrendChart(trend: bundle.trend),
                    ),
                    const SizedBox(height: 32),
                    CategorySpendingChart(
                      categories: bundle.categorySpending,
                      currency: bundle.balance.currency,
                    ),
                    const SizedBox(height: 32),
                    RecentTransactionsList(
                      transactions: bundle.recentTransactions,
                      currency: bundle.balance.currency,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: isDark ? AppColorsDark.textHint : AppColorsLight.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textHeading
                    : AppColorsLight.textHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppColorsDark.textBody : AppColorsLight.textBody,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

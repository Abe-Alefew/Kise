import 'package:flutter/material.dart';

import '../../../../core/widgets/kise_card_holder.dart';

import '../widgets/analytics_bar_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              /// MONTHLY SUMMARY
              KiseCardHolder(

                backgroundColor:
                    Theme.of(context).colorScheme.primary,

                borderColor:
                    Colors.transparent,

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      "Monthly Spending",

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(

                      "ETB 45,000",

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// BAR CHART
              const KiseCardHolder(
                child: AnalyticsBarChart(selectedFilter: "All"),
              ),

              const SizedBox(height: 24),

              /// CATEGORY BREAKDOWN
              const Text(

                "Top Categories",

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _categoryCard(
                title: "Education",
                amount: "ETB 20,000",
                percent: "44%",
                color: Theme.of(context).colorScheme.primary,
              ),

              _categoryCard(
                title: "Entertainment",
                amount: "ETB 5,000",
                percent: "12%",
                color: Theme.of(context).colorScheme.secondary,
              ),

              _categoryCard(
                title: "Transport",
                amount: "ETB 3,000",
                percent: "8%",
                color: Theme.of(context).colorScheme.tertiary,
              ),

              const SizedBox(height: 24),

              /// INSIGHTS
              const Text(

                "Insights",

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const KiseCardHolder(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      "• Your highest spending was in April.",
                    ),

                    SizedBox(height: 10),

                    Text(
                      "• Education takes 44% of your expenses.",
                    ),

                    SizedBox(height: 10),

                    Text(
                      "• Savings improved by 12% this month.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard({
    required String title,
    required String amount,
    required String percent,
    required Color color,
  }) {

    return Padding(

      padding:
          const EdgeInsets.only(bottom: 14),

      child: KiseCardHolder(

        child: Row(

          children: [

            CircleAvatar(
              radius: 8,
              backgroundColor: color,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(title),
            ),

            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 12),

            Text(percent),
          ],
        ),
      ),
    );
  }
}
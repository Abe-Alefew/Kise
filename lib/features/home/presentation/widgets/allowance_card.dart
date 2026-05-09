import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';

class AllowanceCard extends StatelessWidget {
  const AllowanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return KiseCardHolder(
      // Kirubel's core widget
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFFD4AF37),
          ),
          title: const Text(
            "Set your allowance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          subtitle: const Text(
            "Go to Settings to set your monthly budget and unlock spending alerts.",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

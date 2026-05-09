import 'package:flutter/material.dart';
import '../../../../core/widgets/kise_card_holder.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "View all",
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KiseCardHolder(

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFFA855F7),
              ),
            ),
            title: const Text(
              "Education",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "something. April 15",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: const Text(
              "-20,000.00 ETB",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

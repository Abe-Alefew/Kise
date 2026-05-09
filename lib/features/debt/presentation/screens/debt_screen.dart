import 'package:flutter/material.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt Book')),
      body: const Center(
        child: Text('This is Debt Screen'),
      ),
    );
  }
}

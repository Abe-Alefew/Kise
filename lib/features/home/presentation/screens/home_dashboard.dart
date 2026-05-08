import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Dashboard')),
      body: const Center(
        child: Text('This is Home Dashboard Screen'),
      ),
    );
  }
}

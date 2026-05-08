import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/routing/app_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is Login Screen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Login (Go to Home)'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

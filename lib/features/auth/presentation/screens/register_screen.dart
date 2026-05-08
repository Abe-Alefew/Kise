import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/routing/app_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is Register Screen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Register (Go to Home)'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

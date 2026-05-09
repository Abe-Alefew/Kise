import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/routing/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is Onboarding Screen'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to Login'),
            ),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

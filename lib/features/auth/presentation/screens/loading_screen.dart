import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 6,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: Image.asset(
                  'assets/images/kise_logo.png',
                  width: AppDimensions.logoWidth,
                  height: AppDimensions.logoHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

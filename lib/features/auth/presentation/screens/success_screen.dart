import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';

enum SuccessType { registration, signIn }

class SuccessScreen extends StatefulWidget {
  final SuccessType type;

  const SuccessScreen({super.key, required this.type});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  static const Duration _autoNavDelay = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    Future.delayed(_autoNavDelay, () {
      if (!mounted) return;
      context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    final labelText = widget.type == SuccessType.registration
        ? 'Registration'
        : 'Logged In';

    return PopScope(
      
      canPop: false,
      child: Scaffold(
        backgroundColor: scaffoldColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Center content ──────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/checklist.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    labelText,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColorsLight.textHint,
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Success!',
                    style: (textTheme.displayMedium ?? textTheme.headlineLarge)
                        ?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 38
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
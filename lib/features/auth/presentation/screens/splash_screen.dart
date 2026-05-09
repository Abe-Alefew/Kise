import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/widgets.dart';

class SplashScreen extends StatelessWidget {
	const SplashScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;

		return Scaffold(
			backgroundColor: AppColorsLight.scaffold,
			body: Stack(
				children: [
					Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								Image.asset(
									'assets/images/kise_logo.png',
									width: AppDimensions.logoWidth,
									height: AppDimensions.logoHeight,
									fit: BoxFit.contain,
								),
								const SizedBox(height: 2.5),
								Text(
									'your personal budget tracker',
									style: GoogleFonts.playfairDisplay(
										textStyle: textTheme.bodyMedium?.copyWith(
											color: colorScheme.secondary,
											fontStyle: FontStyle.italic,
											fontWeight: FontWeight.w700,
											fontSize: 19,
										),
									),
									textAlign: TextAlign.center,
								),
							],
						),
					),
					Positioned.fill(
						child: Padding(
							padding: AppDimensions.pagePadding,
							child: Align(
								alignment: Alignment.bottomRight,
								child: SizedBox(
									width: 90,
                  height: 37,
									// TODO: restore production navigation logic
									child: KiseActionButton(
										label: 'NEXT',
										onPressed: () => context.go(AppRoutes.onboarding),
										expanded: false,
                    width:85,
                    height: 37,
                    textColor: AppColorsLight.textOnPrimary,
                    fontSize: 14,
									),
								),
							),
						),
					),
				],
			),
		);
	}
}

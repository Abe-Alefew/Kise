import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kise/core/theme/colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
	const OnboardingScreen({super.key});

	@override
	State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
	final PageController _controller = PageController();
	int _currentIndex = 0;

	final List<_OnboardingSlide> _slides = const [
		_OnboardingSlide(
			title: 'Track Every Birr',
			body:
					'Built for Ethiopian students. log your income, expenses and savings in seconds. Know exactly where your money goes.',
			imagePath: 'assets/images/onboarding_1.png',
		),
		_OnboardingSlide(
			title: 'Understand your habits',
			body:
					'See smart analytics, spot spending trends, and make better decisions. Stay on top of your goals smarter every month.',
			imagePath: 'assets/images/onboarding_2.png',
		),
		_OnboardingSlide(
			title: 'Debt and Lending',
			body:
					'Track money you lend or borrow. Record paid amounts, set reminders, and keep your balances clear.',
			imagePath: 'assets/images/onboarding_3.png',
		),
	];

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	void _nextPage() {
		if (_currentIndex < _slides.length - 1) {
			_controller.nextPage(
				duration: const Duration(milliseconds: 300),
				curve: Curves.easeOut,
			);
		} else {
			// TODO: restore production navigation logic
			context.go(AppRoutes.login);
		}
	}

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;
		final slide = _slides[_currentIndex];
		final isLastSlide = _currentIndex == _slides.length - 1;

		return Scaffold(
			resizeToAvoidBottomInset: true,
			body: SafeArea(
				child: Padding(
					padding: AppDimensions.pagePadding,
					child: LayoutBuilder(
						builder: (context, constraints) {
							// imageHeight is derived from the viewport height (outside the
							// scroll view) so it remains stable regardless of content size.
							final imageHeight = constraints.maxHeight * 0.44;
							return SingleChildScrollView(
								physics: const ClampingScrollPhysics(),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.center,
									children: [
										const SizedBox(height: 25),
										Text(
											'KISE',
											style: textTheme.labelMedium?.copyWith(
												color: colorScheme.primary,
												fontWeight: FontWeight.w700,
												fontSize: 39,
											),
											textAlign: TextAlign.center,
										),
										const SizedBox(height: AppDimensions.xxl),
										SizedBox(
											height: imageHeight,
											child: PageView.builder(
												controller: _controller,
												itemCount: _slides.length,
												onPageChanged: (index) {
													setState(() => _currentIndex = index);
												},
												itemBuilder: (context, index) {
													final s = _slides[index];
													return Center(
														child: Image.asset(
															s.imagePath,
															fit: BoxFit.contain,
														),
													);
												},
											),
										),
										const SizedBox(height: AppDimensions.lg),
										_DotIndicators(
											count: _slides.length,
											activeIndex: _currentIndex,
										),
										const SizedBox(height: AppDimensions.lg),
										Text(
											slide.title,
											style: textTheme.displayMedium?.copyWith(
												color: colorScheme.onSecondary,
												fontWeight: FontWeight.w900,
												fontSize: 29,
											),
											textAlign: TextAlign.center,
										),
										const SizedBox(height: AppDimensions.lg),
										Text(
											slide.body,
											style: textTheme.bodyMedium?.copyWith(
												color: colorScheme.onSurface.withValues(alpha: 0.7),
												fontSize: 16,
											),
											textAlign: TextAlign.center,
										),
										// Fixed gap replaces Spacer — Spacer requires a bounded
										// parent height which SingleChildScrollView cannot provide.
										const SizedBox(height: AppDimensions.xxl),
										if (isLastSlide)
											Align(
												alignment: Alignment.center,
												child: KiseActionButton(
													label: 'GET STARTED',
													leadingIcon: LucideIcons.checkCircle,
													onPressed: _nextPage,
													expanded: false,
													width: 181,
													height: 37,
													textColor: AppColorsLight.textOnPrimary,
													fontSize: 14,
												),
											)
										else
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													KiseActionButton(
														label: 'SKIP',
														variant: KiseButtonVariant.ghost,
														expanded: false,
														textColor: colorScheme.onSecondary.withValues(alpha: 0.7),
														fontSize: 14,
														onPressed: () {
															context.go(AppRoutes.login);
														},
													),
													KiseActionButton(
														label: 'NEXT',
														onPressed: _nextPage,
														expanded: false,
														width: 85,
														height: 37,
														textColor: AppColorsLight.textOnPrimary,
														fontSize: 14,
													),
												],
											),
										const SizedBox(height: AppDimensions.md),
									],
								),
							);
						},
					),
				),
			),
		);
	}
}

class _DotIndicators extends StatelessWidget {
	const _DotIndicators({required this.count, required this.activeIndex});

	final int count;
	final int activeIndex;

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		const double dotSize = AppDimensions.sm;

		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(count, (index) {
				final isActive = index == activeIndex;
				return AnimatedContainer(
					duration: const Duration(milliseconds: 250),
					margin: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
					width: dotSize,
					height: dotSize,
					decoration: BoxDecoration(
						shape: BoxShape.circle,
						color: isActive ? colorScheme.primary : Colors.transparent,
						border: Border.all(
							color: isActive
									? colorScheme.primary
									: colorScheme.primary.withValues(alpha: 0.4),
							width: 1.5,
						),
					),
				);
			}),
		);
	}
}

class _OnboardingSlide {
	const _OnboardingSlide({
		required this.title,
		required this.body,
		required this.imagePath,
	});

	final String title;
	final String body;
	final String imagePath;
}

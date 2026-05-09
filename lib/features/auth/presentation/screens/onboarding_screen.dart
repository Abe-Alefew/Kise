import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
					'Built for Ethiopian students, keep your income, expenses, and savings in sync. Know exactly where your money goes.',
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

		return Scaffold(
			body: SafeArea(
				child: Padding(
					padding: AppDimensions.pagePadding,
					child: Column(
						children: [
							Expanded(
								child: PageView.builder(
									controller: _controller,
									itemCount: _slides.length,
									onPageChanged: (index) {
										setState(() {
											_currentIndex = index;
										});
									},
									itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Expanded — takes all remaining vertical space flexibly
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                              child: Image.asset(
                                slide.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        Text(
                          'KISE',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        Text(
                          slide.title,
                          style: textTheme.displaySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          slide.body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
							if (_currentIndex == 1)
								Row(
									children: [
										Expanded(
											child: KiseActionButton(
												label: 'SKIP',
												variant: KiseButtonVariant.ghost,
												onPressed: () {
													// TODO: restore production navigation logic
													context.go(AppRoutes.login);
												},
											),
										),
										const SizedBox(width: AppDimensions.sm),
										Expanded(
											child: KiseActionButton(
												label: 'NEXT',
												onPressed: _nextPage,
											),
										),
									],
								)
							else
								KiseActionButton(
									label: _currentIndex == _slides.length - 1
											? 'GET STARTED'
											: 'NEXT',
									onPressed: _nextPage,
								),
						],
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

		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(count, (index) {
				final isActive = index == activeIndex;
				return AnimatedContainer(
					  duration: const Duration(milliseconds: 250),
					  margin: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
					  width: isActive ? AppDimensions.lg : AppDimensions.sm,
					  height: AppDimensions.sm,
					decoration: BoxDecoration(
						color: isActive
								? colorScheme.primary
								: colorScheme.onSurface.withValues(alpha: 0.2),
						borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
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

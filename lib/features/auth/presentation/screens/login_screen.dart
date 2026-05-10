import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/widgets.dart';
import 'success_screen.dart';

class LoginScreen extends StatefulWidget {
	const LoginScreen({super.key});

	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _handleLogin() async {
		if (!(_formKey.currentState?.validate() ?? false)) return;

		final router = GoRouter.of(context);
		router.push(AppRoutes.loading);

		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(AppStorageKeys.authLoggedIn, true);
		if (!mounted) return;
		if (router.canPop()) {
			router.pop();
		}
		router.go(AppRoutes.success, extra: SuccessType.signIn);
	}

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;
		final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

		return Scaffold(
			backgroundColor: colorScheme.primary,
			body: Stack(
				fit: StackFit.expand,
				children: [
					// ── Gold top area with back button + title ──
					SafeArea(
						child: Padding(
              padding: const EdgeInsets.all(12),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									IconButton(
										onPressed: () => context.go(AppRoutes.onboarding),
										icon: Icon(Icons.arrow_back, color: scaffoldColor),
										
                     constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 34,
                      ),
									),
									const SizedBox(height: AppDimensions.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:  Text(
										'Log In',
                    
										style: textTheme.displayLarge?.copyWith(
											color: scaffoldColor,
											fontWeight: FontWeight.w700,
											letterSpacing: 1.8,
                      
										),
                    
									),
                  )
									
								],
							),
						),
					),

					// ── White rounded card sliding up ──
					Positioned(
						left: 0,
						right: 0,
						// Sits ~228px from top on a ~874px frame → ~26% down
						top: MediaQuery.of(context).size.height * 0.26,
						bottom: 0,
						child: Container(
							decoration: BoxDecoration(
								color: scaffoldColor,
								borderRadius: const BorderRadius.vertical(
									top: Radius.circular(AppDimensions.radiusAuthCard),
								),
								boxShadow: [
									BoxShadow(
										color: colorScheme.shadow.withValues(alpha: 0.25),
										blurRadius: 4,
										offset: const Offset(1, -3),
									),
								],
							),
							child: SingleChildScrollView(
								padding: const EdgeInsets.fromLTRB(
									AppDimensions.md,
									100,
									AppDimensions.md,
									AppDimensions.lg,
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										// ── Email ──
										Text(
											'YOUR EMAIL ADDRESS',
											style: textTheme.bodyMedium?.copyWith(
												color: AppColorsLight.textHint,
												fontWeight: FontWeight.w800,
											),
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: AppDimensions.sm),
										KiseFormSystem(
											formKey: _formKey,
											children: [
												KiseTextField(
													label: '',
													controller: _emailController,
													keyboardType: TextInputType.emailAddress,
													validator: Validators.email,
                        
												),

												const SizedBox(height: AppDimensions.sm),

												// ── Password row ──
												Row(
													mainAxisAlignment: MainAxisAlignment.spaceBetween,
													children: [
														Flexible(
															child: Text(
																'PASSWORD',
																style: textTheme.bodyMedium?.copyWith(
																	color: AppColorsLight.textHint,
																	fontWeight: FontWeight.w800,
																),
																maxLines: 1,
																overflow: TextOverflow.ellipsis,
															),
														),
														Flexible(
															child: Align(
																alignment: Alignment.centerRight,
																child: GestureDetector(
																	onTap: () {},
																	child: Text(
																		'Forgot?',
																		style: textTheme.bodyMedium?.copyWith(
																			color: colorScheme.primaryContainer,
																			fontWeight: FontWeight.w600,
																		),
																		maxLines: 1,
																		overflow: TextOverflow.ellipsis,
																	),
																),
															),
														),
													],
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _passwordController,
													isPassword: true,
													validator: Validators.password,
												),

												const SizedBox(height: AppDimensions.lg),

												// ── Sign In button (centered, fixed width) ──
												Center(
													child: KiseActionButton(
														label: 'SIGN IN',
														onPressed: _handleLogin,
														height: AppDimensions.authButtonHeight,
														width: AppDimensions.authButtonWidth,
														expanded: false,
                            fontSize: 14,
													),
												),
											],
										),

										const SizedBox(height: AppDimensions.xxl),

										// ── Register link ──
										Center(
											child: Text.rich(
												TextSpan(
													children: [
														TextSpan(
															text: 'New to Kise? ',
															style: textTheme.bodyMedium?.copyWith(
																color: AppColorsLight.textHint,
																fontSize: AppDimensions.fontSizeCaption,
															),
														),
														WidgetSpan(
															alignment: PlaceholderAlignment.middle,
															child: GestureDetector(
																onTap: () => context.go(AppRoutes.register),
																child: Text(
																	'Register Here',
																	style: textTheme.bodyMedium?.copyWith(
																		color: colorScheme.primary,
																		fontSize: AppDimensions.fontSizeCaption,
																	),
																),
															),
														),
													],
												),
												textAlign: TextAlign.center,
											),
										),

										const SizedBox(height: AppDimensions.xxxl),

										// ── Logo at bottom ──
										Center(
											child: Image.asset(
												'assets/images/kise_logo.png',
												width: AppDimensions.logoWidth,
												height: AppDimensions.logoHeight,
												fit: BoxFit.contain,
											),
										),

										const SizedBox(height: AppDimensions.md),
									],
								),
							),
						),
					),
				],
			),
		);
	}
}

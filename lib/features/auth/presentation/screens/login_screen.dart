import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
	const LoginScreen({super.key});

	@override
	ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	String? _submitErrorMessage;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _handleLogin() async {
		if (!(_formKey.currentState?.validate() ?? false)) return;
		setState(() {
			_submitErrorMessage = null;
		});
		ref.read(authNotifierProvider.notifier).clearError();

		try {
			await ref.read(authNotifierProvider.notifier).login(
				email: _emailController.text.trim(),
				password: _passwordController.text,
			);
		} on ApiException catch (error) {
			if (!mounted) return;
			setState(() {
				_submitErrorMessage = error.message;
			});
			return;
		} catch (_) {
			if (!mounted) return;
			setState(() {
				_submitErrorMessage = 'Unable to sign in. Please try again.';
			});
			return;
		}

		if (!mounted) return;
		final authState = ref.read(authNotifierProvider).value;
		if (authState?.redirectRoute != null) {
			final successType = authState?.successType;
			if (successType != null) {
				context.go(authState!.redirectRoute!, extra: successType);
			} else {
				context.go(authState!.redirectRoute!);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		final authAsync = ref.watch(authNotifierProvider);
		final authState = authAsync.value;
		final isLoading = authAsync.isLoading || authState?.isLoading == true;
		final errorMessage =
				_submitErrorMessage ?? authState?.errorMessage;
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
												if (errorMessage != null &&
													errorMessage.isNotEmpty) ...[
													Text(
														errorMessage,
														style: textTheme.bodySmall?.copyWith(
															color: colorScheme.error,
															fontWeight: FontWeight.w600,
														),
													),
													const SizedBox(height: AppDimensions.md),
												],

												// ── Sign In button (centered, fixed width) ──
												Center(
													child: KiseActionButton(
														label: 'SIGN IN',
														onPressed: _handleLogin,
														isLoading: isLoading,
														height: AppDimensions.authButtonHeight,
														width: AppDimensions.authButtonWidth,
														expanded: false,
                            fontSize: 14,
                            textColor:  AppColorsLight.textOnPrimary,
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

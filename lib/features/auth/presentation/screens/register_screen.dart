import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({super.key});

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

	final TextEditingController _firstNameController = TextEditingController();
	final TextEditingController _lastNameController = TextEditingController();
	final TextEditingController _phoneController = TextEditingController();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	final TextEditingController _confirmController = TextEditingController();
	final TextEditingController _schoolController = TextEditingController();
	final TextEditingController _departmentController = TextEditingController();
	final TextEditingController _yearController = TextEditingController();
	final TextEditingController _budgetController = TextEditingController();
	final TextEditingController _currencyController = TextEditingController();

	@override
	void dispose() {
		_firstNameController.dispose();
		_lastNameController.dispose();
		_phoneController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		_confirmController.dispose();
		_schoolController.dispose();
		_departmentController.dispose();
		_yearController.dispose();
		_budgetController.dispose();
		_currencyController.dispose();
		super.dispose();
	}

	Future<void> _handleRegister() async {
		if (!(_formKey.currentState?.validate() ?? false)) return;

		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(AppStorageKeys.authLoggedIn, true);
		if (!mounted) return;
		context.go(AppRoutes.home);
	}

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;
		final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
		final labelStyle = textTheme.bodyMedium?.copyWith(
			color: AppColorsLight.textHint,
			fontWeight: FontWeight.w600,
		);

		return Scaffold(
			backgroundColor: colorScheme.primary,
			body: Stack(
				fit: StackFit.expand,
				children: [
					// ── Gold top area with back button + title ──
					SafeArea(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									IconButton(
										onPressed: () => context.go(AppRoutes.onboarding),
										icon: Icon(Icons.arrow_back, color: scaffoldColor),
										padding: EdgeInsets.zero,
									),
									const SizedBox(height: AppDimensions.sm),
									Text(
										'Register',
										style: textTheme.displayLarge?.copyWith(
											color: scaffoldColor,
											fontWeight: FontWeight.w700,
											letterSpacing: 1.8,
										),
									),
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
									AppDimensions.xl2,
									AppDimensions.md,
									AppDimensions.lg,
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'FIRST NAME',
											style: labelStyle,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: AppDimensions.sm),
										KiseFormSystem(
											formKey: _formKey,
											children: [
												KiseTextField(
													label: '',
													controller: _firstNameController,
													validator: Validators.requiredField,
												),
												Text(
													'LAST NAME',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _lastNameController,
													validator: Validators.requiredField,
												),
												Text(
													'PHONE NUMBER',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _phoneController,
													keyboardType: TextInputType.phone,
													validator: Validators.requiredField,
												),
												Text(
													'YOUR EMAIL ADDRESS',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _emailController,
													keyboardType: TextInputType.emailAddress,
													validator: Validators.email,
												),
												Text(
													'PASSWORD',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _passwordController,
													isPassword: true,
													validator: Validators.password,
												),
												Text(
													'CONFIRM PASSWORD',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _confirmController,
													isPassword: true,
													validator: (value) {
														if (value == null || value.isEmpty) {
															return 'This field is required';
														}
														if (value != _passwordController.text) {
															return 'Passwords do not match';
														}
														return null;
													},
												),
												Text(
													'SCHOOL',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _schoolController,
													validator: Validators.requiredField,
												),
												Text(
													'DEPARTMENT',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _departmentController,
													validator: Validators.requiredField,
												),
												Text(
													'YEAR OF STUDY',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _yearController,
													keyboardType: TextInputType.number,
													validator: Validators.requiredField,
												),
												Text(
													'MONTHLY BUDGET',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _budgetController,
													keyboardType: TextInputType.number,
													validator: Validators.requiredField,
												),
												Text(
													'CURRENCY',
													style: labelStyle,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: AppDimensions.sm),
												KiseTextField(
													label: '',
													controller: _currencyController,
													validator: Validators.requiredField,
												),

												const SizedBox(height: AppDimensions.lg),

												Center(
													child: KiseActionButton(
														label: 'SIGN UP',
														onPressed: _handleRegister,
														height: AppDimensions.authButtonHeight,
														width: AppDimensions.authButtonWidth,
														expanded: false,
													),
												),
											],
										),

										const SizedBox(height: AppDimensions.xxl),

										Center(
											child: Text.rich(
												TextSpan(
													children: [
														TextSpan(
															text: 'Already have an account? ',
															style: textTheme.bodyMedium?.copyWith(
																color: AppColorsLight.textHint,
																fontSize: AppDimensions.fontSizeCaption,
															),
														),
														WidgetSpan(
															alignment: PlaceholderAlignment.middle,
															child: GestureDetector(
																onTap: () => context.go(AppRoutes.login),
																child: Text(
																	'Log In',
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
      ),],
			),
		);
	}
}

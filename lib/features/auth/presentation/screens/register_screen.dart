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

  int _currentStep = 0;
  String _preferredLanguage = 'English';
  String? _selectedCurrency;
  bool _termsAccepted = false;

  static const List<String> _stepTitles = [
    'Personal\nInformation',
    'Account\nInformation',
    'Student\nInformation',
    'Preferences',
  ];

  static const List<String> _currencyOptions = ['ETB', 'USD'];

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

  void _handleBack() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep -= 1;
      });
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentStep < _stepTitles.length - 1) {
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    await _handleRegister();
  }

  // ── Shared underline input field ──────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? sublabel,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: AppColorsLight.textHint,
      fontWeight: FontWeight.w600,
    );

    final displayLabel = sublabel != null
        ? '$label (${sublabel.toLowerCase()})'
        : label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          displayLabel,
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.sm),
        KiseTextField(
          label: '',
          controller: controller,
          keyboardType: keyboardType,
          isPassword: isPassword,
          validator: validator,
        ),
      ],
    );
  }

  // ── Step content builders ─────────────────────────────────────────────────

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _firstNameController,
          label: 'FIRST NAME',
          validator: Validators.requiredField,
        ),
        _buildInputField(
          controller: _lastNameController,
          label: 'LAST NAME',
          validator: Validators.requiredField,
        ),
        _buildInputField(
          controller: _phoneController,
          label: 'USERNAME',
          sublabel: 'optional',
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'EMAIL ADDRESS',
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        _buildInputField(
          controller: _phoneController,
          label: 'PHONE NUMBER',
          sublabel: 'Optional',
          keyboardType: TextInputType.phone,
        ),
        _buildInputField(
          controller: _passwordController,
          label: 'PASSWORD',
          isPassword: true,
          validator: Validators.password,
        ),
        _buildInputField(
          controller: _confirmController,
          label: 'CONFIRM YOUR PASSWORD',
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
      ],
    );
  }

  Widget _buildStudentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _schoolController,
          label: 'UNIVERSITY NAME',
          validator: Validators.requiredField,
        ),
        _buildInputField(
          controller: _departmentController,
          label: 'DEPARTMENT',
          validator: Validators.requiredField,
        ),
        _buildInputField(
          controller: _yearController,
          label: 'YEAR OF STUDY',
          keyboardType: TextInputType.number,
          validator: Validators.requiredField,
        ),
      ],
    );
  }

  Widget _buildPreferencesStep({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final labelStyle = textTheme.bodySmall?.copyWith(
      color: AppColorsLight.textHint,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontSize: AppDimensions.fontSizeCaption,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Preferred Language ──
        Text('PREFERRED LANGUAGE', style: labelStyle),
        const SizedBox(height: AppDimensions.xs),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioOption(
                label: 'ENGLISH',
                value: 'English',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(width: AppDimensions.lg),
              _buildRadioOption(
                label: 'AMHARIC',
                value: 'Amharic',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.md),

        // ── Currency Dropdown ──
        Text('CURRENCY', style: labelStyle),
        const SizedBox(height: AppDimensions.xs),
        _buildCurrencyDropdown(colorScheme: colorScheme, textTheme: textTheme),

        const SizedBox(height: AppDimensions.md),

        // ── Terms checkbox ──
        GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                  activeColor: colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                  side: BorderSide(
                    color: AppColorsLight.textHint.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'I agree to the ',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColorsLight.textHint,
                          fontSize: AppDimensions.fontSizeCaption,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.terms),
                          child: Text(
                            'terms and the conditions of Kise',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontSize: AppDimensions.fontSizeCaption,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Radio option widget ───────────────────────────────────────────────────

  Widget _buildRadioOption({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = _preferredLanguage == value;
    return GestureDetector(
      onTap: () => setState(() => _preferredLanguage = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _preferredLanguage,
            onChanged: (val) {
              if (val != null) setState(() => _preferredLanguage = val);
            },
            activeColor: colorScheme.primary,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isSelected ? colorScheme.primary : AppColorsLight.textHint,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              fontSize: AppDimensions.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  // ── Currency dropdown ─────────────────────────────────────────────────────

  Widget _buildCurrencyDropdown({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCurrency,
      hint: Text(
        'SELECT CURRENCY',
        style: textTheme.bodySmall?.copyWith(
          color: AppColorsLight.textHint,
          fontWeight: FontWeight.w500,
          fontSize: AppDimensions.fontSizeCaption,
          letterSpacing: 0.4,
        ),
      ),
      items: _currencyOptions
          .map(
            (currency) => DropdownMenuItem<String>(
              value: currency,
              child: Text(
                currency,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColorsLight.textBody,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedCurrency = value);
        _currencyController.text = value ?? '';
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsLight.textHint.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        border: const UnderlineInputBorder(),
      ),
      icon: Icon(Icons.keyboard_arrow_down, color: AppColorsLight.textHint),
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      isExpanded: true,
    );
  }

  // ── Step dot indicator ────────────────────────────────────────────────────

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        _stepTitles.length,
        (index) {
          final isActive = index == _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: AppDimensions.xs),
            height: 5,
            width: isActive ? 24 : 10,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.25),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusRound),
            ),
          );
        },
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final isLastStep = _currentStep == _stepTitles.length - 1;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gold header: back arrow + title ──────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back arrow
                  IconButton(
                    onPressed: _handleBack,
                    icon: Icon(
                      Icons.arrow_back,
                      color: scaffoldColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // "Register" title
                  Text(
                    'Register',
                    style: textTheme.displayLarge?.copyWith(
                      color: scaffoldColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card ───────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.24,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusAuthCard),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.md,
                  AppDimensions.lg,
                  AppDimensions.md,
                  AppDimensions.lg,
                ),
                child: KiseFormSystem(
                  formKey: _formKey,
                  children: [
                    // Step dots
                    _buildStepIndicator(colorScheme),
                    const SizedBox(height: AppDimensions.md),

                    // Step title — large, bold, uppercase, two-line
                    Text(
                      _stepTitles[_currentStep].toUpperCase(),
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColorsLight.textBody,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Step content
                    if (_currentStep == 0)
                      _buildPersonalStep()
                    else if (_currentStep == 1)
                      _buildAccountStep()
                    else if (_currentStep == 2)
                      _buildStudentStep()
                    else
                      _buildPreferencesStep(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),

                    const SizedBox(height: AppDimensions.lg),

                    // ── Primary action button — full width ────────────────
                    KiseActionButton(
                      label: isLastStep ? 'CONTINUE' : 'NEXT',
                      onPressed: _handlePrimaryAction,
                      height: AppDimensions.authButtonHeight,
                      width: double.infinity,
                      expanded: true,
                    ),

                    const SizedBox(height: AppDimensions.md),

                    // ── Sign in link ──────────────────────────────────────
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have Kise? ',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColorsLight.textHint,
                                fontSize: AppDimensions.fontSizeCaption,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => context.go(AppRoutes.login),
                                child: Text(
                                  'Sign in Here',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontSize: AppDimensions.fontSizeCaption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.xl),

                    // ── Kise logo ─────────────────────────────────────────
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
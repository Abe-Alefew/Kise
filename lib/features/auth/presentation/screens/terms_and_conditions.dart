import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/colors.dart';


class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _loadAgreement();
  }

  Future<void> _loadAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool(AppStorageKeys.termsAccepted) ?? false;
    if (!mounted) return;
    setState(() {
      _agreed = agreed;
    });
  }

  Future<void> _updateAgreement(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStorageKeys.termsAccepted, value);
    if (!mounted) return;
    setState(() {
      _agreed = value;
    });
  }

  // ── Content ───────────────────────────────────────────────────────────────

  static const String _effectiveDate =
      'Effective Date: April 16, 2026\nApplication Name: KISE\nOwner/Operator: KISE Team';

  static const String _intro =
      'Welcome to KISE. These Terms and Conditions govern your use of the '
      'KISE mobile application and related services. By creating an account '
      'or using KISE, you agree to these terms.';

  static const List<_Section> _sections = [
    _Section(
      number: '1',
      title: 'Acceptance of Terms',
      body:
          'By registering for or using KISE, you confirm that:',
      bullets: [
        'You have read and understood these Terms and Conditions.',
        'You agree to comply with them.',
        'You are legally able to enter into this agreement.',
      ],
      footer: 'If you do not agree, please do not use KISE.',
    ),
    _Section(
      number: '2',
      title: 'About KISE',
      body:
          'KISE is a student-focused personal finance and budgeting application '
          'designed to help users:',
      bullets: [
        'Track expenses',
        'Manage budgets',
        'Set savings goals',
        'Improve financial discipline',
        'View spending insights',
      ],
      footer: 'KISE provides informational and management tools only.',
    ),
    _Section(
      number: '3',
      title: 'User Eligibility',
      body: 'You may use KISE if:',
      bullets: [
        'You are at least 13 years old (or local minimum digital consent age).',
        'You provide accurate registration information.',
        'You use the platform lawfully.',
      ],
      footer:
          'If you are under legal age in your jurisdiction, parental/guardian '
          'consent may be required.',
    ),
    _Section(
      number: '4',
      title: 'Account Registration',
      body: 'When creating an account, you agree to:',
      bullets: [
        'Provide accurate and current information.',
        'Keep your login credentials secure.',
        'Notify us of unauthorized account use.',
        'Be responsible for activity under your account.',
      ],
      footer:
          'We may suspend accounts with false or misleading information.',
    ),
    _Section(
      number: '5',
      title: 'User Responsibilities',
      body: 'You agree not to:',
      bullets: [
        'Use KISE for fraud or illegal activity.',
        'Attempt unauthorized access to systems or accounts.',
        'Upload harmful code or malicious content.',
        'Interfere with app performance or security.',
        'Misrepresent financial data to abuse rewards/features.',
      ],
    ),
    _Section(
      number: '6',
      title: 'Financial Disclaimer',
      body:
          'KISE is not a bank, lender, investment advisor, accountant, or '
          'financial institution. KISE does not provide:',
      bullets: [
        'Loans',
        'Investment advice',
        'Tax advice',
        'Guaranteed financial outcomes',
      ],
      footer: 'All financial decisions remain your responsibility.',
    ),
    _Section(
      number: '7',
      title: 'Data Accuracy',
      body:
          'KISE tools depend on information you provide. We are not responsible '
          'for inaccurate reports caused by:',
      bullets: [
        'Incorrect entries',
        'Missing transactions',
        'Outdated information',
        'User error',
      ],
    ),
    _Section(
      number: '8',
      title: 'Privacy',
      body:
          'Your privacy matters. Use of KISE is also governed by our Privacy '
          'Policy, which explains:',
      bullets: [
        'What data we collect',
        'How we use it',
        'How we protect it',
        'Your rights regarding your data',
      ],
    ),
    _Section(
      number: '9',
      title: 'Intellectual Property',
      body: 'All rights in KISE, including:',
      bullets: [
        'Name',
        'Branding',
        'Design',
        'Code',
        'Features',
        'Content',
      ],
      footer:
          'are owned by KISE or its licensors. You may not copy, reverse '
          'engineer, resell, or distribute KISE without permission.',
    ),
    _Section(
      number: '10',
      title: 'Service Availability',
      body:
          'We aim for reliable service but do not guarantee uninterrupted '
          'access. KISE may experience:',
      bullets: [
        'Maintenance downtime',
        'Bugs',
        'Updates',
      ],
      footer: 'We may modify or discontinue features at any time.',
    ),
    _Section(
      number: '11',
      title: 'Account Suspension or Termination',
      body: 'We may suspend or terminate accounts that:',
      bullets: [
        'Violate these terms',
        'Abuse the platform',
        'Engage in fraud',
        'Threaten security or other users',
      ],
      footer: 'You may stop using KISE at any time.',
    ),
    _Section(
      number: '12',
      title: 'Limitation of Liability',
      body:
          'To the maximum extent allowed by law, KISE is not liable for:',
      bullets: [
        'Indirect damages',
        'Loss of data',
        'Financial losses from user decisions',
        'Service interruptions',
        'Device issues outside our control',
      ],
      footer: 'Use the app at your own risk.',
    ),
    _Section(
      number: '13',
      title: 'Updates to Terms',
      body:
          'We may revise these Terms from time to time. Updated versions will '
          'be posted in the app. Continued use after updates means acceptance '
          'of revised terms.',
    ),
    _Section(
      number: '14',
      title: 'Governing Law',
      body:
          'These Terms shall be governed by applicable laws of the jurisdiction '
          'where KISE operates, unless otherwise required by law.',
    ),
    _Section(
      number: '15',
      title: 'Contact',
      body:
          'For support or legal inquiries:\n\nEmail: support-kise@gmail.com\nApp Name: KISE',
    ),
    _Section(
      number: '16',
      title: 'Consent',
      body:
          'By tapping "I Agree" or using KISE, you acknowledge and accept '
          'these Terms and Conditions.',
    ),
  ];

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _buildSection(
    _Section section,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final titleStyle = textTheme.bodyMedium?.copyWith(
      color: AppColorsLight.textBody,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final bodyStyle = textTheme.bodySmall?.copyWith(
      color: AppColorsLight.textHint,
      height: 1.55,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Text(
            '${section.number}. ${section.title}',
            style: titleStyle,
          ),
          const SizedBox(height: AppDimensions.xs),

          // Intro body
          if (section.body != null)
            Text(section.body!, style: bodyStyle),

          // Bullet list
          if (section.bullets != null) ...[
            const SizedBox(height: AppDimensions.xs),
            ...section.bullets!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.sm,
                  bottom: 3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: bodyStyle),
                    Expanded(child: Text(item, style: bodyStyle)),
                  ],
                ),
              ),
            ),
          ],

          // Footer note
          if (section.footer != null) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(section.footer!, style: bodyStyle),
          ],
        ],
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

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
          // ── Gold header ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: scaffoldColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Terms and\nConditions',
                    style: textTheme.displayLarge?.copyWith(
                      color: scaffoldColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White card ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.28,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Meta info ─────────────────────────────────────────
                    Text(
                      _effectiveDate,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColorsLight.textHint,
                        height: 1.6,
                        fontSize: AppDimensions.fontSizeCaption,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // ── Intro paragraph ───────────────────────────────────
                    Text(
                      _intro,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColorsLight.textHint,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // ── Sections ──────────────────────────────────────────
                    ..._sections.map(
                      (s) => _buildSection(s, textTheme, colorScheme),
                    ),

                    const SizedBox(height: AppDimensions.md),

                    // ── Agreement radio ───────────────────────────────────
                    GestureDetector(
                      onTap: () => _updateAgreement(!_agreed),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _agreed ? true : null,
                            onChanged: (val) =>
                                _updateAgreement(val ?? false),
                            activeColor: colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: AppDimensions.xs),
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
                                  TextSpan(
                                    text:
                                        'terms and the conditions of Kise',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontSize: AppDimensions.fontSizeCaption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

// ── Data model ────────────────────────────────────────────────────────────────

class _Section {
  const _Section({
    required this.number,
    required this.title,
    this.body,
    this.bullets,
    this.footer,
  });

  final String number;
  final String title;
  final String? body;
  final List<String>? bullets;
  final String? footer;
}
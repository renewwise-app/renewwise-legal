import 'package:flutter/material.dart';

import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/welcome_auth_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/first_launch_navigation.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

class WelcomeLoginScreen extends StatefulWidget {
  const WelcomeLoginScreen({
    super.key,
    required this.settingsService,
    required this.shellArgs,
  });

  final SettingsService settingsService;
  final FirstLaunchShellArgs shellArgs;

  @override
  State<WelcomeLoginScreen> createState() => _WelcomeLoginScreenState();
}

class _WelcomeLoginScreenState extends State<WelcomeLoginScreen> {
  final _authService = WelcomeAuthService();
  bool _busy = false;

  Future<void> _finishLogin({
    required String email,
    required WelcomeAuthProvider provider,
  }) async {
    setState(() => _busy = true);
    await widget.settingsService.completeWelcomeLogin(
      email: email,
      provider: provider.name,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    FirstLaunchNavigation.replaceWith(
      context,
      widget.shellArgs.buildWelcomeName(),
    );
  }

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result == null) {
        setState(() => _busy = false);
        return;
      }
      await _finishLogin(
        email: result.email,
        provider: result.provider,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppFeedback.info(context, 'Could not sign in with Google. Try email instead.');
      }
    }
  }

  Future<void> _continueWithEmail() async {
    if (_busy) return;
    final emailController = TextEditingController(
      text: widget.settingsService.accountEmail,
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Continue with Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your email to identify your account. No password required.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (!_isValidEmail(email)) {
                AppFeedback.info(ctx, 'Enter a valid email address');
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    final email = emailController.text.trim();
    emailController.dispose();
    if (submitted != true || !mounted) return;
    await _finishLogin(email: email, provider: WelcomeAuthProvider.email);
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeLoginBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Center(child: RenewWiseLogo(size: 72)),
                      const SizedBox(height: AppSpacing.section),
                      Text(
                        'Welcome to RenewWise',
                        style: RenewWiseTypography.screenTitle.copyWith(
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'RenewWise works fully offline. Sign in to identify your account, '
                        'enable optional backup, and support future premium membership.',
                        style: RenewWiseTypography.secondary.copyWith(
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: RenewWisePalette.cardSurface,
                          borderRadius: BorderRadius.circular(AppRadius.homeCard),
                          border: Border.all(
                            color: RenewWisePalette.brandSoftEnd.withAlpha(160),
                          ),
                          boxShadow: RenewWiseShadows.listCard(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PrivacyPoint(
                              icon: Icons.offline_bolt_outlined,
                              text: 'Your reminders stay on this device.',
                            ),
                            const SizedBox(height: 10),
                            _PrivacyPoint(
                              icon: Icons.lock_outline_rounded,
                              text: 'Your data remains private.',
                            ),
                            const SizedBox(height: 10),
                            _PrivacyPoint(
                              icon: Icons.cloud_outlined,
                              text: 'Cloud backup is always optional.',
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _continueWithGoogle,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _continueWithEmail,
                        icon: const Icon(Icons.email_outlined, size: 20),
                        label: const Text('Continue with Email'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ],
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

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: RenewWiseTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: RenewWisePalette.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeLoginBackground extends StatelessWidget {
  const _WelcomeLoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RenewWisePalette.brandSoftStart.withAlpha(220),
            RenewWisePalette.pageBackground,
          ],
        ),
      ),
    );
  }
}

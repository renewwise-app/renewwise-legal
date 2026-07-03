import 'package:flutter/material.dart';

import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/first_launch_navigation.dart';
import 'package:renew_wise/widgets/first_launch/tutorial_offer_dialog.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

class WelcomeNameScreen extends StatefulWidget {
  const WelcomeNameScreen({
    super.key,
    required this.settingsService,
    required this.shellArgs,
  });

  final SettingsService settingsService;
  final FirstLaunchShellArgs shellArgs;

  @override
  State<WelcomeNameScreen> createState() => _WelcomeNameScreenState();
}

class _WelcomeNameScreenState extends State<WelcomeNameScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  bool get _canContinue => _nameController.text.trim().isNotEmpty && !_saving;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _saving = true);
    await widget.settingsService.setUserName(_nameController.text);
    if (!mounted) return;
    setState(() => _saving = false);

    await TutorialOfferDialog.maybeShow(context, widget.settingsService);
    if (!mounted) return;

    FirstLaunchNavigation.replaceWith(
      context,
      widget.shellArgs.buildMainShell(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RenewWisePalette.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeAmbientBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Center(child: RenewWiseLogo(size: 72)),
                      const SizedBox(height: AppSpacing.section),
                      Text(
                        'What should we call you?',
                        style: RenewWiseTypography.screenTitle.copyWith(
                          fontSize: 28,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We\'ll use your preferred name in greetings — like Good Morning, Ujjal.',
                        style: RenewWiseTypography.secondary.copyWith(
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: RenewWisePalette.cardSurface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.homeCard),
                          boxShadow: RenewWiseShadows.listCard(),
                          border: Border.all(
                            color: RenewWisePalette.brandSoftEnd.withAlpha(180),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Name',
                              style: RenewWiseTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: RenewWisePalette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.name],
                              style: RenewWiseTypography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              onSubmitted: (_) {
                                if (_canContinue) _continue();
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                filled: true,
                                fillColor: RenewWisePalette.brandSoftStart
                                    .withAlpha(120),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withAlpha(100),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      FilledButton(
                        onPressed: _canContinue ? _continue : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withAlpha(120),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.homeCard),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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

class _WelcomeAmbientBackground extends StatelessWidget {
  const _WelcomeAmbientBackground();

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
            RenewWisePalette.pageBackground,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
    );
  }
}

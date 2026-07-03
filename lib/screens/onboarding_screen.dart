import 'package:flutter/material.dart';

import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/first_launch_navigation.dart';
import 'package:renew_wise/widgets/onboarding/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settingsService,
    required this.renewalService,
    required this.notificationService,
    required this.reminderStateService,
    required this.assistantDraftService,
    required this.eventExtrasService,
    required this.shellArgs,
    this.developerService,
  });

  final SettingsService settingsService;
  final RenewalService renewalService;
  final NotificationService notificationService;
  final ReminderStateService reminderStateService;
  final AssistantDraftService assistantDraftService;
  final EventExtrasService eventExtrasService;
  final FirstLaunchShellArgs shellArgs;
  final DeveloperService? developerService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      headline: 'Never miss what matters.',
      subtitle:
          'Renewals, deadlines and life moments — organised calmly in one trusted place.',
      illustration: OnboardingOrganisedLifeIllustration(),
      semanticsLabel: 'Organised reminders and calendar illustration',
    ),
    _OnboardingPageData(
      headline: 'Private by design.',
      subtitle: null,
      bullets: [
        'Works offline',
        'Your data stays on your device',
        'Cloud backup is optional',
      ],
      illustration: OnboardingPrivacyIllustration(),
      semanticsLabel: 'Phone protected by shield illustration',
    ),
    _OnboardingPageData(
      headline: 'Plan today. Relax tomorrow.',
      subtitle:
          'Understand your spending, reach your goals, and feel confident about what\'s ahead with Smart Insights.',
      illustration: OnboardingPlanningIllustration(),
      semanticsLabel: 'Planning and insights illustration',
    ),
  ];

  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: AppMotion.duration,
        curve: AppMotion.curve,
      );
    }
  }

  Future<void> _complete() async {
    await widget.settingsService.setHasSeenOnboarding(true);
    if (!mounted) return;
    FirstLaunchNavigation.replaceWith(
      context,
      widget.shellArgs.buildWelcomeLogin(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScale),
      child: Scaffold(
        backgroundColor: RenewWisePalette.pageBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _OnboardingAmbientBackground(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.sm,
                          AppSpacing.page,
                          0,
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            if (!_isLastPage)
                              TextButton(
                                onPressed: _complete,
                                child: Text(
                                  'Skip',
                                  style: RenewWiseTypography.actionLink.copyWith(
                                    color: RenewWisePalette.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pageCount,
                          onPageChanged: (page) =>
                              setState(() => _currentPage = page),
                          itemBuilder: (context, index) {
                            return _OnboardingPageView(
                              isActive: _currentPage == index,
                              data: _pages[index],
                            );
                          },
                        ),
                      ),
                      _OnboardingPageIndicator(
                        count: _pageCount,
                        index: _currentPage,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.md,
                          AppSpacing.page,
                          AppSpacing.lg,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(_isLastPage ? 'Get Started' : 'Next'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.headline,
    required this.illustration,
    required this.semanticsLabel,
    this.subtitle,
    this.bullets,
  });

  final String headline;
  final String? subtitle;
  final List<String>? bullets;
  final Widget illustration;
  final String semanticsLabel;
}

class _OnboardingPageView extends StatefulWidget {
  const _OnboardingPageView({
    required this.isActive,
    required this.data,
  });

  final bool isActive;
  final _OnboardingPageData data;

  @override
  State<_OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<_OnboardingPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.curve));
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _OnboardingPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final illustrationHeight =
        MediaQuery.sizeOf(context).height.clamp(480, 900) * 0.28;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Semantics(
                label: widget.data.semanticsLabel,
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: illustrationHeight,
                    child: Center(child: widget.data.illustration),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.data.headline,
                style: RenewWiseTypography.screenTitle.copyWith(
                  fontSize: 28,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (widget.data.subtitle != null)
                Text(
                  widget.data.subtitle!,
                  style: RenewWiseTypography.secondary.copyWith(
                    fontSize: 16,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.data.bullets != null) ...[
                const SizedBox(height: 8),
                ...widget.data.bullets!.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: RenewWiseTypography.secondary.copyWith(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageIndicator extends StatelessWidget {
  const _OnboardingPageIndicator({
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.duration,
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.primary.withAlpha(50),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _OnboardingAmbientBackground extends StatelessWidget {
  const _OnboardingAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RenewWisePalette.brandSoftStart.withAlpha(230),
            RenewWisePalette.pageBackground,
          ],
        ),
      ),
    );
  }
}

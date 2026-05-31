import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/database/database_service.dart';
import '../../../../shared/widgets/premium_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    const OnboardingSlide(
      icon: Icons.task_alt,
      title: "Master Your Tasks",
      description: "Organize your life with intelligent categories, smart due reminders, slidable tasks, custom priorities, and a dynamic Pomodoro timer.",
      gradientColor: AppColors.primary,
    ),
    const OnboardingSlide(
      icon: Icons.autorenew,
      title: "Form Unstoppable Habits",
      description: "Build robust daily streaks, monitor consistency scores, unlock achievements, and visualize success through GitHub-style maps.",
      gradientColor: AppColors.secondary,
    ),
    const OnboardingSlide(
      icon: Icons.book,
      title: "Reflect and Grow",
      description: "Capture daily journals, track emotional mood trends, record beautiful memories, and lock sensitive logs under biometric local protection.",
      gradientColor: AppColors.success,
    ),
  ];

  void _onNext() async {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppTransitions.medium,
        curve: Curves.easeInOut,
      );
    } else {
      // Save completed state to local settings
      final db = DatabaseService.instance;
      await db.saveSetting('onboarding_completed', true);
      // Wait, also check if biometrics should be suggested.
      // Let's go to dashboard directly (or login fallback if biometrics is turned on later)
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _slides[_currentPage].gradientColor.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Top skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: _currentPage < _slides.length - 1
                        ? TextButton(
                            onPressed: () async {
                              final db = DatabaseService.instance;
                              await db.saveSetting('onboarding_completed', true);
                              if (mounted) context.go('/dashboard');
                            },
                            child: Text(
                              "Skip",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox(height: 48),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Graphic vector visual representation
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slide.gradientColor.withOpacity(0.06),
                                border: Border.all(
                                  color: slide.gradientColor.withOpacity(0.15),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [slide.gradientColor, slide.gradientColor.withAlpha(160)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: slide.gradientColor.withOpacity(0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              slide.title,
                              style: AppTextStyles.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                slide.description,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Progress Dots Indicator & Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress Dots
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: AppTransitions.fast,
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? _slides[_currentPage].gradientColor
                                  : AppColors.textMuted.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                      // Dynamic Slide Button
                      PremiumButton(
                        text: _currentPage == _slides.length - 1 ? "Get Started" : "Continue",
                        onTap: _onNext,
                        width: 160,
                        gradient: LinearGradient(
                          colors: [
                            _slides[_currentPage].gradientColor,
                            _slides[_currentPage].gradientColor.withAlpha(200),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color gradientColor;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColor,
  });
}

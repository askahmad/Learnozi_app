import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      badge: 'BILINGUAL AI STUDY TUTOR',
      title: 'Personalized Study\nCompanion',
      subtitle:
          'Explain complex syllabus topics step-by-step with practical worked exam examples and revision summaries in English and Urdu.',
      icon: Icons.auto_awesome_rounded,
      secondaryIcon: Icons.school_rounded,
      gradientColors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      accentColor: Color(0xFF818CF8),
    ),
    OnboardingSlide(
      badge: 'MACHINE LEARNING DIAGNOSTIC',
      title: 'Adaptive Mock Tests &\nWeak-Topic Engine',
      subtitle:
          'Generate syllabus-aligned quizzes from your notes and let our self-trained ML model detect weak concepts for focused revision.',
      icon: Icons.psychology_rounded,
      secondaryIcon: Icons.track_changes_rounded,
      gradientColors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
      accentColor: Color(0xFF2DD4BF),
    ),
    OnboardingSlide(
      badge: 'ACTIVE RECALL & PRODUCTIVITY',
      title: 'Master Your Exams with\nSmart Study Tools',
      subtitle:
          'SuperMemo SM-2 flashcards, interactive Pomodoro focus timers, and milestone planners designed to build high-yield exam habits.',
      icon: Icons.style_rounded,
      secondaryIcon: Icons.local_fire_department_rounded,
      gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
      accentColor: Color(0xFFFB923C),
    ),
  ];

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Logo Brand + Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Learnozi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Page View Carousel (3 Slides)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Layered Hero Emblem Illustration
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ambient Background Glow Ring
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: slide.gradientColors.first.withValues(alpha: 0.12),
                                ),
                              ),
                              // Core Gradient Circle
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: slide.gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: slide.gradientColors.first.withValues(alpha: 0.35),
                                      blurRadius: 26,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    slide.icon,
                                    size: 58,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Floating Satellite Badge
                              Positioned(
                                bottom: 12,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    slide.secondaryIcon,
                                    size: 18,
                                    color: slide.gradientColors.first,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 38),

                        // Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: slide.gradientColors.first.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: slide.gradientColors.first.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            slide.badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: slide.gradientColors.first,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Slide Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // Animated Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Action Button (Next or Get Started)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // One-Tap Quick Demo Student Link
                  TextButton.icon(
                    onPressed: () {
                      AuthService().loginAsDemoStudent();
                      _finishOnboarding();
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4F46E5)),
                    label: const Text(
                      'Explore directly as Student Demo',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData secondaryIcon;
  final List<Color> gradientColors;
  final Color accentColor;

  const OnboardingSlide({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.secondaryIcon,
    required this.gradientColors,
    required this.accentColor,
  });
}

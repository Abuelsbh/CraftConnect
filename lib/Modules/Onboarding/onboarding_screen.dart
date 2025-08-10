import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.search_rounded,
      titleKey: 'onboarding_title_1',
      descriptionKey: 'onboarding_desc_1',
      color: const Color(0xFF6C63FF),
    ),
    const OnboardingPage(
      icon: Icons.verified_rounded,
      titleKey: 'onboarding_title_2',
      descriptionKey: 'onboarding_desc_2',
      color: const Color(0xFF4CAF50),
    ),
    const OnboardingPage(
      icon: Icons.chat_rounded,
      titleKey: 'onboarding_title_3',
      descriptionKey: 'onboarding_desc_3',
      color: const Color(0xFF2196F3),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isFirstTimeKey, false);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Skip button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.padding),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    AppLocalizations.of(context)?.translate('skip') ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Page view
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return AnimationLimiter(
                  child: _buildOnboardingPage(_pages[index], index),
                );
              },
            ),
          ),

          // Page indicators
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: AppConstants.animationDuration,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentPage == index ? 32.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
          ),

          // Next/Get Started button
          Padding(
            padding: EdgeInsets.all(AppConstants.padding),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _currentPage == _pages.length - 1
                      ? AppLocalizations.of(context)?.translate('get_started') ?? ''
                      : AppLocalizations.of(context)?.translate('next') ?? '',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page, int index) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimationConfiguration.staggeredList(
            position: index,
            delay: const Duration(milliseconds: 100),
            child: Column(
              children: [
              // Icon
              SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      color: page.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      page.icon,
                      size: 100.w,
                      color: page.color,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 60.h),

              // Title
              SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: Text(
                    AppLocalizations.of(context)?.translate(page.titleKey) ?? '',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Description
              SlideAnimation(
                verticalOffset: 20.0,
                child: FadeInAnimation(
                  child: Text(
                    AppLocalizations.of(context)?.translate(page.descriptionKey) ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ])
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final Color color;

  const OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.color,
  });
} 
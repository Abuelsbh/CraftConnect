import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/app_languages.dart';
import '../../core/Language/locales.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Languages? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // تحديد اللغة الحالية من الـ provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = Provider.of<AppLanguage>(context, listen: false);
      setState(() {
        _selectedLanguage = languageProvider.appLang;
      });
    });
  }

  Future<void> _selectLanguage(Languages language) async {
    setState(() {
      _selectedLanguage = language;
    });

    // حفظ اللغة المختارة
    final languageProvider = Provider.of<AppLanguage>(context, listen: false);
    await languageProvider.changeLanguage(language: language);

    // حفظ حالة أن اللغة تم اختيارها
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.languageSelectedKey, true);

    // الانتقال إلى الـ onboarding بعد اختيار اللغة
    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.padding),
            child: AnimationLimiter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  
                  // Icon
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          width: 200.w,
                          height: 200.w,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            size: 100.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // Title
                  AnimationConfiguration.staggeredList(
                    position: 1,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(
                        child: Text(
                          AppLocalizations.of(context)?.translate('select_language') ?? 
                          'Select Language',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Description
                  AnimationConfiguration.staggeredList(
                    position: 2,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: Text(
                          AppLocalizations.of(context)?.translate('choose_your_preferred_language') ?? 
                          'Choose your preferred language to continue',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // Language options
                  AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: Column(
                          children: [
                            // Arabic option
                            _buildLanguageOption(
                              language: Languages.ar,
                              title: 'العربية',
                              flag: '🇰🇼',
                              isSelected: _selectedLanguage == Languages.ar,
                            ),
                            
                            SizedBox(height: 20.h),
                            
                            // English option
                            _buildLanguageOption(
                              language: Languages.en,
                              title: 'English',
                              flag: '🇬🇧',
                              isSelected: _selectedLanguage == Languages.en,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required Languages language,
    required String title,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(language),
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: 32.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}


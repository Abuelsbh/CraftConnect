import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../generated/assets.dart';
import 'splash_data_handler.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = "/";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _navigateAfterDelay();
  }

  void _initAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // Background animation
    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    _logoController.forward();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });
  }

  void _navigateAfterDelay() {
    Future.delayed(AppConstants.splashDuration, () async {
      if (mounted) {
        // التحقق من وجود البيانات وإضافتها إذا لم تكن موجودة
       // await _checkAndAddSampleData();

        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = prefs.getBool(AppConstants.isFirstTimeKey) ?? true;

        if (isFirstTime) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      }
    });
  }

  // دالة للتحقق من وجود البيانات وإضافتها
  Future<void> _checkAndAddSampleData() async {
    try {
      // التحقق من وجود البيانات
      final dataExists = await SplashDataHandler.checkIfDataExists();

      if (!dataExists) {
        print('📊 البيانات غير موجودة، سيتم إضافتها...');

        // إضافة البيانات إلى Firebase
        await SplashDataHandler.addAllSampleDataToFirebase();

        print('✅ تم إضافة البيانات بنجاح!');
      } else {
        print('✅ البيانات موجودة بالفعل');
      }
    } catch (e) {
      print('❌ خطأ في التحقق من البيانات: $e');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  Image.asset(
                    Assets.iconsLogo,
                    width: 200.w,
                    height: 200.w,
                    fit: BoxFit.cover,
                  ),
                  
                  SizedBox(height: 90.h),


                  
                  // Loading indicator
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text('Loading...')
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
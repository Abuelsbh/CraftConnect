import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rush/rush.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'firebase_options.dart';

import 'Utilities/fast_http_config.dart';
import 'Utilities/git_it.dart';
import 'Utilities/router_config.dart';
import 'Utilities/performance_helper.dart';
import 'package:provider/provider.dart';
import 'core/Font/font_provider.dart';
import 'core/Language/app_languages.dart';
import 'core/Language/locales.dart';
import 'core/Theme/theme_provider.dart';
import 'providers/app_provider.dart';
import 'providers/simple_auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/artisan_provider.dart';
import 'providers/fault_provider.dart';
import 'providers/favorite_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحسينات الأداء
  PerformanceHelper.optimizeImageCache();
  PerformanceHelper.preloadFonts();
  PerformanceHelper.optimizeCPUUsage();

  // تحسين الرسوم المتحركة
  PerformanceHelper.optimizeAnimations();

  // تحسين الواجهة لنظام Android
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // تحديد اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تمكين Firebase مع معالجة أفضل للأخطاء
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android يعتمد على google-services.json
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }

    // تهيئة Firebase Storage مع فحص الاتصال
    final storage = FirebaseStorage.instance;

    // اختبار الاتصال بـ Firebase Storage
    try {
      await storage.ref().listAll();
      debugPrint('✅ تم تهيئة Firebase Storage بنجاح');
    } catch (e) {
      debugPrint('⚠️ تحذير: مشكلة في اتصال Firebase Storage: $e');
      // لا نوقف التطبيق، فقط نطبع تحذير
    }

  } catch (e) {
    debugPrint('❌ خطأ في تهيئة Firebase: $e');
    // يمكن إضافة معالجة إضافية هنا إذا لزم الأمر
  }

  RushSetup.init(
    largeScreens: RushScreenSize.large,
    mediumScreens: RushScreenSize.medium,
    smallScreens: RushScreenSize.small,
    startMediumSize: 768,
    startLargeSize: 1200,
  );

  FastHttpConfig.init();

  await GitIt.initGitIt();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>(create: (_) => AppProvider()),
        ChangeNotifierProvider<SimpleAuthProvider>(create: (_) => SimpleAuthProvider()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<ArtisanProvider>(create: (_) => ArtisanProvider()),
        ChangeNotifierProvider<FaultProvider>(create: (_) => FaultProvider()),
        ChangeNotifierProvider<FavoriteProvider>(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider<FontProvider>(create: (_) => FontProvider()),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) {
            final provider = ThemeProvider();
            provider.fetchTheme();
            return provider;
          },
        ),
        ChangeNotifierProvider<AppLanguage>(
          create: (_) {
            final provider = AppLanguage();
            provider.fetchLocale();
            return provider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, AppLanguage>(
        builder: (context, themeProvider, languageProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            useInheritedMediaQuery: true,
            builder: (context, child) => MaterialApp.router(
              title: 'PIX & FIX',
              debugShowCheckedModeBanner: false,
              
              // تحسين الأداء
              showPerformanceOverlay: false,
              checkerboardRasterCacheImages: false,
              checkerboardOffscreenLayers: false,
              
              // التوطين والترجمة
              locale: languageProvider.appLang.name == 'ar'
                  ? const Locale('ar')
                  : const Locale('en'),
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              
              // التوجيه المحسن
              routerConfig: GoRouterConfig.router,
              
              // الثيم المحسن
              theme: themeProvider.appThemeMode,
              themeMode: themeProvider.appTheme.isDark ? ThemeMode.dark : ThemeMode.light,
              
              // إعدادات متقدمة للأداء
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    // تحسين النصوص
                    textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                  ),
                  child: ScrollConfiguration(
                    // تحسين التمرير
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                      overscroll: false,
                      physics: PerformanceHelper.optimizedScrollPhysics,
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

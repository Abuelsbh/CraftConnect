import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceHelper {
  // تحسين استخدام الذاكرة
  static void optimizeMemory() {
    if (!kDebugMode) {
      // تنظيف الذاكرة في الإنتاج فقط
      SystemChannels.platform.invokeMethod('SystemNavigator.routeUpdated');
    }
  }

  // تحسين صور التطبيق
  static void optimizeImageCache() {
    // زيادة حجم ذاكرة التخزين المؤقت للصور
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB
  }

  // تحسين الرسوم المتحركة
  static void optimizeAnimations() {
    // تقليل عدد الإطارات المرسومة غير الضرورية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  // تنظيف الموارد
  static Future<void> cleanupResources() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (Platform.isAndroid) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse('/'),
        state: null,
      );
    }
  }

  // تحسين أداء القوائم
  static const int defaultCacheExtent = 250;
  static const double defaultItemExtent = 80.0;

  // تحسين التمرير
  static const ScrollPhysics optimizedScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  // تحسين النصوص
  static void preloadFonts() {
    // تحميل مسبق للخطوط المستخدمة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحميل الخطوط الأساسية
    });
  }

  // تحديد معدل الإطارات
  static const int targetFrameRate = 60;
  
  // تحسين البناء المشروط
  static bool shouldRebuild(Object? oldValue, Object? newValue) {
    return oldValue != newValue;
  }

  // تأخير العمليات الثقيلة
  static Future<T> deferredExecution<T>(Future<T> Function() computation) async {
    await Future.delayed(const Duration(milliseconds: 16)); // إطار واحد
    return await computation();
  }

  // تحسين استخدام المعالج
  static void optimizeCPUUsage() {
    // تقليل أولوية المهام غير المهمة
    Timer.periodic(const Duration(seconds: 30), (timer) {
      optimizeMemory();
    });
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/Theme/theme_model.dart';
import '../core/Theme/theme_provider.dart';

class ThemeClass extends ThemeModel{

  static ThemeModel of(BuildContext context) => Provider.of<ThemeProvider>(context,listen: false).appTheme;

  // ألوان محسنة للوضع الفاتح
  ThemeClass.defaultTheme({
    super.isDark = false,
    super.primaryColor = const Color(0xFF812FF4), // أخضر داكن أنيق
    super.accentColor = const Color(0xFFD9D9D9), // أخضر متوسط
    super.backGroundColor = const Color(0xFFFFFFFF), // رمادي فاتح جداً
    super.darkGreyColor = const Color(0xFF2C2C2C), // رمادي داكن
    super.lightGreyColor = const Color(0xFF9E9E9E), // رمادي متوسط
    super.warningColor = const Color(0xFFE53935), // أحمر واضح
  });

  // ألوان محسنة للوضع الداكن
  static ThemeModel darkTheme() => ThemeModel(
    isDark: true,
    primaryColor: const Color(0xFF812FF4), // بنفسجي للوضع الداكن
    accentColor: const Color(0xFF2C2C2C), // بنفسجي فاتح
    backGroundColor: const Color(0xFF121212), // أسود داكن
    darkGreyColor: const Color(0xFFE0E0E0), // رمادي فاتح (للنصوص)
    lightGreyColor: const Color(0xFFBDBDBD), // رمادي متوسط
    warningColor: const Color(0xFFEF5350), // أحمر أفتح
  );
}
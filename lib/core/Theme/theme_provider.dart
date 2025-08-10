import 'package:flutter/material.dart';
import 'theme_model.dart';
import '../../Utilities/shared_preferences.dart';
import '../../Utilities/theme_helper.dart';

class ThemeProvider extends ChangeNotifier {

  ThemeModel _appTheme = ThemeModel.defaultTheme;
  ThemeModel get appTheme => _appTheme;

  void fetchTheme(){
    if (SharedPref.getTheme() == null){
      _appTheme = ThemeModel.defaultTheme;
    }
    else{
      _appTheme = SharedPref.getTheme()!;
    }
  }

  ThemeData? get appThemeMode => _appTheme.isDark ? _darkMode : _lightMode;

  // الوضع الداكن المحسن
  ThemeData get _darkMode => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _appTheme.primaryColor,
      secondary: _appTheme.accentColor,
      surface: const Color(0xFF1E1E1E),
      error: _appTheme.warningColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _appTheme.darkGreyColor,
      onError: Colors.white,
      outline: _appTheme.lightGreyColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: _appTheme.darkGreyColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: _appTheme.primaryColor),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF2A2A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _appTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _appTheme.primaryColor,
        side: BorderSide(color: _appTheme.primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: _appTheme.primaryColor,
      unselectedItemColor: _appTheme.lightGreyColor,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    extensions: <ThemeExtension<ThemeModel>>[_appTheme],
  );

  // الوضع الفاتح المحسن
  ThemeData get _lightMode => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _appTheme.primaryColor,
      secondary: _appTheme.accentColor,
      surface: Colors.white,
      error: _appTheme.warningColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _appTheme.darkGreyColor,
      onError: Colors.white,
      outline: _appTheme.lightGreyColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _appTheme.backGroundColor,
      foregroundColor: _appTheme.darkGreyColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: _appTheme.primaryColor),
      titleTextStyle: TextStyle(
        color: _appTheme.darkGreyColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _appTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _appTheme.primaryColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _appTheme.primaryColor,
        side: BorderSide(color: _appTheme.primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _appTheme.primaryColor,
      unselectedItemColor: _appTheme.lightGreyColor,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _appTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _appTheme.primaryColor.withValues(alpha: 0.1),
      selectedColor: _appTheme.primaryColor,
      labelStyle: TextStyle(color: _appTheme.primaryColor),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    extensions: <ThemeExtension<ThemeModel>>[_appTheme],
  );

  Future changeTheme({required ThemeModel theme}) async {
    _appTheme = theme;
    await SharedPref.setTheme(theme: _appTheme);
    notifyListeners();
  }

  // تبديل بين الوضع الفاتح والداكن
  Future toggleDarkMode() async {
    if (_appTheme.isDark) {
      await changeTheme(theme: ThemeClass.defaultTheme());
    } else {
      await changeTheme(theme: ThemeClass.darkTheme());
    }
  }
}

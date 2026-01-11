import 'dart:ui';

class AppConstants {
  // App Info
  static const String appName = 'PIX & FIX';
  static const String appVersion = '1.0.0';

  // Craft Types - يمكن تحميلها من Firebase
  static const List<String> defaultCraftTypes = [
    'carpenter',
    'electrician',
    'plumber',
    'painter',
    'mechanic',
    'hvac',
    'satellite',
    'internet',
    'tiler',
    'locksmith',
  ];

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Spacing
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String artisansCollection = 'artisans';
  static const String craftsCollection = 'crafts';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Shared Preferences Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String languageSelectedKey = 'language_selected';
  static const String currentLanguageKey = 'current_language';
  static const String themeKey = 'theme_mode';
  static const String userLocationKey = 'user_location';

  // Map Constants
  static const double defaultZoom = 14.0;
  static const double markerZoom = 16.0;
  static const int locationUpdateInterval = 5000; // milliseconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
} 
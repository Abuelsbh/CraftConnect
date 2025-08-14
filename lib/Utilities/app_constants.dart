class AppConstants {
  // App Info
  static const String appName = 'CraftConnect';
  static const String appVersion = '1.0.0';

  // Craft Types - يمكن تحميلها من Firebase
  static const List<String> defaultCraftTypes = [
    'carpenter',
    'electrician',
    'plumber',
    'painter',
    'mechanic',
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

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String artisansCollection = 'artisans';
  static const String craftsCollection = 'crafts';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Shared Preferences Keys
  static const String isFirstTimeKey = 'is_first_time';
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
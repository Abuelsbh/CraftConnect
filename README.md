# CraftConnect - Artisan Marketplace

A modern Flutter mobile application designed for both artisans (craftsmen) and users searching for local service providers. The app features a beautiful, smooth UI/UX with animations and supports both Arabic and English languages.

## Features Implemented (Phase 1)

### ✅ Core Features
- **Animated Splash Screen**: Visually impressive splash screen with logo animation and background transitions
- **Onboarding Flow**: Clean onboarding screen that appears only on first app launch
- **Multi-language Support**: Full Arabic and English internationalization
- **Light & Dark Theme**: Modern theming system with user preference support
- **Responsive Design**: Adapts to various screen sizes using Rush and ScreenUtil

### ✅ Home Page Features
- **Modern App Bar**: Logo, app name, search and notification icons
- **Craft Categories Filter**: Horizontal scrollable filter with icons and counts
- **Craft Listings**: Beautiful cards showing craft details and artisan counts
- **Bottom Navigation**: 5-tab navigation (Home, Chat, Maps, Profile, Submit Request)
- **Smooth Animations**: Staggered animations throughout the app

### ✅ Architecture & Code Quality
- **Clean Architecture**: Well-structured codebase with proper separation of concerns
- **Provider Pattern**: State management using Provider
- **Responsive Layout**: Supports various screen sizes
- **Modular Structure**: Organized code in modules and utilities

### ✅ Dependencies Added
- Firebase (Core, Auth, Firestore, Storage)
- Google Maps Flutter
- Geolocator & Geocoding
- Lottie & Flutter Staggered Animations
- Cached Network Image
- UUID and other utilities

## App Structure

### 1. Splash Screen ✅
- Animated logo with elastic scaling and rotation
- Gradient background with fade-in effect
- App name and welcome text with slide animations
- Loading indicator
- Auto-navigation to onboarding or home based on first-time status

### 2. Onboarding Screen ✅
- 3 beautiful pages explaining app purpose
- Smooth page transitions with indicators
- Skip functionality
- Staggered animations for content reveal
- Persists completion state to avoid showing again

### 3. Home Page ✅
- **App Bar**: Logo, app name, search and notifications
- **Category Filter**: Horizontal scrollable craft categories with:
  - Icons for each craft type
  - Category names (localized)
  - Artisan counts
  - Selection highlighting with animations
- **Craft List**: Vertical list showing:
  - Craft icons and names
  - Brief descriptions
  - Number of available artisans
  - Navigation arrows
- **Bottom Navigation**: 5 tabs with animated selection states

### 4. Bottom Navigation ✅
- **Home**: Craft categories and listings
- **Chat**: Placeholder (Phase 2)
- **Maps**: Placeholder (Phase 2) 
- **Profile**: Placeholder (Phase 2)
- **Submit Request**: Placeholder (Phase 2)

## Phase 2 Features (Coming Soon)

### 🔄 Planned Features
- **Craft Details Page**: List artisans by craft, sorted by distance
- **Artisan Profile Page**: Detailed artisan info with gallery
- **Google Maps Integration**: Show artisan locations with markers
- **Firebase Integration**: Authentication and real-time data
- **Chat System**: Real-time messaging between users and artisans
- **User Authentication**: Login/register functionality
- **Artisan Registration**: Allow artisans to create profiles
- **Location Services**: GPS-based distance calculations
- **Search & Filtering**: Advanced search functionality

## Technical Stack

- **Frontend**: Flutter 3.5.3+
- **State Management**: Provider Pattern
- **Routing**: GoRouter
- **Responsive Design**: Rush + ScreenUtil
- **Internationalization**: Built-in Flutter i18n
- **Animations**: Flutter Staggered Animations + Lottie
- **Backend (Phase 2)**: Firebase (Auth, Firestore, Storage)
- **Maps (Phase 2)**: Google Maps Flutter
- **Location (Phase 2)**: Geolocator

## Supported Crafts

The app supports various craft categories:
- 🔨 Carpenter - Wood working and furniture
- ⚡ Electrician - Electrical installations
- 🚰 Plumber - Plumbing and water systems  
- 🎨 Painter - Interior and exterior painting
- 🔧 Mechanic - Vehicle repair and maintenance
- ✂️ Tailor - Custom clothing and alterations
- ⚒️ Blacksmith - Metalworking
- 🔥 Welder - Metal joining services
- 🧱 Mason - Construction and masonry
- 🌱 Gardener - Landscaping and garden care

## Getting Started

### Prerequisites
- Flutter SDK 3.5.3 or higher
- Dart SDK
- Android Studio / VS Code
- iOS development: Xcode (for iOS)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd template_2025-main
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Language Support

The app supports:
- **English** (default)
- **Arabic** (RTL support)

Language files are located in `i18n/` directory.

## Project Structure

```
lib/
├── core/
│   ├── Font/              # Font management
│   ├── Language/          # Internationalization
│   └── Theme/             # Theme management
├── models/                # Data models
│   ├── artisan_model.dart
│   ├── craft_model.dart
│   └── user_model.dart
├── Modules/
│   ├── Splash/            # Splash screen
│   ├── Onboarding/        # Onboarding flow
│   └── Home/              # Home screen with navigation
├── Utilities/             # Helper classes and constants
└── Widgets/               # Reusable widgets
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please contact the development team.

---

**Note**: This is Phase 1 of the CraftConnect app. More features including real-time chat, maps integration, and Firebase backend will be added in Phase 2.
# CraftConnect

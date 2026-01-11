import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Modules/ArtisanProfile/ArtisanProfileScreen.dart';
import '../Modules/ArtisanProfile/edit_artisan_profile_screen.dart';
import '../Modules/Review/add_review_screen.dart';
import '../Modules/Review/reviews_list_screen.dart';
import '../Modules/ArtisanRegistration/artisan_registration_screen.dart';
import '../Modules/Splash/splash_screen.dart';
import '../Modules/Onboarding/onboarding_screen.dart';
import '../Modules/LanguageSelection/language_selection_screen.dart';
import '../Modules/Home/home_screen.dart';
import '../Modules/CraftDetails/craft_details_screen.dart';
import '../Modules/Search/search_screen.dart';
import '../Modules/Auth/login_screen.dart';
import '../Modules/Auth/register_screen.dart';
import '../Modules/Auth/forgot_password_screen.dart';
import '../Modules/Auth/phone_login_screen.dart';
import '../Modules/Chat/chat_page.dart';
import '../Modules/Chat/chat_room_screen.dart';
import '../Modules/FaultReport/fault_report_screen.dart';
import '../Modules/FaultReport/fault_report_details_screen.dart';
import '../Modules/ProblemReport/problem_report_stepper_screen.dart';
import '../Modules/Profile/edit_profile_screen.dart';
import '../Modules/Profile/notifications_settings_screen.dart';
import '../Modules/Profile/security_settings_screen.dart';
import '../Modules/Profile/help_support_screen.dart';
import '../Modules/Profile/about_app_screen.dart';
import '../Modules/Favorites/favorites_screen.dart';
import '../Modules/Admin/admin_crafts_management_screen.dart';

BuildContext? get currentContext_ =>
    GoRouterConfig.router.routerDelegate.navigatorKey.currentContext;

class GoRouterConfig {
  static GoRouter get router => _router;
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SplashScreen(),
          );
        },
      ),
      GoRoute(
        path: '/language-selection',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const LanguageSelectionScreen(),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const OnboardingScreen(),
          );
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/craft-details/:craftId',
        pageBuilder: (_, GoRouterState state) {
          final craftId = state.pathParameters['craftId']!;
          return getCustomTransitionPage(
            state: state,
            child: CraftDetailsScreen(craftId: craftId),
          );
        },
      ),
      GoRoute(
        path: '/artisan-profile/:artisanId',
        pageBuilder: (_, GoRouterState state) {
          final artisanId = state.pathParameters['artisanId']!;
          return getCustomTransitionPage(
            state: state,
            child: ArtisanProfileScreen(artisanId: artisanId),
          );
        },
      ),
      GoRoute(
        path: '/edit-artisan-profile/:artisanId',
        pageBuilder: (_, GoRouterState state) {
          final artisanId = state.pathParameters['artisanId']!;
          return getCustomTransitionPage(
            state: state,
            child: EditArtisanProfileScreen(artisanId: artisanId),
          );
        },
      ),
      GoRoute(
        path: '/add-review/:artisanId',
        pageBuilder: (_, GoRouterState state) {
          final artisanId = state.pathParameters['artisanId']!;
          final artisanName = state.queryParameters['name'] ?? 'الحرفي';
          return getCustomTransitionPage(
            state: state,
            child: AddReviewScreen(
              artisanId: artisanId,
              artisanName: artisanName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/reviews/:artisanId',
        pageBuilder: (_, GoRouterState state) {
          final artisanId = state.pathParameters['artisanId']!;
          final artisanName = state.queryParameters['name'] ?? 'الحرفي';
          return getCustomTransitionPage(
            state: state,
            child: ReviewsListScreen(
              artisanId: artisanId,
              artisanName: artisanName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/register-artisan',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const ArtisanRegistrationScreen(),
          );
        },
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SearchScreen(),
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, GoRouterState state) {
          final isArtisan = state.queryParameters['artisan'] == 'true';
          return getCustomTransitionPage(
            state: state,
            child: RegisterScreen(isArtisanRegistration: isArtisan),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const ForgotPasswordScreen(),
          );
        },
      ),
      GoRoute(
        path: '/phone-login',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const PhoneLoginScreen(),
          );
        },
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const ChatPage(),
          );
        },
      ),
      GoRoute(
        path: '/chat-room',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const ChatRoomScreen(),
          );
        },
      ),
      GoRoute(
        path: '/fault-report',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const FaultReportScreen(),
          );
        },
      ),
      GoRoute(
        path: '/problem-report-stepper',
        pageBuilder: (_, GoRouterState state) {
          final reportId = state.queryParameters['reportId'];
          return getCustomTransitionPage(
            state: state,
            child: ProblemReportStepperScreen(reportId: reportId),
          );
        },
      ),
      GoRoute(
        path: '/fault-report-details/:reportId',
        pageBuilder: (_, GoRouterState state) {
          final reportId = state.pathParameters['reportId']!;
          return getCustomTransitionPage(
            state: state,
            child: FaultReportDetailsScreen(reportId: reportId),
          );
        },
      ),
      // Profile Routes
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const EditProfileScreen(),
          );
        },
      ),
      GoRoute(
        path: '/notifications-settings',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const NotificationsSettingsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/security-settings',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SecuritySettingsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/help-support',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const HelpSupportScreen(),
          );
        },
      ),
      GoRoute(
        path: '/about-app',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const AboutAppScreen(),
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const FavoritesScreen(),
          );
        },
      ),
      GoRoute(
        path: '/admin/crafts',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const AdminCraftsManagementScreen(),
          );
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      return null;
    },
  );

  static CustomTransitionPage getCustomTransitionPage({required GoRouterState state, required Widget child}){
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  }
}

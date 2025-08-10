import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Modules/Splash/splash_screen.dart';
import '../Modules/Onboarding/onboarding_screen.dart';
import '../Modules/Home/home_screen.dart';
import '../Modules/CraftDetails/craft_details_screen.dart';
import '../Modules/ArtisanProfile/artisan_profile_screen.dart';
import '../Modules/Search/search_screen.dart';
import '../Modules/Auth/login_screen.dart';
import '../Modules/Auth/register_screen.dart';
import '../Modules/Auth/forgot_password_screen.dart';
import '../Modules/Auth/phone_login_screen.dart';


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
          return getCustomTransitionPage(
            state: state,
            child: const RegisterScreen(),
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






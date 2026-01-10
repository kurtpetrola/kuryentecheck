import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/report/report_screen.dart';
import '../features/map/map_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../services/auth_service.dart';
import 'scaffold_with_navbar.dart';
import 'onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/report',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.uri.toString() == '/login' ||
          state.uri.toString() == '/register';

      // 1. Onboarding Check
      if (!hasSeenOnboarding) {
        if (state.uri.toString() != '/onboarding') {
          return '/onboarding';
        }
        return null; // Let them stay on onboarding
      }

      // 2. Auth Check
      if (!isLoggedIn && !isLoggingIn) {
        // If not logged in and trying to access a protected route, go to login
        // But only if we are NOT on onboarding (which is handled above)
        if (state.uri.toString() != '/onboarding') {
          return '/login';
        }
      }

      // 3. Login Redirect
      if (isLoggedIn && isLoggingIn) {
        // If logged in but on login/register page, go to home
        return '/report';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report',
                builder: (context, state) => const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _ErrorRedirect(),
  );
});

class _ErrorRedirect extends StatefulWidget {
  const _ErrorRedirect();

  @override
  State<_ErrorRedirect> createState() => _ErrorRedirectState();
}

class _ErrorRedirectState extends State<_ErrorRedirect> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.go('/report');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

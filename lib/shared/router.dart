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
import '../features/auth/forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../features/admin/admin_dashboard_screen.dart';
import 'scaffold_with_navbar.dart';
import 'onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(userRoleProvider);
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
          state.uri.toString() == '/register' ||
          state.uri.toString() == '/forgot-password';

      // 1. Onboarding Check
      if (!hasSeenOnboarding) {
        if (state.uri.toString() != '/onboarding') {
          return '/onboarding';
        }
        return null; // Let them stay on onboarding
      }

      // 2. Auth Check
      if (!isLoggedIn && !isLoggingIn) {
        if (state.uri.toString() != '/onboarding') {
          return '/login';
        }
      }

      // 3. Login/Redirect Logic
      if (isLoggedIn) {
        // Wait for role to load if it's null but user is logged in
        // (StreamProvider might be loading initial value)
        // If snapshot is loading, we might want to wait or show splash, but for simplicity:
        final role = userRole.value;

        if (role == 'admin') {
          if (state.uri.toString() != '/admin') {
            return '/admin';
          }
          return null;
        }

        // If resident
        if (isLoggingIn || state.uri.toString() == '/admin') {
          // Redirect away from login pages OR admin page if not admin
          return '/report';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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

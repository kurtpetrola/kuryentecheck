import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/admin/admin_dashboard_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/map/map_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/report/report_screen.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'scaffold_with_navbar.dart';

/// A ChangeNotifier that listens to auth and role changes to trigger router refresh
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._ref) {
    // Listen to auth state changes
    // ignore: unnecessary_underscores
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
    // Listen to role changes
    // ignore: unnecessary_underscores
    _ref.listen(userRoleProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Provider for the auth notifier - used by GoRouter's refreshListenable
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});

/// Keep navigator key as a constant to prevent router recreation
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Main GoRouter configuration, managing auth state changes and role-based redirects
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final userRole = ref.read(userRoleProvider);

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final currentPath = state.uri.toString();
      final isAuthPage =
          currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password';

      // 1. Onboarding Check
      if (!hasSeenOnboarding) {
        if (currentPath != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      // 2. Auth state still loading - show loading screen
      if (authState.isLoading) {
        if (currentPath != '/auth-loading') {
          return '/auth-loading';
        }
        return null;
      }

      final isLoggedIn = authState.value != null;

      // 3. Not logged in - redirect to login
      if (!isLoggedIn) {
        if (!isAuthPage && currentPath != '/onboarding') {
          return '/login';
        }
        return null;
      }

      // 4. User is logged in but role still loading - show loading screen
      if (userRole.isLoading) {
        if (currentPath != '/auth-loading') {
          return '/auth-loading';
        }
        return null;
      }

      final role = userRole.value;

      // 5. Admin routing
      if (role == 'admin') {
        if (currentPath != '/admin') {
          return '/admin';
        }
        return null;
      }

      // 6. Resident routing - redirect away from auth pages, admin, and loading
      if (isAuthPage ||
          currentPath == '/admin' ||
          currentPath == '/auth-loading') {
        return '/report';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const _AuthLoadingScreen(),
      ),
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

/// Loading screen shown during auth state transitions
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F4C45),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_bolt, size: 80, color: Colors.white),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Fallback route that redirects users to the home screen
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

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'data/services/notification_service.dart';
import 'data/services/sync_service.dart';
import 'firebase_options.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/widgets/notification_listener_wrapper.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Load shared preferences early to provide it synchronously later
  final prefs = await SharedPreferences.getInstance();

  // Global Error Handling for UI errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stacktrace: ${details.stack}');
  };

  // Global Error Handling for unhandled asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    debugPrint('Stacktrace: $stack');
    return true; // Handled
  };

  // Initialize Firebase App
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Push Notifications
  await NotificationService().init();

  // Run the app with Riverpod ProviderScope
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

/// Root widget of the KuryenteCheck application
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize SyncService to listen for connectivity changes
    ref.watch(syncServiceProvider);

    // Watch router provider for named routing
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KuryenteCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C45),
          primary: const Color(0xFF0F4C45),
          surface: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F4C45),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: router,
      // Wrap root with NotificationListener to handle deep linking via notifications
      builder: (context, child) =>
          NotificationListenerWrapper(child: child ?? const SizedBox()),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuryente_check/main.dart';
import 'package:kuryente_check/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts and shows onboarding when not seen', (
    WidgetTester tester,
  ) async {
    // 1. Mock SharedPreferences to simulate fresh install
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': false});

    // 2. Pump the widget with Provider overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mock auth state to be logged out
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          // Mock user role
          userRoleProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MyApp(),
      ),
    );

    // 3. Trigger a frame (for async router/state)
    await tester.pumpAndSettle();

    // 4. Verify Onboarding Screen is shown
    // "Report Issues" is the title of the first onboarding page
    expect(find.text('Report Issues'), findsOneWidget);
    expect(
      find.text('Easily report power outages in your area.'),
      findsOneWidget,
    );

    // Verify "Get Started" or "Next" button is there
    expect(find.text('Next'), findsOneWidget);
  });
}

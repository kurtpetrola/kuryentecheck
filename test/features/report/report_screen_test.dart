import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuryente_check/features/report/report_screen.dart';
import 'package:kuryente_check/services/language_provider.dart';
import 'package:kuryente_check/services/report_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<ReportService>(), MockSpec<SharedPreferences>()])
import 'report_screen_test.mocks.dart';

void main() {
  late MockReportService mockReportService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockReportService = MockReportService();
    mockSharedPreferences = MockSharedPreferences();

    // Default stubs
    when(mockSharedPreferences.getString(any)).thenReturn(null);
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        reportServiceProvider.overrideWithValue(mockReportService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
      ],
      child: const MaterialApp(home: ReportScreen()),
    );
  }

  testWidgets('ReportScreen renders correctly', (tester) async {
    await tester.pumpWidget(createSubject());

    expect(find.text('Report Issue'), findsOneWidget);
    expect(find.text('Barangay'), findsOneWidget);
    expect(find.text('Issue Type'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('Empty submission shows error', (tester) async {
    await tester.pumpWidget(createSubject());

    // Submit without data
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    verifyNever(
      mockReportService.addReport(
        barangay: anyNamed('barangay'),
        issueType: anyNamed('issueType'),
        notes: anyNamed('notes'),
      ),
    );

    expect(find.text('Please fill in all required fields'), findsOneWidget);
  });

  testWidgets('Selecting Barangay and Issue Type enables submission', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());

    // Select Barangay
    final dropdownFinder = find.byKey(const Key('barangay_dropdown'));
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Select 'Alitaya' from the menu
    final itemFinder = find.text('Alitaya').last;
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();

    // Select Issue Type
    await tester.tap(find.byKey(const Key('issue_blackout')));
    await tester.pump();

    // Enter Notes
    await tester.enterText(find.byType(TextField), 'Test notes');
    await tester.pump();

    // Submit
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    verify(
      mockReportService.addReport(
        barangay: 'Alitaya',
        issueType: 'Total Blackout',
        notes: 'Test notes',
      ),
    ).called(1);
  });
}

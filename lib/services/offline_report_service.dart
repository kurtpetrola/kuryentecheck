import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_provider.dart';

final offlineReportServiceProvider = Provider<OfflineReportService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineReportService(prefs);
});

/// Manages local storage of community reports when the user is offline
class OfflineReportService {
  static const String _storageKey = 'offline_reports';
  final SharedPreferences _prefs;

  OfflineReportService(this._prefs);

  /// Saves a new report to the local queue
  Future<void> saveReport(Map<String, dynamic> reportData) async {
    final List<String> reports = _prefs.getStringList(_storageKey) ?? [];
    reports.add(jsonEncode(reportData));
    await _prefs.setStringList(_storageKey, reports);
  }

  /// Retrieves all currently queued offline reports
  List<Map<String, dynamic>> getQueuedReports() {
    final List<String> reports = _prefs.getStringList(_storageKey) ?? [];
    return reports.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> removeReport(int index) async {
    final List<String> reports = _prefs.getStringList(_storageKey) ?? [];
    if (index >= 0 && index < reports.length) {
      reports.removeAt(index);
      await _prefs.setStringList(_storageKey, reports);
    }
  }

  Future<void> clearReports() async {
    await _prefs.remove(_storageKey);
  }
}

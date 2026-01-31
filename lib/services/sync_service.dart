import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_report_service.dart';
import 'report_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  final Ref _ref;
  StreamSubscription? _subscription;

  SyncService(this._ref) {
    _init();
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncReports();
      }
    });
  }

  Future<void> _syncReports() async {
    // Reuse the robust logic from syncNow
    await syncNow();
  }

  Future<void> syncNow() async {
    final offlineService = _ref.read(offlineReportServiceProvider);
    final reportService = _ref.read(reportServiceProvider);

    while (true) {
      final reports = offlineService.getQueuedReports();
      if (reports.isEmpty) break;

      final report = reports.first;
      try {
        await reportService.addReport(
          barangay: report['barangay'],
          issueType: report['issueType'],
          notes: report['notes'],
        );
        // Remove the one we just sent (index 0)
        await offlineService.removeReport(0);
      } catch (e) {
        // Stop syncing if we encounter an error
        break;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

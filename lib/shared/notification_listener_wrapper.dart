import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';

/// Global wrapper widget that listens to report status changes and triggers local notifications
class NotificationListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends ConsumerState<NotificationListenerWrapper> {
  // Store the last known status of reports: { docId: status }
  final Map<String, String> _knownStatus = {};
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    // We only listen if user is logged in
    if (user != null) {
      final userReportsStream = ref
          .watch(reportServiceProvider)
          .getUserReports();

      return StreamBuilder<QuerySnapshot>(
        stream: userReportsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            debugPrint(
              'NotificationListener: Received ${docs.length} report docs',
            );

            // First load: just populate the map
            if (!_isInitialized) {
              debugPrint('NotificationListener: Initializing status map');
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                _knownStatus[doc.id] = data['status'] ?? 'Pending';
              }
              // Defer state update to next frame to avoid build conflicts (though boolean flip is safe here)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isInitialized = true;
                  });
                }
              });
            } else {
              // Subsequent updates: check for changes
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final newStatus = data['status'] as String? ?? 'Pending';
                final docId = doc.id;
                final barangay = data['barangay'] as String? ?? 'Unknown';

                if (_knownStatus.containsKey(docId)) {
                  final oldStatus = _knownStatus[docId];
                  if (oldStatus != newStatus) {
                    debugPrint(
                      'NotificationListener: Status change detected for $docId: $oldStatus -> $newStatus',
                    );
                    // Status changed! Trigger notification
                    _triggerNotification(docId, barangay, newStatus);
                    _knownStatus[docId] = newStatus;
                  }
                } else {
                  // New report added (likely by user just now), just track it
                  debugPrint(
                    'NotificationListener: New report tracked: $docId',
                  );
                  _knownStatus[docId] = newStatus;
                }
              }
            }
          } else if (snapshot.hasError) {
            debugPrint('NotificationListener: Stream error: ${snapshot.error}');
          }
          return widget.child;
        },
      );
    }

    // If not logged in, just return child and reset state
    if (_isInitialized) {
      _isInitialized = false;
      _knownStatus.clear();
    }

    return widget.child;
  }

  /// Builds and displays the local notification based on status change
  void _triggerNotification(String id, String barangay, String newStatus) {
    String title = 'Report Update';
    String body = 'Your report in $barangay is now $newStatus';

    if (newStatus == 'Acknowledged') {
      title = 'Report Acknowledged';
      body = 'CENPELCO has acknowledged your outage report in $barangay.';
    } else if (newStatus == 'Resolved') {
      title = 'Power Restored';
      body = 'The outage in $barangay has been resolved.';
    }

    // Use hashcode of ID for notification ID (needs int)
    NotificationService().showNotification(
      id: id.hashCode,
      title: title,
      body: body,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(FirebaseFirestore.instance, ref);
});

final reportStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return ref.watch(reportServiceProvider).getReports();
});

class ReportService {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  ReportService(this._firestore, this._ref);

  // Collection reference
  CollectionReference get _reports => _firestore.collection('reports');

  // Submit a new report
  Future<void> addReport({
    required String barangay,
    required String issueType,
    String? notes,
  }) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) throw Exception('User must be logged in to report');

    await _reports.add({
      'userId': user.uid,
      'displayName': user.displayName ?? 'Anonymous',
      'barangay': barangay,
      'issueType': issueType,
      'notes': notes,
      'status': 'Pending', // Pending, Acknowledged, Resolved
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
    });

    // Increment user's report count
    await _firestore.collection('users').doc(user.uid).update({
      'reportsSubmitted': FieldValue.increment(1),
    });
  }

  // Get stream of reports ordered by newest first
  Stream<QuerySnapshot> getReports() {
    return _reports.orderBy('timestamp', descending: true).snapshots();
  }
}

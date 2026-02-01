import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../shared/exceptions/app_exception.dart';

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
    try {
      final user = _ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw AuthException('User must be logged in to report');
      }

      await _reports.add({
        'userId': user.uid,
        'displayName': user.displayName ?? 'Anonymous',
        'barangay': barangay,
        'issueType': issueType,
        'notes': notes,
        'status': 'Pending', // Pending, Acknowledged, Resolved
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'likedBy': [],
      });

      // Increment user's report count
      await _firestore.collection('users').doc(user.uid).update({
        'reportsSubmitted': FieldValue.increment(1),
      });
    } catch (e) {
      if (e is AppException) rethrow; // Pass up our own exceptions
      throw ServerException('Failed to submit report', originalError: e);
    }
  }

  // Toggle upvote on a report
  Future<void> toggleUpvote(String reportId) async {
    try {
      final user = _ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final reportRef = _reports.doc(reportId);
      final reportDoc = await reportRef.get();

      if (!reportDoc.exists) {
        throw ValidationException('Report not found');
      }

      final data = reportDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(user.uid)) {
        // Remove upvote
        await reportRef.update({
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'upvotes': FieldValue.increment(-1),
        });
      } else {
        // Add upvote
        await reportRef.update({
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'upvotes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to toggle upvote', originalError: e);
    }
  }

  // Get stream of reports ordered by newest first
  Stream<QuerySnapshot> getReports() {
    return _reports.orderBy('timestamp', descending: true).snapshots();
  }

  // Get stream of user specific reports for notifications
  Stream<QuerySnapshot> getUserReports() {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return const Stream.empty();

    return _reports.where('userId', isEqualTo: user.uid).snapshots();
  }
}

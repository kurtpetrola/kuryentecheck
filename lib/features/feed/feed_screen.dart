import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/report_service.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportStreamProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(LucideIcons.fileText, size: 24),
            SizedBox(width: 8),
            Text(
              'Community Feed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by barangay or issue...',
                      prefixIcon: const Icon(LucideIcons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.filter,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (snapshot) {
                if (snapshot.docs.isEmpty) {
                  return const Center(child: Text('No reports yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Basic time ago logic
                    final timestamp = data['timestamp'] as Timestamp?;
                    String timeAgoStr = 'Just now';
                    if (timestamp != null) {
                      final diff = DateTime.now().difference(
                        timestamp.toDate(),
                      );
                      if (diff.inMinutes < 60) {
                        timeAgoStr = '${diff.inMinutes}m ago';
                      } else if (diff.inHours < 24) {
                        timeAgoStr = '${diff.inHours}h ago';
                      } else {
                        timeAgoStr = '${diff.inDays}d ago';
                      }
                    }

                    // Map issue type to icon and color
                    IconData icon = LucideIcons.alertCircle;
                    Color color = Colors.grey;

                    final issueType = data['issueType'] as String? ?? 'Unknown';

                    if (issueType == 'Total Blackout') {
                      icon = LucideIcons.zapOff;
                      color = Colors.red;
                    } else if (issueType == 'Low Voltage') {
                      icon = LucideIcons.activity;
                      color = Colors.orange;
                    } else if (issueType == 'Flickering Lights') {
                      icon = LucideIcons.zap;
                      color = Colors.amber;
                    }

                    final likedBy = List<String>.from(data['likedBy'] ?? []);
                    final isLiked =
                        currentUser != null &&
                        likedBy.contains(currentUser.uid);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _FeedCard(
                        barangay: data['barangay'] ?? 'Unknown',
                        timeAgo: timeAgoStr,
                        issueTitle: issueType,
                        issueIcon: icon,
                        issueColor: color,
                        description:
                            data['notes'] ?? 'No description provided.',
                        status: data['status'] ?? 'Pending',
                        statusColor: (data['status'] == 'Resolved')
                            ? Colors.green
                            : ((data['status'] == 'Acknowledged')
                                  ? Colors.blue
                                  : Colors.orange),
                        upvotes: data['upvotes'] ?? 0,
                        isLiked: isLiked,
                        onUpvote: () {
                          ref.read(reportServiceProvider).toggleUpvote(doc.id);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String barangay;
  final String timeAgo;
  final String issueTitle;
  final IconData issueIcon;
  final Color issueColor;
  final String description;
  final String status;
  final Color statusColor;
  final int upvotes;
  final bool isLiked;
  final VoidCallback onUpvote;

  const _FeedCard({
    required this.barangay,
    required this.timeAgo,
    required this.issueTitle,
    required this.issueIcon,
    required this.issueColor,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.upvotes,
    required this.isLiked,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  barangay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(issueIcon, size: 20, color: issueColor),
              const SizedBox(width: 8),
              Text(
                issueTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onUpvote,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.thumbsUp,
                      size: 20,
                      color: isLiked ? const Color(0xFF0F4C45) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      upvotes.toString(),
                      style: TextStyle(
                        color: isLiked ? const Color(0xFF0F4C45) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

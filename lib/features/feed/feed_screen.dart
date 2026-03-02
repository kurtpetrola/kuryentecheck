import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/language_provider.dart';
import '../../services/report_service.dart';
import '../../shared/app_strings.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  // Controller for the search input field
  final TextEditingController _searchController = TextEditingController();

  // Current search and filter criteria
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportStreamProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final locale = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.fileText, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('community_feed_title', locale),
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.tr('feed_search_hint', locale),
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
                PopupMenuButton<String>(
                  initialValue: _filterStatus,
                  onSelected: (String value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'All',
                          child: Text('All Status'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Acknowledged',
                          child: Text('Acknowledged'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _filterStatus == 'All'
                            ? Colors.grey.shade300
                            : const Color(0xFF0F4C45),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _filterStatus == 'All'
                          ? Colors.transparent
                          : const Color(0xFF0F4C45).withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      LucideIcons.filter,
                      size: 20,
                      color: _filterStatus == 'All'
                          ? Colors.black54
                          : const Color(0xFF0F4C45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (snapshot) {
                final docs = snapshot.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Apply selected status filter
                  if (_filterStatus != 'All') {
                    final status = data['status'] as String? ?? 'Pending';
                    if (status != _filterStatus) return false;
                  }

                  // Apply search keywords against barangay, issue type, and notes
                  if (_searchQuery.isEmpty) return true;
                  final barangay = (data['barangay'] as String? ?? '')
                      .toLowerCase();
                  final issueType = (data['issueType'] as String? ?? '')
                      .toLowerCase();
                  final notes = (data['notes'] as String? ?? '').toLowerCase();

                  return barangay.contains(_searchQuery) ||
                      issueType.contains(_searchQuery) ||
                      notes.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(AppStrings.tr('feed_no_reports', locale)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Calculate human-readable 'time ago' string
                    final timestamp = data['timestamp'] as Timestamp?;
                    String timeAgoStr = AppStrings.tr('time_just_now', locale);
                    if (timestamp != null) {
                      final diff = DateTime.now().difference(
                        timestamp.toDate(),
                      );
                      if (diff.inMinutes < 60) {
                        timeAgoStr =
                            '${diff.inMinutes}${AppStrings.tr('time_m_ago', locale)}';
                      } else if (diff.inHours < 24) {
                        timeAgoStr =
                            '${diff.inHours}${AppStrings.tr('time_h_ago', locale)}';
                      } else {
                        timeAgoStr =
                            '${diff.inDays}${AppStrings.tr('time_d_ago', locale)}';
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

                    String status = data['status'] ?? 'Pending';
                    if (status == 'Pending') {
                      status = AppStrings.tr('status_pending', locale);
                    } else if (status == 'Acknowledged') {
                      status = AppStrings.tr('status_acknowledged', locale);
                    } else if (status == 'Resolved') {
                      status = AppStrings.tr('status_resolved', locale);
                    }

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
                        status: status,
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

/// Reusable card widget for displaying individual feed items
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
  // Indicates if the current user has already liked this report
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

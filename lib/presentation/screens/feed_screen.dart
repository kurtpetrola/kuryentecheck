import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/report_service.dart';
import '../../data/services/sync_service.dart';
import '../providers/language_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/feed_card.dart';

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

    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final isOffline =
        connectivityAsync.value?.contains(ConnectivityResult.none) ?? false;

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
                        borderSide: const BorderSide(color: AppColors.grey300),
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
                        PopupMenuItem<String>(
                          value: 'All',
                          child: Text(AppStrings.tr('feed_all_status', locale)),
                        ),
                        PopupMenuItem<String>(
                          value: 'Pending',
                          child: Text(AppStrings.tr('status_pending', locale)),
                        ),
                        PopupMenuItem<String>(
                          value: 'Acknowledged',
                          child: Text(
                            AppStrings.tr('status_acknowledged', locale),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'Resolved',
                          child: Text(AppStrings.tr('status_resolved', locale)),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _filterStatus == 'All'
                            ? AppColors.grey300
                            : AppColors.primary,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _filterStatus == 'All'
                          ? AppColors.transparent
                          : AppColors.primaryLight,
                    ),
                    child: Icon(
                      LucideIcons.filter,
                      size: 20,
                      color: _filterStatus == 'All'
                          ? AppColors.black54
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isOffline
                ? ErrorView(message: AppStrings.tr('error_offline', locale))
                : reportsAsync.when(
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
                        final notes = (data['notes'] as String? ?? '')
                            .toLowerCase();

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
                          String timeAgoStr = AppStrings.tr(
                            'time_just_now',
                            locale,
                          );
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
                          Color color = AppColors.grey;

                          final issueType =
                              data['issueType'] as String? ?? 'Unknown';

                          if (issueType == 'Total Blackout') {
                            icon = LucideIcons.zapOff;
                            color = AppColors.error;
                          } else if (issueType == 'Low Voltage') {
                            icon = LucideIcons.activity;
                            color = AppColors.warning;
                          } else if (issueType == 'Flickering Lights') {
                            icon = LucideIcons.zap;
                            color = AppColors.amber;
                          }

                          final likedBy = List<String>.from(
                            data['likedBy'] ?? [],
                          );
                          final isLiked =
                              currentUser != null &&
                              likedBy.contains(currentUser.uid);

                          String status = data['status'] ?? 'Pending';
                          if (status == 'Pending') {
                            status = AppStrings.tr('status_pending', locale);
                          } else if (status == 'Acknowledged') {
                            status = AppStrings.tr(
                              'status_acknowledged',
                              locale,
                            );
                          } else if (status == 'Resolved') {
                            status = AppStrings.tr('status_resolved', locale);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FeedCard(
                              barangay: data['barangay'] ?? 'Unknown',
                              timeAgo: timeAgoStr,
                              issueTitle: issueType,
                              issueIcon: icon,
                              issueColor: color,
                              description:
                                  data['notes'] ?? 'No description provided.',
                              status: status,
                              statusColor: (data['status'] == 'Resolved')
                                  ? AppColors.success
                                  : ((data['status'] == 'Acknowledged')
                                        ? AppColors.info
                                        : AppColors.warning),
                              upvotes: data['upvotes'] ?? 0,
                              isLiked: isLiked,
                              onUpvote: () {
                                ref
                                    .read(reportServiceProvider)
                                    .toggleUpvote(doc.id);
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => ErrorView(
                      message: '${AppStrings.tr('error_prefix', locale)} $err',
                      onRetry: () => ref.invalidate(reportStreamProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

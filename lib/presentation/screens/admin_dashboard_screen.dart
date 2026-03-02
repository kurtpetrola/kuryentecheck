import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/report_service.dart';
import '../providers/language_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Current active filter for report status
  String _filterStatus = 'Pending';

  @override
  Widget build(BuildContext context) {
    // Stream of all reports from Firestore
    final reportsAsync = ref.watch(reportStreamProvider);
    // Current application locale for localization
    final locale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text(
          'Command Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    AppStrings.tr('sign_out', locale),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Text(AppStrings.tr('sign_out_confirmation', locale)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.tr('cancel', locale),
                        style: const TextStyle(color: AppColors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authServiceProvider).signOut();
                      },
                      child: Text(
                        AppStrings.tr('sign_out', locale),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (snapshot) {
          final allDocs = snapshot.docs;

          // Calculate counts for each status to display in statistic cards
          final pendingCount = allDocs
              .where((d) => (d.data() as Map)['status'] == 'Pending')
              .length;
          final ackCount = allDocs
              .where((d) => (d.data() as Map)['status'] == 'Acknowledged')
              .length;
          final resolvedCount = allDocs
              .where((d) => (d.data() as Map)['status'] == 'Resolved')
              .length;

          // Filter documents based on currently selected tab
          final displayedDocs = allDocs.where((doc) {
            if (_filterStatus == 'All') return true;
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'Pending') == _filterStatus;
          }).toList();

          return Column(
            children: [
              // Stats Header
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            count: pendingCount,
                            color: AppColors.warning,
                            icon: LucideIcons.alertCircle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Active',
                            count: ackCount,
                            color: AppColors.info,
                            icon: LucideIcons.hammer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Fixed',
                            count: resolvedCount,
                            color: AppColors.success,
                            icon: LucideIcons.checkCircle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Filter Tabs
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterTab(
                            label: 'Pending Issues',
                            isSelected: _filterStatus == 'Pending',
                            onTap: () =>
                                setState(() => _filterStatus = 'Pending'),
                          ),
                          _FilterTab(
                            label: 'Acknowledged',
                            isSelected: _filterStatus == 'Acknowledged',
                            onTap: () =>
                                setState(() => _filterStatus = 'Acknowledged'),
                          ),
                          _FilterTab(
                            label: 'Resolved',
                            isSelected: _filterStatus == 'Resolved',
                            onTap: () =>
                                setState(() => _filterStatus = 'Resolved'),
                          ),
                          _FilterTab(
                            label: 'All Reports',
                            isSelected: _filterStatus == 'All',
                            onTap: () => setState(() => _filterStatus = 'All'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Report List
              Expanded(
                child: displayedDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.clipboardList,
                              size: 48,
                              color: AppColors.grey300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No $_filterStatus reports',
                              style: const TextStyle(color: AppColors.grey500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedDocs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = displayedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _AdminReportCard(
                            key: ValueKey(doc.id),
                            docId: doc.id,
                            data: data,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// A reusable card to display dashboard statistics
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable tab segment used for filtering items
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.transparent : AppColors.grey300,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Display card for an individual user report
class _AdminReportCard extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _AdminReportCard({required this.docId, required this.data, super.key});

  // Helper method to modify report status directly in Firestore
  Future<void> _updateStatus(WidgetRef ref, String newStatus) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = data['status'] ?? 'Pending';
    final issueType = data['issueType'] ?? 'Unknown';
    final barangay = data['barangay'] ?? 'Unknown';
    final description = data['notes'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    Color statusColor = AppColors.warning;
    if (status == 'Acknowledged') statusColor = AppColors.info;
    if (status == 'Resolved') statusColor = AppColors.success;

    IconData issueIcon = LucideIcons.alertCircle;
    if (issueType == 'Total Blackout') issueIcon = LucideIcons.zapOff;
    if (issueType == 'Low Voltage') issueIcon = LucideIcons.activity;
    if (issueType == 'Flickering Lights') issueIcon = LucideIcons.zap;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(issueIcon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            barangay,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              DateFormat('MMM d, h:mm a').format(timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issueType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: statusColor.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    if (status == 'Pending')
                      SizedBox(
                        height: 32,
                        child: TextButton.icon(
                          onPressed: () => _updateStatus(ref, 'Acknowledged'),
                          icon: const Icon(LucideIcons.hardHat, size: 14),
                          label: const Text(
                            'Dispatch',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.info,
                          ),
                        ),
                      ),

                    if (status != 'Resolved') ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(ref, 'Resolved'),
                          icon: const Icon(LucideIcons.check, size: 14),
                          label: const Text(
                            'Resolve',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

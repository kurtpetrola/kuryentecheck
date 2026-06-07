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
import '../widgets/admin_report_card.dart';
import '../widgets/error_view.dart';
import '../widgets/filter_tab.dart';
import '../widgets/stat_card.dart';

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

    // Watch connectivity
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final isOffline = connectivityAsync.value?.contains(ConnectivityResult.none) ?? false;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(
          AppStrings.tr('admin_title', locale),
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      body: isOffline 
        ? ErrorView(
            message: AppStrings.tr('error_offline', locale),
          )
        : reportsAsync.when(
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
                          child: StatCard(
                            label: AppStrings.tr('status_pending', locale),
                            count: pendingCount,
                            color: AppColors.warning,
                            icon: LucideIcons.alertCircle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            label: AppStrings.tr('admin_active', locale),
                            count: ackCount,
                            color: AppColors.info,
                            icon: LucideIcons.hammer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            label: AppStrings.tr('admin_fixed', locale),
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
                          FilterTab(
                            label: AppStrings.tr('admin_pending_issues', locale),
                            isSelected: _filterStatus == 'Pending',
                            onTap: () =>
                                setState(() => _filterStatus = 'Pending'),
                          ),
                          FilterTab(
                            label: AppStrings.tr('status_acknowledged', locale),
                            isSelected: _filterStatus == 'Acknowledged',
                            onTap: () =>
                                setState(() => _filterStatus = 'Acknowledged'),
                          ),
                          FilterTab(
                            label: AppStrings.tr('status_resolved', locale),
                            isSelected: _filterStatus == 'Resolved',
                            onTap: () =>
                                setState(() => _filterStatus = 'Resolved'),
                          ),
                          FilterTab(
                            label: AppStrings.tr('admin_all_reports', locale),
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
                              '${AppStrings.tr('admin_no_reports', locale)} $_filterStatus',
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
                          return AdminReportCard(
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
        error: (e, s) => ErrorView(
          message: '${AppStrings.tr('error_prefix', locale)} $e',
          onRetry: () => ref.invalidate(reportStreamProvider),
        ),
      ),
    );
  }
}

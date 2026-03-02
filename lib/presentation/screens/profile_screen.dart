import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/auth_service.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final locale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.user, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('profile_title', locale),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;

                // Safely determine display name or fallback
                final displayName =
                    data?['displayName'] ?? user.displayName ?? 'No Name';
                // Extract 1-2 letter initials for the avatar placeholder
                final initials = displayName.isNotEmpty
                    ? displayName
                          .trim()
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase()
                    : 'NN';
                final barangay = data?['barangay'] ?? 'Not set';
                final phone = data?['phoneNumber'] ?? 'Not set';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Account Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr('account_information', locale),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _InfoRow(
                              icon: LucideIcons.mapPin,
                              label: AppStrings.tr('barangay_label', locale),
                              value: barangay,
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: LucideIcons.phone,
                              label: AppStrings.tr('mobile_label', locale),
                              value: phone,
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              icon: LucideIcons.fileText,
                              label: AppStrings.tr(
                                'reports_submitted_label',
                                locale,
                              ),
                              value: (data?['reportsSubmitted'] ?? 0)
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                      // ... (Language section omitted for brevity, keeping as is or regenerating if needed)
                      const SizedBox(height: 24),
                      // Language/Wika
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr('language_label', locale),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.grey300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(languageProvider.notifier)
                                            .setLocale(const Locale('en'));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: locale.languageCode == 'en'
                                              ? AppColors.primary
                                              : AppColors.transparent,
                                          // Highlight matching language option visually with border radius
                                          borderRadius: BorderRadius.horizontal(
                                            left: const Radius.circular(7),
                                            right: locale.languageCode == 'en'
                                                ? const Radius.circular(0)
                                                : Radius.zero,
                                          ),
                                        ),
                                        child: Text(
                                          'English',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: locale.languageCode == 'en'
                                                ? AppColors.white
                                                : AppColors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(languageProvider.notifier)
                                            .setLocale(const Locale('tl'));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: locale.languageCode == 'tl'
                                              ? AppColors.primary
                                              : AppColors.transparent,
                                          borderRadius: BorderRadius.horizontal(
                                            right: const Radius.circular(7),
                                            left: locale.languageCode == 'tl'
                                                ? const Radius.circular(0)
                                                : Radius.zero,
                                          ),
                                        ),
                                        child: Text(
                                          'Filipino',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: locale.languageCode == 'tl'
                                                ? AppColors.white
                                                : AppColors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Reusable widget to display a labeled icon-value pair in profile section
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey600),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey600, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

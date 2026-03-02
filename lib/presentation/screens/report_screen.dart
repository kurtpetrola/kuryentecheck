import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../providers/language_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/info_chip.dart';
import '../widgets/issue_type_card.dart';

/// Screen for users to submit new community reports (outages, hazards, etc.)
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Initialize with current state notes if any
    final currentNotes = ref.read(reportFormControllerProvider).notes;
    _notesController = TextEditingController(text: currentNotes);

    // Listen to changes to update state
    _notesController.addListener(() {
      ref
          .read(reportFormControllerProvider.notifier)
          .setNotes(_notesController.text);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Handles report submission and displays appropriate success/error snackbars
  Future<void> _submitReport() async {
    final locale = ref.read(languageProvider);
    final controller = ref.read(reportFormControllerProvider.notifier);

    final result = await controller.submitReport();

    if (!mounted) return;

    if (result == 'sent') {
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('report_snackbar_success', locale)),
          backgroundColor: const Color(0xFF0F4C45),
        ),
      );
    } else if (result == 'queued') {
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report queued (offline). Will send when online.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      final error = ref.read(reportFormControllerProvider).error;
      String errorMessage = error ?? 'Unknown error';

      if (error == 'missing_fields') {
        errorMessage = AppStrings.tr('report_snackbar_missing_fields', locale);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final formState = ref.watch(reportFormControllerProvider);
    final controller = ref.read(reportFormControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.zap, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr('report_issue_title', locale),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.tr('report_form_barangay', locale),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('barangay_dropdown'),
              initialValue: formState.selectedBarangay,
              decoration: InputDecoration(
                hintText: AppStrings.tr('report_form_barangay_hint', locale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              items: Constants.barangays
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: controller.setBarangay,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.tr('report_form_issue_type', locale),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Visual cards for selecting the type of power issue
            IssueTypeCard(
              key: const Key('issue_blackout'),
              title: AppStrings.tr('report_issue_blackout', locale),
              subtitle: AppStrings.tr('report_issue_blackout_desc', locale),
              icon: LucideIcons.zapOff,
              isSelected: formState.selectedIssue == 'Total Blackout',
              onTap: () => controller.setIssue('Total Blackout'),
            ),
            const SizedBox(height: 12),
            IssueTypeCard(
              title: AppStrings.tr('report_issue_low_voltage', locale),
              subtitle: AppStrings.tr('report_issue_low_voltage_desc', locale),
              icon: LucideIcons.activity,
              isSelected: formState.selectedIssue == 'Low Voltage',
              onTap: () => controller.setIssue('Low Voltage'),
            ),
            const SizedBox(height: 12),
            IssueTypeCard(
              title: AppStrings.tr('report_issue_flickering', locale),
              subtitle: AppStrings.tr('report_issue_flickering_desc', locale),
              icon: LucideIcons.zap,
              isSelected: formState.selectedIssue == 'Flickering Lights',
              onTap: () => controller.setIssue('Flickering Lights'),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.tr('report_form_notes', locale),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppStrings.tr('report_form_notes_hint', locale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.tr('report_form_autofilled', locale),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InfoChip(
                  icon: LucideIcons.clock,
                  label: DateFormat.jm().format(DateTime.now()),
                ),
                const SizedBox(width: 8),
                InfoChip(
                  icon: LucideIcons.mapPin,
                  label: formState.selectedBarangay != null
                      ? 'Barangay ${formState.selectedBarangay}'
                      : AppStrings.tr('report_location_not_set', locale),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                key: const Key('submit_button'),
                onPressed: formState.isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: formState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(AppStrings.tr('submit_report_button', locale)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

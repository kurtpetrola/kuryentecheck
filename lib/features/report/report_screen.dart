import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/report_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _selectedBarangay;
  String? _selectedIssue;
  final _notesController = TextEditingController();

  final List<String> _barangays = [
    'Alitaya',
    'Amansabina',
    'Anolid',
    'Banaoang',
    'Bantayan',
    'Bari',
    'Bateng',
    'Buenlag',
    'David',
    'Embarcadero',
    'Gueguesangen',
    'Guesang',
    'Guiguilonen',
    'Guilig',
    'Inlambo',
    'Lanas',
    'Landas',
    'Maasin',
    'Macayug',
    'Malabago',
    'Merano',
    'Navaluan',
    'Nibaliw',
    'Osiem',
    'Palua',
    'Poblacion',
    'Pogo',
    'Salaan',
    'Salapingao',
    'Talogtog',
    'Tebag',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedBarangay == null || _selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      await ref
          .read(reportServiceProvider)
          .addReport(
            barangay: _selectedBarangay!,
            issueType: _selectedIssue!,
            notes: _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Color(0xFF0F4C45),
          ),
        );
        // Reset form
        setState(() {
          _selectedBarangay = null;
          _selectedIssue = null;
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(LucideIcons.zap, size: 24),
            SizedBox(width: 8),
            Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Barangay',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedBarangay,
              decoration: InputDecoration(
                hintText: 'Select your barangay',
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
              items: _barangays
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBarangay = val),
            ),
            const SizedBox(height: 24),
            const Text(
              'Issue Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _IssueTypeCard(
              title: 'Total Blackout',
              subtitle: 'Complete power outage',
              icon: LucideIcons.zapOff,
              isSelected: _selectedIssue == 'Total Blackout',
              onTap: () => setState(() => _selectedIssue = 'Total Blackout'),
            ),
            const SizedBox(height: 12),
            _IssueTypeCard(
              title: 'Low Voltage',
              subtitle: 'Dim lights, weak appliances',
              icon: LucideIcons.activity,
              isSelected: _selectedIssue == 'Low Voltage',
              onTap: () => setState(() => _selectedIssue = 'Low Voltage'),
            ),
            const SizedBox(height: 12),
            _IssueTypeCard(
              title: 'Flickering Lights',
              subtitle: 'Unstable power supply',
              icon: LucideIcons.zap,
              isSelected: _selectedIssue == 'Flickering Lights',
              onTap: () => setState(() => _selectedIssue = 'Flickering Lights'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue in more detail...',
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
            const Text(
              'Auto-filled Information',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: LucideIcons.clock,
                  label: DateFormat.jm().format(DateTime.now()),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: LucideIcons.mapPin,
                  label: _selectedBarangay != null
                      ? 'Barangay $_selectedBarangay'
                      : 'Location not set',
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C45),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IssueTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F4C45) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

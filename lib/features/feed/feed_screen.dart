import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _FeedCard(
                  barangay: 'Poblacion',
                  timeAgo: '15 minutes ago',
                  issueTitle: 'Total Blackout',
                  issueIcon: LucideIcons.zapOff,
                  issueColor: Colors
                      .blue, // Screenshot shows dark blue/black for total blackout
                  description:
                      'Power out since 2pm. Whole street affected. Multiple households reporting the same issue.',
                  status: 'Pending',
                  statusColor: Colors.orange,
                  upvotes: 8,
                ),
                SizedBox(height: 16),
                _FeedCard(
                  barangay: 'Macayug',
                  timeAgo: 'about 2 hours ago',
                  issueTitle: 'Low Voltage',
                  issueIcon: LucideIcons.activity,
                  issueColor: Colors.blue,
                  description:
                      'Lights are very dim, appliances not working properly. Refrigerator stopped working.',
                  status: 'Acknowledged',
                  statusColor: Colors.blue,
                  upvotes: 3,
                ),
                SizedBox(height: 16),
                _FeedCard(
                  barangay: 'Bantayan',
                  timeAgo: 'about 5 hours ago',
                  issueTitle: 'Flickering Lights',
                  issueIcon: LucideIcons.zap,
                  issueColor: Colors.blue,
                  description: 'Lights flickering intermittently.',
                  status: 'Resolved',
                  statusColor: Colors.green,
                  upvotes: 12,
                ),
              ],
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
              Row(
                children: [
                  const Icon(
                    LucideIcons.thumbsUp,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    upvotes.toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

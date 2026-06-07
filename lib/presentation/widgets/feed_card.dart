import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';

class FeedCard extends StatelessWidget {
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

  const FeedCard({
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grey200),
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
                  color: AppColors.grey200,
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
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
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
          Text(description, style: const TextStyle(color: AppColors.black87)),
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
                      color: isLiked ? AppColors.primary : AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      upvotes.toString(),
                      style: TextStyle(
                        color: isLiked ? AppColors.primary : AppColors.grey,
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

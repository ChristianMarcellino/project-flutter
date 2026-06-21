import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localmart/models/app_notif.dart';
import 'package:localmart/theme/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppTheme.surface
            : AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notification.isRead ? AppTheme.border : AppTheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.background,
            child:
                notification.profilePicture != null &&
                    notification.profilePicture!.isNotEmpty
                ? ClipOval(
                    child: Image.memory(
                      base64Decode(notification.profilePicture!),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, color: AppTheme.textSecondary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _timeAgo(notification.createdAt.toDate()),
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          if (notification.productImage != null &&
              notification.productImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(notification.productImage!),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    width: 52,
                    height: 52,
                    color: AppTheme.background,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

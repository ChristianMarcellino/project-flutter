import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localmart/models/app_notif.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF5FDF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : const Color(0xFF21C063),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
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
                : const Icon(Icons.person),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 4),

                Text(
                  _timeAgo(notification.createdAt.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
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

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    return '${diff.inDays}d ago';
  }
}

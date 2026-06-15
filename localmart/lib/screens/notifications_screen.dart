import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/app_notif.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/notif_service.dart';
import 'package:localmart/widgets/notifications_card.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final _notifService = NotifService();

  @override
  Widget build(BuildContext context) {
    final userId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notifService.markAllAsRead(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notifService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return InkWell(
                onTap: () async {
                  await _notifService.markAsRead(notification.id);
                  if (notification.productId != null) {
                    context.push('/product/${notification.productId}');
                  }
                },
                child: NotificationCard(notification: notification),
              );
            },
          );
        },
      ),
    );
  }
}

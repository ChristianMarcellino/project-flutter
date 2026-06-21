import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/main.dart';
import 'package:localmart/models/app_notif.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/notif_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/notifications_card.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final _notifService = NotifService();

  @override
  Widget build(BuildContext context) {
    final userId = authService.currentUser!.uid;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,

          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            centerTitle: false,

            iconTheme: IconThemeData(color: AppTheme.textPrimary),

            title: Text(
              "Notifications",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            actions: [
              IconButton(
                tooltip: 'Mark all as read',
                icon: Icon(Icons.done_all, color: AppTheme.textPrimary),
                onPressed: () async {
                  await _notifService.markAllAsRead(userId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.surface,
                        content: Text(
                          'All notifications marked as read',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Something went wrong",
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No notifications",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You're all caught up!",
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await _notifService.markAsRead(notification.id);

                        if (notification.productId != null && context.mounted) {
                          context.push('/product/${notification.productId}');
                        }
                      },
                      child: NotificationCard(notification: notification),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

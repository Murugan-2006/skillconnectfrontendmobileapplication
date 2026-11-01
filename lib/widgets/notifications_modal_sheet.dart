import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../services/notification_service.dart';

class NotificationsModalSheet extends StatelessWidget {
  const NotificationsModalSheet({super.key});

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppConstants.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications & Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  if (notificationService.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notificationService.unreadCount} NEW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (notifications.isNotEmpty && notificationService.unreadCount > 0)
                TextButton(
                  onPressed: () => notificationService.markAllAsRead(),
                  child: const Text('Mark all read', style: TextStyle(color: AppConstants.primaryColor, fontSize: 12)),
                ),
            ],
          ),
          const Divider(height: 24),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Notifications Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimaryColor),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Updates regarding your booking requests will appear here in real-time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        onDismissed: (_) {
                          notificationService.markAsRead(item.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? Colors.grey.shade50
                                : AppConstants.primaryLightColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            border: Border.all(
                              color: item.isRead
                                  ? Colors.grey.shade200
                                  : AppConstants.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: item.type == 'accepted'
                                    ? AppConstants.successColor.withValues(alpha: 0.15)
                                    : item.type == 'in_progress'
                                        ? AppConstants.secondaryColor.withValues(alpha: 0.15)
                                        : AppConstants.primaryColor.withValues(alpha: 0.15),
                                child: Icon(
                                  item.type == 'accepted'
                                      ? Icons.check_circle
                                      : item.type == 'in_progress'
                                          ? Icons.timer
                                          : Icons.notifications,
                                  color: item.type == 'accepted'
                                      ? AppConstants.successColor
                                      : item.type == 'in_progress'
                                          ? AppConstants.secondaryColor
                                          : AppConstants.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: AppConstants.textPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTimestamp(item.timestamp),
                                          style: const TextStyle(fontSize: 11, color: AppConstants.textSecondaryColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.body,
                                      style: const TextStyle(fontSize: 13, color: AppConstants.textSecondaryColor, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

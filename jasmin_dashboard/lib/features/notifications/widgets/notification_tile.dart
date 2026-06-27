import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/admin_notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile(
      {super.key,
      required this.notification,
      required this.isBusy,
      required this.onToggleRead});
  final AdminNotificationModel notification;
  final bool isBusy;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openTarget(context),
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.black.withValues(alpha: 0.04)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: notification.isRead
              ? Colors.black54
              : Theme.of(context).colorScheme.primary,
          child: Icon(_icon),
        ),
        title: Text(notification.title,
            style: TextStyle(
                fontWeight:
                    notification.isRead ? FontWeight.w700 : FontWeight.w900)),
        subtitle: Text(
            '${notification.message}\n${notification.type} • ${Formatters.dateTimeOrDash(notification.createdAt)}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2))
            : IconButton(
                tooltip: notification.isRead ? 'Mark unread' : 'Mark read',
                onPressed: onToggleRead,
                icon: Icon(notification.isRead
                    ? Icons.mark_email_unread_rounded
                    : Icons.mark_email_read_rounded)),
      ),
    );
  }

  IconData get _icon {
    if (notification.type.contains('order')) {
      return Icons.receipt_long_rounded;
    }
    if (notification.type.contains('product')) {
      return Icons.inventory_2_rounded;
    }
    if (notification.type.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.notifications_rounded;
  }

  void _openTarget(BuildContext context) {
    if (notification.targetType == 'order' && notification.targetId != null) {
      context.go('/orders/${Uri.encodeComponent(notification.targetId!)}');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/incident_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/date_format.dart';
import '../utils/incident_styles.dart';
import '../widgets/empty_state.dart';
import 'incidents/incident_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.loadError != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not load notifications',
        message: provider.loadError!,
      );
    }
    if (provider.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'No notifications yet',
        message: "You'll be notified here when staff update or remove your reports.",
      );
    }
    return ListView.separated(
      itemCount: provider.notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _NotificationTile(notification: provider.notifications[index]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  void _open(BuildContext context) {
    context.read<NotificationProvider>().markAsRead(notification);

    final incident = context.read<IncidentProvider>().findById(notification.incidentId);
    if (incident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This report is no longer available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IncidentDetailScreen(incidentId: incident.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = notification.isDeletion
        ? Colors.red
        : StatusStyle.color(notification.status ?? '');
    final icon = notification.isDeletion
        ? Icons.delete_outline
        : StatusStyle.icon(notification.status ?? '');
    final unread = !notification.read;

    return ListTile(
      tileColor: unread ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        notification.message,
        style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Text(AppDateFormat.relative(notification.createdAt)),
      trailing: unread
          ? Icon(Icons.circle, size: 10, color: theme.colorScheme.primary)
          : null,
      onTap: () => _open(context),
    );
  }
}
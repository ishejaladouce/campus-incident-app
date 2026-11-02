import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.profile;
    final reportCount = context.watch<IncidentProvider>().myIncidents(user?.uid ?? '').length;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(user?.name ?? '', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        Text(user?.email ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(
          child: Chip(
            avatar: Icon(auth.isStaff ? Icons.badge_outlined : Icons.school_outlined, size: 18),
            label: Text(auth.isStaff ? 'Campus staff' : 'Student'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Reports I submitted'),
            trailing: Text('$reportCount', style: theme.textTheme.titleLarge),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}
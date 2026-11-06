import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../utils/incident_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import '../incidents/incident_detail_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  void _open(BuildContext context, Incident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IncidentDetailScreen(incidentId: incident.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Loading failed: explain why and offer to try again
    if (provider.loadError != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not load the dashboard',
        message: provider.loadError!,
        actionLabel: 'Try again',
        onAction: provider.retry,
      );
    }

    final needsAttention = provider.needsAttention;
    final inProgress = provider.inProgressIncidents;
    final highPriorityOpen = provider.highPriorityOpenCount;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Overview',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: IncidentStatus.all
                .map((status) => _StatCard(
                      status: status,
                      count: provider.countByStatus(status),
                    ))
                .toList(),
          ),
        ),
        if (highPriorityOpen > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Card(
              elevation: 0,
              color: Colors.red.withValues(alpha: 0.08),
              child: ListTile(
                leading: const Icon(Icons.priority_high, color: Colors.red),
                title: Text(
                  '$highPriorityOpen high-priority '
                  '${highPriorityOpen == 1 ? 'report' : 'reports'} still open',
                ),
                subtitle: const Text('Submitted or in progress'),
              ),
            ),
          ),
        const _SectionHeader(
          title: 'Needs attention',
          subtitle: 'New reports, highest priority and oldest first',
        ),
        if (needsAttention.isEmpty)
          const _EmptyNote(text: 'All caught up! No new reports.')
        else
          ...needsAttention.map(
            (incident) => IncidentCard(incident: incident, onTap: () => _open(context, incident)),
          ),
        const _SectionHeader(
          title: 'In progress',
          subtitle: 'Reports your team is currently working on',
        ),
        if (inProgress.isEmpty)
          const _EmptyNote(text: 'Nothing in progress right now.')
        else
          ...inProgress.map(
            (incident) => IncidentCard(incident: incident, onTap: () => _open(context, incident)),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String status;
  final int count;
  const _StatCard({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.color(status);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(StatusStyle.icon(status), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    IncidentStatus.label(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
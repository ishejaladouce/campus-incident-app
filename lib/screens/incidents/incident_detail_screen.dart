import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/date_format.dart';
import '../../utils/incident_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/status_update_sheet.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  Future<void> _openStatusSheet(BuildContext context, Incident incident) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<IncidentProvider>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StatusUpdateSheet(incident: incident),
    );
    if (success == null) return; // sheet closed without saving
    messenger.showSnackBar(SnackBar(
      content: Text(success ? 'Status updated' : provider.error ?? 'Could not update status'),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text(
          'This permanently removes the report and its photo. '
          'Use this for spam, duplicates or inappropriate content. '
          'To close a valid report, update its status instead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<IncidentProvider>();
    final success = await provider.deleteIncident(incident);
    if (success) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.error ?? 'Could not delete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    // Read the latest version from the provider, so status changes appear instantly
    final incident = provider.findById(incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.delete_outline,
          title: 'Report not available',
          message: 'This report may have been deleted.',
        ),
      );
    }

    final theme = Theme.of(context);
    final isOwner = incident.reportedBy == auth.profile?.uid;
    final canDelete = auth.isStaff || (isOwner && incident.status == IncidentStatus.submitted);
    // Privacy: other students don't see who reported the issue
    final reporterLabel = isOwner
        ? 'You'
        : auth.isStaff
            ? incident.reporterName
            : 'A student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete report',
              onPressed: () => _confirmDelete(context, incident),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (incident.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                incident.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(incident.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: incident.status),
              Chip(
                avatar: Icon(CategoryStyle.icon(incident.category), size: 16),
                label: Text(incident.category),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: Icon(Icons.flag_outlined, size: 16, color: PriorityStyle.color(incident.priority)),
                label: Text('${incident.priority} priority'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.place_outlined, label: 'Location', value: incident.location),
          _InfoRow(icon: Icons.person_outline, label: 'Reported by', value: reporterLabel),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Submitted',
            value: AppDateFormat.full(incident.createdAt),
          ),
          const SizedBox(height: 16),
          Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(incident.description),
          if (incident.staffNote != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.secondaryContainer,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Note from campus staff'),
                subtitle: Text(incident.staffNote!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Status timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...incident.history.map((change) => _TimelineTile(change: change, showReporter: auth.isStaff || isOwner)),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: auth.isStaff
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: 'Update status',
                  onPressed: () => _openStatusSheet(context, incident),
                  isLoading: provider.isSubmitting,
                ),
              ),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final StatusChange change;
  final bool showReporter;
  const _TimelineTile({required this.change, required this.showReporter});

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.color(change.status);
    final isSubmission = change.status == IncidentStatus.submitted;
    final who = isSubmission && !showReporter ? 'A student' : change.changedBy;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(StatusStyle.icon(change.status), color: color),
      ),
      title: Text(IncidentStatus.label(change.status)),
      subtitle: Text([
        if (change.note != null) change.note!,
        '$who • ${AppDateFormat.full(change.changedAt)}',
      ].join('\n')),
      isThreeLine: change.note != null,
    );
  }
}
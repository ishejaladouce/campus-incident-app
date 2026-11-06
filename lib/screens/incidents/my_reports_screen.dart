import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final uid = context.watch<AuthProvider>().profile?.uid ?? '';
    final myReports = provider.myIncidents(uid);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Loading failed: explain why and offer to try again
    if (provider.loadError != null && myReports.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not load your reports',
        message: provider.loadError!,
        actionLabel: 'Try again',
        onAction: provider.retry,
      );
    }
    if (myReports.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No reports yet',
        message: 'Tap "Report issue" to tell campus staff about a problem.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: myReports.length,
      itemBuilder: (context, index) {
        final incident = myReports[index];
        return IncidentCard(
          incident: incident,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => IncidentDetailScreen(incidentId: incident.id)),
          ),
        );
      },
    );
  }
}
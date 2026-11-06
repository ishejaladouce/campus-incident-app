import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../utils/incident_styles.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final isStaff = context.watch<AuthProvider>().isStaff;
    final incidents = provider.filteredIncidents;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search title, description or location',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: provider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    ),
            ),
          ),
        ),
        _ChipRow(children: [
          _filterChip('All categories', provider.categoryFilter == null,
              () => provider.setCategoryFilter(null)),
          for (final category in IncidentCategory.all)
            _filterChip(category, provider.categoryFilter == category,
                () => provider.setCategoryFilter(category)),
        ]),
        _ChipRow(children: [
          _filterChip('All statuses', provider.statusFilter == null,
              () => provider.setStatusFilter(null)),
          for (final status in IncidentStatus.all)
            _filterChip(IncidentStatus.label(status), provider.statusFilter == status,
                () => provider.setStatusFilter(status)),
        ]),
        if (isStaff) _StaffSummary(provider: provider),
        Expanded(child: _buildList(provider, incidents)),
      ],
    );
  }

  Widget _buildList(IncidentProvider provider, List<Incident> incidents) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Loading failed: explain why and offer to try again
    if (provider.loadError != null && incidents.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not load reports',
        message: provider.loadError!,
        actionLabel: 'Try again',
        onAction: provider.retry,
      );
    }
    if (incidents.isEmpty) {
      return provider.hasActiveFilters
          ? EmptyState(
              icon: Icons.search_off,
              title: 'No matching reports',
              message: 'Try a different search or filter.',
              actionLabel: 'Clear filters',
              onAction: () {
                _searchController.clear();
                provider.clearFilters();
              },
            )
          : const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: 'Reports submitted by students will appear here.',
            );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
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

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: children,
      ),
    );
  }
}

// Staff see a quick count of reports per status
class _StaffSummary extends StatelessWidget {
  final IncidentProvider provider;
  const _StaffSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: IncidentStatus.all.map((status) {
          final color = StatusStyle.color(status);
          return Expanded(
            child: Card(
              elevation: 0,
              color: color.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      '${provider.countByStatus(status)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      IncidentStatus.label(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
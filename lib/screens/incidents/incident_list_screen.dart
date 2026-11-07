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

    // One scrolling page: the search and filters scroll away with the list,
    // so the reports get the space they need on any screen size
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
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
        ),
        // Two filters side by side: they always fit the screen width
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    icon: Icons.category_outlined,
                    allLabel: 'All categories',
                    value: provider.categoryFilter,
                    options: IncidentCategory.all,
                    labelOf: (category) => category,
                    onChanged: provider.setCategoryFilter,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
                    icon: Icons.flag_outlined,
                    allLabel: 'All statuses',
                    value: provider.statusFilter,
                    options: IncidentStatus.all,
                    labelOf: IncidentStatus.label,
                    onChanged: provider.setStatusFilter,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isStaff) SliverToBoxAdapter(child: _StaffSummary(provider: provider)),
        ..._buildResults(provider, incidents),
      ],
    );
  }

  List<Widget> _buildResults(IncidentProvider provider, List<Incident> incidents) {
    if (provider.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    // Loading failed: explain why and offer to try again
    if (provider.loadError != null && incidents.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off,
            title: 'Could not load reports',
            message: provider.loadError!,
            actionLabel: 'Try again',
            onAction: provider.retry,
          ),
        ),
      ];
    }
    if (incidents.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: provider.hasActiveFilters
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
                ),
        ),
      ];
    }
    return [
      SliverPadding(
        // Space at the bottom so the "Report issue" button never hides the last card
        padding: const EdgeInsets.only(bottom: 88),
        sliver: SliverList.builder(
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
        ),
      ),
    ];
  }
}

// A compact dropdown button for one filter (category or status)
class _FilterDropdown extends StatelessWidget {
  static const _allValue = '__all__';

  final IconData icon;
  final String allLabel;
  final String? value;
  final List<String> options;
  final String Function(String) labelOf;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = value != null;

    return PopupMenuButton<String>(
      tooltip: allLabel,
      onSelected: (selected) => onChanged(selected == _allValue ? null : selected),
      itemBuilder: (context) => [
        _item(_allValue, allLabel, !isActive),
        ...options.map((option) => _item(option, labelOf(option), option == value)),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.secondaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? colors.primary : colors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isActive ? labelOf(value!) : allLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String itemValue, String label, bool selected) {
    return PopupMenuItem<String>(
      value: itemValue,
      child: Row(
        children: [
          SizedBox(width: 24, child: selected ? const Icon(Icons.check, size: 18) : null),
          const SizedBox(width: 8),
          Text(label),
        ],
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
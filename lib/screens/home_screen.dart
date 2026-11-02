import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import 'incidents/incident_list_screen.dart';
import 'incidents/my_reports_screen.dart';
import 'incidents/report_incident_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final IncidentProvider _incidentProvider;

  static const _titles = [AppConstants.appName, 'My reports', 'Profile'];

  @override
  void initState() {
    super.initState();
    // Start the real-time Firestore listener once the user is logged in
    _incidentProvider = context.read<IncidentProvider>();
    _incidentProvider.startListening();
  }

  @override
  void dispose() {
    // Stop listening when the user logs out
    _incidentProvider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (isStaff)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(label: Text('Staff'), visualDensity: VisualDensity.compact),
            ),
        ],
      ),
      // IndexedStack keeps each tab's scroll position when switching
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          IncidentListScreen(),
          MyReportsScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportIncidentScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Report issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'All reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined),
            selectedIcon: Icon(Icons.assignment_ind),
            label: 'My reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import 'incidents/incident_list_screen.dart';
import 'incidents/my_reports_screen.dart';
import 'incidents/report_incident_screen.dart';
import 'profile_screen.dart';
import 'staff/staff_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final IncidentProvider _incidentProvider;

  @override
  void initState() {
    super.initState();
    // Start the real-time Firestore listener once the user is logged in
    _incidentProvider = context.read<IncidentProvider>();
    _incidentProvider.startListening();
  }

  @override
  void dispose() {
    _incidentProvider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;
    final titles = [
      AppConstants.appName,
      isStaff ? 'Staff dashboard' : 'My reports',
      'Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
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
        children: [
          const IncidentListScreen(),
          // Staff get a dashboard; students get their own reports
          isStaff ? const StaffDashboardScreen() : const MyReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || (!isStaff && _currentIndex == 1)
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'All reports',
          ),
          isStaff
              ? const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                )
              : const NavigationDestination(
                  icon: Icon(Icons.assignment_ind_outlined),
                  selectedIcon: Icon(Icons.assignment_ind),
                  label: 'My reports',
                ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
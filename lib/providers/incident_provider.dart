import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../models/user_model.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service;
  IncidentProvider(this._service);

  StreamSubscription<List<Incident>>? _subscription;
  List<Incident> _incidents = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Search and filters
  String _searchQuery = '';
  String? _categoryFilter;
  String? _statusFilter;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get statusFilter => _statusFilter;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _categoryFilter != null || _statusFilter != null;

  // The list the screens show, after search + filters
  List<Incident> get filteredIncidents {
    final query = _searchQuery.toLowerCase();
    return _incidents.where((incident) {
      final matchesSearch = query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query);
      final matchesCategory =
          _categoryFilter == null || incident.category == _categoryFilter;
      final matchesStatus =
          _statusFilter == null || incident.status == _statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  List<Incident> myIncidents(String uid) =>
      _incidents.where((i) => i.reportedBy == uid).toList();

  int countByStatus(String status) =>
      _incidents.where((i) => i.status == status).length;

    // ---------- Staff dashboard ----------
  static const Map<String, int> _priorityRank = {'High': 0, 'Medium': 1, 'Low': 2};

  // High priority first, then the oldest first, so nothing urgent waits too long
  int _byPriorityThenOldest(Incident a, Incident b) {
    final byPriority = (_priorityRank[a.priority] ?? 1)
        .compareTo(_priorityRank[b.priority] ?? 1);
    if (byPriority != 0) return byPriority;
    return a.createdAt.compareTo(b.createdAt);
  }

  List<Incident> get needsAttention => _incidents
      .where((i) => i.status == IncidentStatus.submitted)
      .toList()
    ..sort(_byPriorityThenOldest);

  List<Incident> get inProgressIncidents => _incidents
      .where((i) => i.status == IncidentStatus.inProgress)
      .toList()
    ..sort(_byPriorityThenOldest);

  int get highPriorityOpenCount => _incidents
      .where((i) =>
          i.priority == 'High' &&
          (i.status == IncidentStatus.submitted ||
              i.status == IncidentStatus.inProgress))
      .length;

  // Used by the details screen, so it always shows the latest version
  Incident? findById(String id) {
    for (final incident in _incidents) {
      if (incident.id == id) return incident;
    }
    return null;
  }

  // Start listening after login
  void startListening() {
    if (_subscription != null) return;
    _subscription = _service.watchIncidents().listen(
      (incidents) {
        _incidents = incidents;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  // Stop listening on logout
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _incidents = [];
    _isLoading = true;
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
    notifyListeners();
  }

  Future<bool> submitIncident({
    required String title,
    required String category,
    required String description,
    required String location,
    required String priority,
    File? image,
    required AppUser reporter,
  }) {
    return _run(() => _service.createIncident(
          title: title,
          category: category,
          description: description,
          location: location,
          priority: priority,
          image: image,
          reporter: reporter,
        ));
  }

  Future<bool> updateStatus({
    required String incidentId,
    required String status,
    String? note,
    required AppUser staff,
  }) {
    return _run(() => _service.updateStatus(
          incidentId: incidentId,
          status: status,
          note: note,
          staff: staff,
        ));
  }

  Future<bool> deleteIncident(Incident incident) {
    return _run(() => _service.deleteIncident(incident));
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseException catch (e) {
      _error = e.code == 'permission-denied'
          ? 'You do not have permission to do that.'
          : 'Something went wrong (${e.code}). Please try again.';
      return false;
    } catch (e) {
      debugPrint('Incident action failed: $e');
      _error = 'Something went wrong. Please try again.';
      return false;;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
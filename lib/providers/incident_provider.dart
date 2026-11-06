import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../models/user_model.dart';
import '../services/incident_service.dart';
import '../utils/error_messages.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service;
  IncidentProvider(this._service);

  // Photo uploads can be slow on campus Wi-Fi, so allow a bit more time
  static const _timeout = Duration(seconds: 45);

  StreamSubscription<List<Incident>>? _subscription;
  List<Incident> _incidents = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error; // errors from actions (submit, update, delete)
  String? _loadError; // errors while loading the list

  // Search and filters
  String _searchQuery = '';
  String? _categoryFilter;
  String? _statusFilter;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get loadError => _loadError;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get statusFilter => _statusFilter;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _categoryFilter != null || _statusFilter != null;

  // ---------- Lists for the screens ----------

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

  // Used by the details screen, so it always shows the latest version
  Incident? findById(String id) {
    for (final incident in _incidents) {
      if (incident.id == id) return incident;
    }
    return null;
  }

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

  // ---------- Real-time listening ----------

  // Start listening after login
  void startListening() {
    if (_subscription != null) return;
    _subscription = _service.watchIncidents().listen(
      (incidents) {
        _incidents = incidents;
        _isLoading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not load reports: $e');
        _isLoading = false;
        _loadError = ErrorMessages.from(e);
        notifyListeners();
      },
    );
  }

  // Try loading again after an error
  void retry() {
    _subscription?.cancel();
    _subscription = null;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    startListening();
  }

  // Stop listening on logout
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _incidents = [];
    _isLoading = true;
    _loadError = null;
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
  }

  // ---------- Search and filters ----------

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

  // ---------- Actions ----------

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

  // Runs an action with loading, a timeout and friendly error messages
  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action().timeout(_timeout);
      return true;
    } catch (e) {
      debugPrint('Incident action failed: $e');
      _error = ErrorMessages.from(e);
      return false;
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
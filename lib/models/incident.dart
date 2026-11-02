import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentStatus {
  static const String submitted = 'submitted';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String rejected = 'rejected';

  static const List<String> all = [submitted, inProgress, resolved, rejected];

  static String label(String status) {
    switch (status) {
      case inProgress:
        return 'In progress';
      case resolved:
        return 'Resolved';
      case rejected:
        return 'Rejected';
      default:
        return 'Submitted';
    }
  }
}

class IncidentCategory {
  static const List<String> all = [
    'Water',
    'Electricity',
    'Facilities',
    'Furniture',
    'Sanitation',
    'Safety',
    'Other',
  ];
}

class IncidentPriority {
  static const List<String> all = ['Low', 'Medium', 'High'];
}

// One entry in the report's timeline (e.g. "Submitted", then "In progress")
class StatusChange {
  final String status;
  final String? note;
  final String changedBy;
  final DateTime changedAt;

  StatusChange({
    required this.status,
    this.note,
    required this.changedBy,
    required this.changedAt,
  });

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: map['status'] ?? IncidentStatus.submitted,
      note: map['note'],
      changedBy: map['changedBy'] ?? '',
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'note': note,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
    };
  }
}

class Incident {
  final String id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String priority;
  final String? imageUrl;
  final String status;
  final String reportedBy;
  final String reporterName;
  final String? staffNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusChange> history;

  Incident({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.priority,
    this.imageUrl,
    required this.status,
    required this.reportedBy,
    required this.reporterName,
    this.staffNote,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
  });

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawHistory = data['history'] as List<dynamic>? ?? [];

    return Incident(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'Other',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      priority: data['priority'] ?? 'Medium',
      imageUrl: data['imageUrl'],
      status: data['status'] ?? IncidentStatus.submitted,
      reportedBy: data['reportedBy'] ?? '',
      reporterName: data['reporterName'] ?? '',
      staffNote: data['staffNote'],
      // serverTimestamp can be null for a split second right after saving
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      history: rawHistory
          .map((e) => StatusChange.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationType {
  static const String statusChanged = 'status_changed';
  static const String deleted = 'deleted';
}

class AppNotification {
  final String id;
  final String userId; 
  final String incidentId;
  final String incidentTitle;
  final String type;
  final String? status; 
  final String message;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.incidentId,
    required this.incidentTitle,
    required this.type,
    this.status,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  bool get isDeletion => type == NotificationType.deleted;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      incidentId: data['incidentId'] ?? '',
      incidentTitle: data['incidentTitle'] ?? '',
      type: data['type'] ?? NotificationType.statusChanged,
      status: data['status'],
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
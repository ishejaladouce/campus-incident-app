import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import '../models/app_notification.dart';
import '../models/incident.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';
import 'image_storage_service.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImageStorageService _imageStorage;

  // The photo storage is "injected", so it can be Firebase or Supabase
  IncidentService(this._imageStorage);

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // Real-time stream: the app updates automatically when anything changes
  Stream<List<Incident>> watchIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Incident.fromDoc).toList());
  }

  // CREATE
  Future<void> createIncident({
    required String title,
    required String category,
    required String description,
    required String location,
    required String priority,
    File? image,
    required AppUser reporter,
  }) async {
    // Create the document ID first, so the photo can use the same ID
    final doc = _incidents.doc();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _imageStorage.uploadIncidentImage(incidentId: doc.id, image: image);
    }

    await doc.set({
      'title': title.trim(),
      'category': category,
      'description': description.trim(),
      'location': location.trim(),
      'priority': priority,
      'imageUrl': imageUrl,
      'status': IncidentStatus.submitted,
      'reportedBy': reporter.uid,
      'reporterName': reporter.name,
      'staffNote': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'history': [
        StatusChange(
          status: IncidentStatus.submitted,
          note: 'Report submitted',
          changedBy: reporter.name,
          changedAt: DateTime.now(),
        ).toMap(),
      ],
    });
  }

  // UPDATE (staff only) + notify the student, saved together in one batch
  Future<void> updateStatus({
    required String incidentId,
    required String status,
    String? note,
    required AppUser staff,
  }) async {
    final cleanNote = (note == null || note.trim().isEmpty) ? null : note.trim();

    final ref = _incidents.doc(incidentId);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw const AppException('This report no longer exists.');
    }
    final incident = Incident.fromDoc(snapshot);

    final batch = _db.batch();
    batch.update(ref, {
      'status': status,
      'staffNote': cleanNote,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        StatusChange(
          status: status,
          note: cleanNote,
          changedBy: staff.name,
          changedAt: DateTime.now(),
        ).toMap(),
      ]),
    });
    batch.set(_notifications.doc(), {
      'userId': incident.reportedBy,
      'incidentId': incident.id,
      'incidentTitle': incident.title,
      'type': NotificationType.statusChanged,
      'status': status,
      'message': _statusMessage(incident.title, status, cleanNote),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    // Both writes succeed together, or neither does
    await batch.commit();
  }

  static String _statusMessage(String title, String status, String? note) {
    final base = 'Your report "$title" is now ${IncidentStatus.label(status).toLowerCase()}.';
    return note == null ? base : '$base Staff note: $note';
  }

  // DELETE (also tries to remove the photo, and notifies the reporter)
  Future<void> deleteIncident(Incident incident) async {
    if (incident.imageUrl != null) {
      try {
        await _imageStorage.deleteIncidentImage(incident.imageUrl!);
      } catch (_) {
        // If the photo can't be removed, still delete the report
      }
    }

    final batch = _db.batch();
    batch.delete(_incidents.doc(incident.id));

    // Notify the student only when someone else (staff) removed their report
    final deletedBy = FirebaseAuth.instance.currentUser?.uid;
    if (deletedBy != incident.reportedBy) {
      batch.set(_notifications.doc(), {
        'userId': incident.reportedBy,
        'incidentId': incident.id,
        'incidentTitle': incident.title,
        'type': NotificationType.deleted,
        'status': null,
        'message': 'Your report "${incident.title}" was removed by campus staff. '
            'This usually happens with duplicates, spam or inappropriate content.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit();
  }
}
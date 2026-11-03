import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../models/user_model.dart';
import 'image_storage_service.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImageStorageService _imageStorage;

  // The photo storage is "injected", so it can be Firebase or Supabase
  IncidentService(this._imageStorage);

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

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

  // UPDATE (staff only, enforced by Firestore security rules)
  Future<void> updateStatus({
    required String incidentId,
    required String status,
    String? note,
    required AppUser staff,
  }) {
    final cleanNote =
        (note == null || note.trim().isEmpty) ? null : note.trim();

    return _incidents.doc(incidentId).update({
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
  }

  // DELETE (also tries to remove the photo)
  Future<void> deleteIncident(Incident incident) async {
    if (incident.imageUrl != null) {
      try {
        await _imageStorage.deleteIncidentImage(incident.imageUrl!);
      } catch (_) {
        // If the photo can't be removed, still delete the report
      }
    }
    await _incidents.doc(incident.id).delete();
  }
}
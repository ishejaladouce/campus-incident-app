import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/incident.dart';
import '../models/user_model.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final ref = _storage.ref('incident_images/${doc.id}.jpg');
      await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl = await ref.getDownloadURL();
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

  // UPDATE (staff only, enforced later by security rules)
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

  // DELETE (also removes the photo from Storage)
  Future<void> deleteIncident(Incident incident) async {
    if (incident.imageUrl != null) {
      try {
        await _storage.refFromURL(incident.imageUrl!).delete();
      } catch (_) {
        // If the photo is already gone, still delete the report
      }
    }
    await _incidents.doc(incident.id).delete();
  }
}
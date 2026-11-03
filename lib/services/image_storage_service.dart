import 'dart:io';

abstract class ImageStorageService {
  Future<String> uploadIncidentImage({required String incidentId, required File image});
  Future<void> deleteIncidentImage(String imageUrl);
}
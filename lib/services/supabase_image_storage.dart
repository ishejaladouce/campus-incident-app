import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, SupabaseClient, FileOptions, StorageException;
import '../config/supabase_config.dart';
import '../utils/app_exception.dart';
import 'image_storage_service.dart';

// Supabase Storage version (free tier, no payment card needed)
class SupabaseImageStorage implements ImageStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String> uploadIncidentImage({required String incidentId, required File image}) async {
    final path = '$incidentId.jpg';
    try {
      await _client.storage.from(SupabaseConfig.bucket).upload(
            path,
            image,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
          );
      return _client.storage.from(SupabaseConfig.bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      debugPrint('Photo upload failed: ${e.message}');
      throw const AppException('Could not upload the photo. Please try again.');
    } catch (e) {
      debugPrint('Photo upload failed: $e');
      throw const AppException(
        'Could not upload the photo. Check your internet connection and try again.',
      );
    }
  }

  @override
  Future<void> deleteIncidentImage(String imageUrl) async {
    // The file name is the last part of the URL, e.g. "abc123.jpg"
    final path = Uri.parse(imageUrl).pathSegments.last;
    await _client.storage.from(SupabaseConfig.bucket).remove([path]);
  }
}
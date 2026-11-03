import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient, FileOptions;
import '../config/supabase_config.dart';
import 'image_storage_service.dart';

// Supabase Storage 
class SupabaseImageStorage implements ImageStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String> uploadIncidentImage({required String incidentId, required File image}) async {
    final path = '$incidentId.jpg';
    await _client.storage.from(SupabaseConfig.bucket).upload(
          path,
          image,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
    return _client.storage.from(SupabaseConfig.bucket).getPublicUrl(path);
  }

  @override
  Future<void> deleteIncidentImage(String imageUrl) async {
    // The file name is the last part of the URL, e.g. "abc123.jpg"
    final path = Uri.parse(imageUrl).pathSegments.last;
    await _client.storage.from(SupabaseConfig.bucket).remove([path]);
  }
}
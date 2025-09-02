import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class StorageRepository {
  final SupabaseClient _client = SupabaseService.client;

  // Carica un file e ritorna l'URL pubblico
  Future<String?> uploadPublic({
    required String bucket,
    required String path, // es:'challenge_123_1690000000.jpg'
    required Uint8List bytes,
    required String contentType, // es:'image/jpeg'
    bool upsert = true, // se upsert=true consente sovrascrittura
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: upsert),
          );
      // URL pubblico:
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      // se esiste e upsert=true, aggiorna tramite updateBinary
      if (upsert) {
        try {
          await _client.storage.from(bucket).updateBinary(
                path,
                bytes,
                fileOptions: FileOptions(contentType: contentType, upsert: upsert),
              );
          return _client.storage.from(bucket).getPublicUrl(path);
        } catch (_) {}
      }
      rethrow;
    }
  }
}
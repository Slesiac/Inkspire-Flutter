import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

//Future<void> indica che il metodo è asincrono e che restituisce un Future,
//valore che arriverà in futuro e che potrà essere completato con successo o con errore.
class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  //getter statici che incapsulano i moduli principali
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
}
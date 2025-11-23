import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseClient {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  static GoTrueClient get auth => Supabase.instance.client.auth;
  
  static PostgrestQueryBuilder from(String table) {
    return Supabase.instance.client.from(table);
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url {
    return dotenv.env['SUPABASE_URL']?.trim() ?? '';
  }

  static String get publishableKey {
    final publishableKey =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';

    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (publishableKey.isNotEmpty) {
      return publishableKey;
    }

    return anonKey;
  }

  static String get anonKey {
    return publishableKey;
  }

  static bool get isConfigured {
    return url.isNotEmpty && publishableKey.isNotEmpty;
  }

  static SupabaseClient get client {
    return Supabase.instance.client;
  }
}
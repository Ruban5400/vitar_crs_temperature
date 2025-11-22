// filename: lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._privateConstructor();

  static final SupabaseService _instance = SupabaseService._privateConstructor();

  /// Accessor for the singleton instance
  static SupabaseService get instance => _instance;

  /// The initialized Supabase client
  late final SupabaseClient client;

  /// Initialize Supabase. Call this once before runApp.
  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      // optionally pass auth persistence, debug, etc.
    );

    _instance.client = Supabase.instance.client;
  }

  /// Optional convenience getter
  SupabaseClient get c => client;
}

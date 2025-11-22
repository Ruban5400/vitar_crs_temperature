// filename: lib/services/master_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitar_crs_temperature/services/supabase_service.dart';

class NamesService {
  final SupabaseClient _client;

  NamesService({SupabaseClient? client}) : _client = client ?? SupabaseService.instance.client;

  /// Loads master options from 'ref_master' table returning a Map<Category, List<Value>>
  Future<Map<String, List<String>>> fetchMasterOptions() async {
    final Map<String, List<String>> out = {};
    try {
      final res = await _client.from('ref_master').select().order('value');
      if (res == null || res is! List) return out;

      for (final row in res) {
        final category = (row['category'] ?? '').toString();
        final value = (row['value'] ?? '').toString();
        if (category.isEmpty) continue;
        out.putIfAbsent(category, () => []).add(value);
      }
    } catch (e) {
      debugPrint('MasterService.fetchMasterOptions error: $e');
    }
    return out;
  }
}

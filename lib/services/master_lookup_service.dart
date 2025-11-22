import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class MasterService {
  final SupabaseClient _client;
  MasterService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Returns a map: category -> List<String> (ordered by sort_order)
  Future<Map<String, List<String>>> fetchMasterOptions() async {
    try {
      final res = await _client
          .from('vitar_master_lookup')
          .select('category, value, sort_order')
          .order('category')
          .order('sort_order');

      final Map<String, List<String>> out = {};
      if (res == null || res is! List) return out;

      for (final row in res) {
        final cat = (row['category'] as String?)?.trim() ?? 'unknown';
        final val = (row['value'] as String?) ?? '';
        out.putIfAbsent(cat, () => []);
        out[cat]!.add(val);
      }
      return out;
    } on PostgrestException catch (e) {
      debugPrint('MasterService error: ${e.message}');
      return {};
    } catch (e) {
      debugPrint('MasterService general error: $e');
      return {};
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:vitar_crs_temperature/models/meter_entry.dart';

class MeterService {
  final SupabaseClient _client;
  MeterService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<MeterEntry>> fetchMeterData({required String modelName}) async {
    try {

      final res = await _client
          .from('vitar_meter')
          .select('*')
          .eq('meter_model', modelName)
          .order('id', ascending: true);

      // if (res == null || res is! List) return [];

      final rows = res
          .whereType<Map<String, dynamic>>()
          .map((m) => MeterEntry.fromJson(m))
          .toList();
      return rows;
    } on PostgrestException catch (e) {
      debugPrint('MeterService error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('MeterService general error: $e');
      return [];
    }
  }
}

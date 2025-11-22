// filename: lib/services/reference_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:vitar_crs_temperature/models/reference_data.dart'; // SampleData model (you already have)

class ReferenceService {
  final SupabaseClient _client;
  ReferenceService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Returns a map like: { 'ST-S5': SampleData(...), 'ST-S6': SampleData(...), ... }
  Future<Map<String, SampleData>> fetchReferenceSamples() async {
    try {
      // select row_name, st_s5, st_s6, st_s4, id
      final res = await _client
          .from('vitar_calibration_reference_values')
          .select('row_name, st_s5, st_s6, st_s4, id')
          .order('id');
      final Map<String, SampleData> out = {};

      debugPrint('ReferenceService.fetchReferenceSamples: raw rows => $res');

      if (res == null || res is! List) return out;

      // Build temporary maps: sampleKey -> Map<normalizedRowName, value>
      final Map<String, Map<String, double>> tmp = {};

      // Helper: normalize DB row_name variants to internal keys row1/row3/row4/row5
      String _normalizeRowName(String raw) {
        final r = raw.trim().toLowerCase();
        // Known letter codes (observed in dump) -> map to logical rows
        if (r == 'r' || r == 'row r' || r == 'row1' || r == 'row_1') return 'row1';
        if (r == 'a' || r == 'row a' || r == 'row3' || r == 'row_3') return 'row3';
        if (r == 'b' || r == 'row b' || r == 'row4' || r == 'row_4') return 'row4';
        if (r == 'c' || r == 'row c' || r == 'row5' || r == 'row_5') return 'row5';
        // If already starts with 'row' and matches expected names, keep (row1,row3,row4,row5)
        if (r == 'row1' || r == 'row3' || r == 'row4' || r == 'row5') return r;
        // Unknown variant: log and pass raw lowercased so caller can decide
        debugPrint('ReferenceService: unexpected row_name="$raw" normalized -> "$r"');
        return r;
      }

      // Populate tmp with numeric values under normalized row keys
      for (final row in res) {
        final rawRowName = (row['row_name'] as String?) ?? '';
        final rowName = _normalizeRowName(rawRowName);

        for (final sampleKey in ['st_s5', 'st_s6', 'st_s4']) {
          final raw = row[sampleKey];
          if (raw == null) continue;
          final v = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
          if (v == null) continue;
          tmp.putIfAbsent(sampleKey, () => {});
          tmp[sampleKey]![rowName] = v;
        }
      }

      debugPrint('ReferenceService: tmp assembled => $tmp');

      // Convert tmp into SampleData objects (we expect certain row names: row1, row3, row4, row5)
      for (final sampleKey in tmp.keys) {
        final map = tmp[sampleKey]!;

        final row1 = <double>[];
        final row3 = <double>[];
        final row4 = <double>[];
        final row5 = <double>[];

        // If DB used letter codes (R/A/B/C) we've normalized them to row1/3/4/5 above.
        if (map.containsKey('row1')) row1.add(map['row1']!);
        if (map.containsKey('row3')) row3.add(map['row3']!);
        if (map.containsKey('row4')) row4.add(map['row4']!);
        if (map.containsKey('row5')) row5.add(map['row5']!);

        // Fallback: if row1 empty but there are other numeric values, attempt to guess:
        // (This is defensive — ideally DB should contain explicit row1/row3/row4/row5 or R/A/B/C)
        if (row1.isEmpty && map.isNotEmpty) {
          // try to find the largest value (likely the ~100 reference 'R')
          final entries = map.entries.toList();
          entries.sort((a, b) => b.value.compareTo(a.value)); // descending
          row1.add(entries.first.value);
          debugPrint('ReferenceService: fallback placing ${entries.first.value} into row1 for $sampleKey');
        }

        // Build SampleData with first element of each or sensible defaults.
        final sample = SampleData(
          row1: row1.isNotEmpty ? row1 : [1.0],
          row3: row3.isNotEmpty ? row3 : [0.0],
          row4: row4.isNotEmpty ? row4 : [0.0],
          row5: row5.isNotEmpty ? row5 : [0.0],
        );

        // Map sampleKey like 'st_s5' -> 'ST-S5' to match your existing keys
        final displayKey = sampleKey.toUpperCase().replaceAll('_', '-'); // st_s5 -> ST-S5
        out[displayKey] = sample;
      }

      debugPrint('ReferenceService: returning samples => ${out.keys.toList()}');
      return out;
    } on PostgrestException catch (e) {
      debugPrint('ReferenceService error: ${e.message}');
      return {};
    } catch (e) {
      debugPrint('ReferenceService general error: $e');
      return {};
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission_names.dart';
import 'supabase_service.dart';

class NamesService {
  final SupabaseClient _client;
  NamesService({SupabaseClient? client}) : _client = client ?? SupabaseService.instance.client;

  Future<List<PermissionName>> fetchByType(String type) async {
    try {
      final res = await _client
          .from('vitar_permission_names')
          .select('name,role,type')
          .eq('type', type)
          .order('name', ascending: true);

      final data = res as List<dynamic>? ?? [];
      final out = <PermissionName>[];

      for (final row in data) {
        if (row is Map) {
          out.add(PermissionName.fromMap(row));
        } else if (row is Map<String, dynamic>) {
          out.add(PermissionName.fromMap(row));
        } else {
          // defensive: try convert
          try {
            out.add(PermissionName.fromMap(Map<dynamic,dynamic>.from(row)));
          } catch (_) {
            debugPrint('NamesService.fetchByType: skipping invalid row: $row');
          }
        }
      }
      return out;
    } catch (e, st) {
      debugPrint('NamesService.fetchByType error: $e\n$st');
      return [];
    }
  }

  Future<Map<String, List<PermissionName>>> fetchCalibratedAndApproved() async {
    final results = await Future.wait([
      fetchByType('calibrated_by'),
      fetchByType('approved_signatory'),
    ]);
    return {
      'calibrated_by': results[0],
      'approved_signatory': results[1],
    };
  }
}

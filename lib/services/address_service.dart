// filename: lib/services/address_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitar_crs_temperature/services/supabase_service.dart';
import 'package:vitar_crs_temperature/models/address.dart';

class AddressService {
  final SupabaseClient _client;

  AddressService({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Returns a typed List<Address>
  Future<List<Address>> fetchAddressData() async {
    try {
      final response = await _client.from('vitar_address').select('*');

      if (response == null || response is! List) {
        debugPrint('AddressService: unexpected response type: ${response.runtimeType}');
        return <Address>[];
      }

      // Map only Map<String, dynamic> items to Address
      final List<Address> addresses = response
          .whereType<Map<String, dynamic>>()
          .map((m) => Address.fromJson(m))
          .toList();

      return addresses;
    } on PostgrestException catch (e) {
      debugPrint('Supabase Fetch Error (address): ${e.message}');
      return <Address>[];
    } catch (e) {
      debugPrint('General Error fetching address data: $e');
      return <Address>[];
    }
  }
}

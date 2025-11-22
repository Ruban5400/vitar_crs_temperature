import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/address.dart';

class AddressService {
  Future<List<Address>> fetchAddressData() async {
    try {
      // 1. Await the response from Supabase
      final response = await supabase
          .from('vitar_address')
          .select('*');

      final List<dynamic> dataList = response as List<dynamic>;

      final address = dataList
          .map((item) => Address.fromJson(item))
          .toList();
      return address;


    } on PostgrestException catch (e) {
      // Print the specific Supabase error message
      print('Supabase Fetch Error: ${e.message}');
      return [];
    } catch (e) {
      // Catch any remaining general Dart errors
      print('General Error fetching meter data: $e');
      return [];
    }
  }

}
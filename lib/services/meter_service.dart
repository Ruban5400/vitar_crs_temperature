import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/meter_entry.dart';

class MeterService {
  Future<List<MeterEntry>> fetchMeterData() async {
    try {
      // 1. Await the response from Supabase
      final response = await supabase
          .from('meter')
          .select()
      // Re-enable ordering by the correct column name (e.g., 'lv')
          .order('lower_value', ascending: true);

      // 2. CRITICAL FIX: Explicitly handle a null response from the API
      if (response == null) {
        return [];
      }

      // 3. Map the non-null list of JSON objects to MeterEntry objects.
      final List<dynamic> dataList = response as List<dynamic>;

      final meterEntries = dataList
          .map((item) => MeterEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      return meterEntries;

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
// filename: lib/providers/meter_provider.dart
import 'package:flutter/foundation.dart';
import 'package:vitar_crs_temperature/models/meter_entry.dart';
import 'package:vitar_crs_temperature/services/meter_service.dart';

class MeterProvider extends ChangeNotifier {
  final List<MeterEntry> _rows = [];
  final MeterService _service;

  bool loading = false;

  MeterProvider({MeterService? service}) : _service = service ?? MeterService();

  List<MeterEntry> get rows => List.unmodifiable(_rows);

  Future<List<MeterEntry>> fetchAll(String? selectedModel) async {
    loading = true;
    notifyListeners();
    try {
      // Ask service for rows (from Supabase)

      final fetched = await _service.fetchMeterData(modelName: selectedModel!);
      if (fetched.isNotEmpty) {
        replaceAll(fetched);
        return _rows;
      }

      // fallback: keep your local sample data
      if (_rows.isNotEmpty) return _rows;

      return _rows;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void replaceAll(List<MeterEntry> items) {
    _rows
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void clear() {
    _rows.clear();
    notifyListeners();
  }
}

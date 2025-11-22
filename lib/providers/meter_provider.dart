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

  Future<List<MeterEntry>> fetchAll() async {
    loading = true;
    notifyListeners();
    try {
      // Ask service for rows (from Supabase)
      final fetched = await _service.fetchMeterData();
      if (fetched.isNotEmpty) {
        replaceAll(fetched);
        return _rows;
      }

      // fallback: keep your local sample data
      if (_rows.isNotEmpty) return _rows;

      await Future.delayed(const Duration(milliseconds: 200));
      final sample = <MeterEntry>[
        MeterEntry(id: 1, lowerValue: 18.526, upperValue: 60.266, lowerCorrection: -0.006, upperCorrection: -0.01, lowerUncertainty: 0.002, upperUncertainty: 0.002, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 2, lowerValue: 60.266, upperValue: 100.008, lowerCorrection: -0.01, upperCorrection: -0.009, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 3, lowerValue: 100.008, upperValue: 138.514, lowerCorrection: -0.009, upperCorrection: -0.008, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 4, lowerValue: 138.514, upperValue: 175.865, lowerCorrection: -0.008, upperCorrection: -0.009, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 5, lowerValue: 175.865, upperValue: 212.061, lowerCorrection: -0.009, upperCorrection: -0.009, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 6, lowerValue: 212.061, upperValue: 247.103, lowerCorrection: -0.009, upperCorrection: -0.012, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 7, lowerValue: 247.103, upperValue: 280.99, lowerCorrection: -0.012, upperCorrection: -0.014, lowerUncertainty: 0.003, upperUncertainty: 0.003, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 8, lowerValue: 280.99, upperValue: 313.72, lowerCorrection: 0.014, upperCorrection: 0.014, lowerUncertainty: 0.1, upperUncertainty: 0.1, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 9, lowerValue: 313.72, upperValue: 345.306, lowerCorrection: 0.014, upperCorrection: 0.022, lowerUncertainty: 0.1, upperUncertainty: 0.1, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 10, lowerValue: 345.306, upperValue: 375.727, lowerCorrection: 0.022, upperCorrection: 0.019, lowerUncertainty: 0.1, upperUncertainty: 0.1, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 11, lowerValue: 375.727, upperValue: 390.497, lowerCorrection: 0.019, upperCorrection: 0.016, lowerUncertainty: 0.1, upperUncertainty: 0.1, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 12, lowerValue: 390.497, upperValue: 3000.18, lowerCorrection: 0.016, upperCorrection: 0.18, lowerUncertainty: 0.1, upperUncertainty: 0.1, meterModel: 'ST-MC6-1-600ohm-I'),
        MeterEntry(id: 13, lowerValue: 3000.18, upperValue: 0, lowerCorrection: 0.18, upperCorrection: 0, lowerUncertainty: 0, upperUncertainty: 0, meterModel: 'ST-MC6-1-600ohm-I'),
      ];

      _rows.addAll(sample);
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

import 'package:flutter/material.dart';
import '../models/meter_entry.dart';

/// A simple provider that holds the meter rows and can fetch them.
/// Replace the fetch implementation with your Supabase call.
class MeterProvider extends ChangeNotifier {
  final List<MeterEntry> _rows = [];
  bool loading = false;

  List<MeterEntry> get rows => List.unmodifiable(_rows);

  /// Replace this with the actual fetch from Supabase service you already have.
  /// For example: return await MySupabaseService.fetchMeterEntries();
  Future<List<MeterEntry>> fetchAll() async {
    loading = true;
    notifyListeners();

    try {
      // TODO: Replace the sample data below with a real network call.
      await Future.delayed(const Duration(milliseconds: 300)); // simulate latency

      // Example: if you already fetched from Supabase use that data instead of building sample.
      // For now we return the provider's stored rows if non-empty, otherwise create sample.
      if (_rows.isNotEmpty) return _rows;

      // ---- SAMPLE rows (remove when using real fetch) ----
      final sample = List.generate(12, (i) {
        return MeterEntry(
          id: i + 1,
          lowerValue: 18.5260 + i, // sample numbers
          upperValue: 60.2660 + i,
          upperCorrection: -0.0100,
          lowerCorrection: -0.0060,
          lowerUncertainty: 0.0020,
          upperUncertainty: 0.0020,
          meterModel: 'ST-MODEL',
        );
      });
      _rows
        ..clear()
        ..addAll(sample);
      // ----------------------------------------------------

      return _rows;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void replaceAll(List<MeterEntry> rows) {
    _rows
      ..clear()
      ..addAll(rows);
    notifyListeners();
  }

  void clear() {
    _rows.clear();
    notifyListeners();
  }
}

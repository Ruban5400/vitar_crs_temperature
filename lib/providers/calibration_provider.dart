import 'package:flutter/foundation.dart';
import '../models/calibration_basic_data.dart';
import '../models/meter_entry.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

  // -------------------------
  // Basic data updates
  // (these are helper methods used by your existing UI)
  void updateField(String fieldName, String value) { /* ... keep as you had ... */
    switch (fieldName) {
      case 'CertificateNo':
        data.certificateNo = value;
        break;
      case 'Instrument':
        data.instrument = value;
        break;
      case 'Make':
        data.make = value;
        break;
      case 'Model':
        data.model = value;
        break;
      case 'SerialNo':
        data.serialNo = value;
        break;
      case 'CustomerName':
        data.customerName = value;
        break;
      case 'CMRNo':
        data.cmrNo = value;
        break;
      case 'DateReceived':
        data.dateReceived = value;
        break;
      case 'DateCalibrated':
        data.dateCalibrated = value;
        break;
      case 'AmbientTempMax':
        data.ambientTempMax = value;
        break;
      case 'AmbientTempMin':
        data.ambientTempMin = value;
        break;
      case 'RHMax':
        data.relativeHumidityMax = value;
        break;
      case 'RHMin':
        data.relativeHumidityMin = value;
        break;
      case 'Thermohygrometer':
        data.thermohygrometer = value;
        break;
      case 'RefMethod':
        data.refMethod = value;
        break;
      case 'CalibratedAt':
        data.calibratedAt = value;
        break;
      case 'Remark':
        data.remark = value;
        break;
      case 'Resolution':
        data.resolution = value;
        break;
    }
    notifyListeners();
  }

  void updateCondition(String which, String value) {
    if (which == 'Received') {
      data.instrumentConditionReceived = value;
    } else {
      data.instrumentConditionReturned = value;
    }
    notifyListeners();
  }

  // Cal point updates
  void updateCalPointSetting(int index, String value) {
    calPoints[index].setting = value;
    notifyListeners();
  }

  void updateRefReading(int pointIndex, int rowIndex, String value) {
    calPoints[pointIndex].refReadings[rowIndex] = value;
    notifyListeners();
  }

  void updateTestReading(int pointIndex, int rowIndex, String value) {
    calPoints[pointIndex].testReadings[rowIndex] = value;
    notifyListeners();
  }

  void updateCalPointRightInfo(int pointIndex, String key, String value) {
    calPoints[pointIndex].rightInfo[key] = value;
    notifyListeners();
  }

  void resetAll() {
    final newBasic = CalibrationBasicData();
    data.certificateNo = newBasic.certificateNo;
    data.instrument = newBasic.instrument;
    data.make = newBasic.make;
    data.model = newBasic.model;
    data.serialNo = newBasic.serialNo;
    data.customerName = newBasic.customerName;
    data.cmrNo = newBasic.cmrNo;
    data.dateReceived = newBasic.dateReceived;
    data.dateCalibrated = newBasic.dateCalibrated;
    data.ambientTempMax = newBasic.ambientTempMax;
    data.ambientTempMin = newBasic.ambientTempMin;
    data.relativeHumidityMax = newBasic.relativeHumidityMax;
    data.relativeHumidityMin = newBasic.relativeHumidityMin;
    data.thermohygrometer = newBasic.thermohygrometer;
    data.refMethod = newBasic.refMethod;
    data.calibratedAt = newBasic.calibratedAt;
    data.remark = newBasic.remark;
    data.instrumentConditionReceived = newBasic.instrumentConditionReceived;
    data.instrumentConditionReturned = newBasic.instrumentConditionReturned;
    data.resolution = newBasic.resolution;

    for (var p in calPoints) {
      p.setting = '';
      for (int i = 0; i < 6; i++) {
        p.refReadings[i] = '';
        p.testReadings[i] = '';
      }
      p.rightInfo.updateAll((key, value) => '');
      p.meterCorrPerRow = List.generate(6, (_) => '');
    }
    notifyListeners();
  }

  Map<String, dynamic> exportAll() => {
    'basic': data.toMap(),
    'calPoints': calPoints.map((c) => c.toMap()).toList(),
  };

  // -------------------------
  // Averaging logic (only computes average of refReadings; doesn't change them)
  double? _safeParseDouble(String? s) {
    if (s == null) return null;
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  double? averageDoubleList(List<double?> values) {
    final valid = values.where((v) => v != null).cast<double>().toList();
    if (valid.isEmpty) return null;
    final sum = valid.reduce((a, b) => a + b);
    return sum / valid.length;
  }

  /// compute & store ONLY averages into rightInfo['Meter Corr.'] (preserves refReadings)
  List<double?> computeAndStoreMeterCorrections() {
    final List<double?> results = [];
    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
      final avg = averageDoubleList(parsed);
      if (avg != null) {
        cp.rightInfo['Meter Corr.'] = avg.toStringAsFixed(8);
      } else {
        cp.rightInfo['Meter Corr.'] = '';
      }
      results.add(avg);
    }
    notifyListeners();
    return results;
  }

  // -------------------------
  // Meter table interpolation logic
  MeterEntry? _findSegmentForMean(double mean, List<MeterEntry> table) {
    if (table.isEmpty) return null;
    for (final row in table) {
      if (mean >= row.lowerValue && mean <= row.upperValue) return row;
    }
    if (mean < table.first.lowerValue) return table.first;
    if (mean > table.last.upperValue) return table.last;
    // fallback
    MeterEntry? best;
    double bestDiff = double.infinity;
    for (final r in table) {
      final mid = (r.lowerValue + r.upperValue) / 2.0;
      final diff = (mid - mean).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = r;
      }
    }
    return best;
  }

  double _interpolateCorrection(double mean, MeterEntry seg) {
    final lv = seg.lowerValue;
    final uv = seg.upperValue;
    final lc = seg.lowerCorrection;
    final uc = seg.upperCorrection;

    if ((uv - lv).abs() < 1e-12) return lc;
    final slope = (uc - lc) / (uv - lv);
    final corr = slope * (mean - lv) + lc;
    return corr;
  }

  /// Public: compute meter correction for each cal point using the meter table
  /// and write the same computed correction into calPoint.meterCorrPerRow (all 6 rows).
  List<double?> calculateMeterCorrections(List<MeterEntry> meterTable) {
    final List<double?> results = [];

    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];

      // parse reference readings safely
      final parsed = cp.refReadings.map((s) {
        if (s == null) return null;
        final t = s.trim();
        if (t.isEmpty) return null;
        return double.tryParse(t);
      }).toList();

      final valid = parsed.where((x) => x != null).cast<double>().toList();
      if (valid.isEmpty) {
        // nothing valid -> clear meterCorr entries
        cp.meterCorrPerRow = List.generate(6, (_) => '');
        results.add(null);
        continue;
      }

      final mean = valid.reduce((a, b) => a + b) / valid.length;

      final seg = _findSegmentForMean(mean, meterTable);
      if (seg == null) {
        cp.meterCorrPerRow = List.generate(6, (_) => '');
        results.add(null);
        continue;
      }

      final corr = _interpolateCorrection(mean, seg);
      final corrStr = corr.toStringAsFixed(4); // format to 4 decimals

      // fill same value for all 6 rows
      cp.meterCorrPerRow = List.generate(6, (_) => corrStr);

      results.add(corr);
    }

    notifyListeners();
    return results;
  }
}

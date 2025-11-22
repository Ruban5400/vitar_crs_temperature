
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../main.dart'; // if you use supabase client from main.dart
import '../models/calibration_basic_data.dart';
import '../models/meter_entry.dart';
import '../models/address.dart';
import '../models/undefined_models.dart';

// lib/providers/calibration_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter/material.dart';


class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

  // ---------------- core setters/getters (unchanged) ----------------
  void updateField(String fieldName, String value) {
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

  String? getFieldValue(String fieldName) {
    switch (fieldName) {
      case 'CertificateNo':
        return data.certificateNo;
      case 'Instrument':
        return data.instrument;
      case 'Make':
        return data.make;
      case 'Model':
        return data.model;
      case 'SerialNo':
        return data.serialNo;
      case 'CustomerName':
        return data.customerName;
      case 'CMRNo':
        return data.cmrNo;
      case 'DateReceived':
        return data.dateReceived;
      case 'DateCalibrated':
        return data.dateCalibrated;
      case 'AmbientTempMax':
        return data.ambientTempMax;
      case 'AmbientTempMin':
        return data.ambientTempMin;
      case 'RHMax':
        return data.relativeHumidityMax;
      case 'RHMin':
        return data.relativeHumidityMin;
      case 'Thermohygrometer':
        return data.thermohygrometer;
      case 'RefMethod':
        return data.refMethod;
      case 'CalibratedAt':
        return data.calibratedAt;
      case 'Remark':
        return data.remark;
      case 'Resolution':
        return data.resolution;
      default:
        return null;
    }
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
    if (index < 0 || index >= calPoints.length) return;
    calPoints[index].setting = value;
    notifyListeners();
  }

  void updateRefReading(int pointIndex, int rowIndex, String value) {
    if (!_validPointRow(pointIndex, rowIndex)) return;
    calPoints[pointIndex].refReadings[rowIndex] = value;
    notifyListeners();
  }

  void updateTestReading(int pointIndex, int rowIndex, String value) {
    if (!_validPointRow(pointIndex, rowIndex)) return;
    calPoints[pointIndex].testReadings[rowIndex] = value;
    notifyListeners();
  }

  void updateCalPointRightInfo(int pointIndex, String key, String value) {
    if (pointIndex < 0 || pointIndex >= calPoints.length) return;
    calPoints[pointIndex].rightInfo[key] = value;
    notifyListeners();
  }

  bool _validPointRow(int pointIndex, int rowIndex) {
    if (pointIndex < 0 || pointIndex >= calPoints.length) return false;
    final p = calPoints[pointIndex];
    return rowIndex >= 0 && rowIndex < (p.refReadings.length);
  }

  void resetAll() {
    data.clear();

    for (var p in calPoints) {
      p.setting = '';
      p.refReadings = List.generate(6, (_) => '');
      p.testReadings = List.generate(6, (_) => '');
      if (p.rightInfo.isNotEmpty) p.rightInfo.updateAll((k, v) => '');
      p.meterCorrPerRow = List.generate(6, (_) => '');
      p.actualRefPerRow = List.generate(6, (_) => '');
    }
    notifyListeners();
  }

  Map<String, dynamic> exportAll() => {
    'basic': data.toMap(),
    'calPoints': calPoints.map((c) => c.toMap()).toList(),
  };

  // ------------------------- helpers -------------------------
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

  List<double?> computeAndStoreMeterCorrections() {
    final List<double?> results = [];
    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
      final avg = averageDoubleList(parsed);
      results.add(avg);
    }
    notifyListeners();
    return results;
  }

  // ------------------------- meter-table helpers (unchanged) -------------------------
  MeterEntry? _findSegmentForMean(double mean, List<MeterEntry> table) {
    if (table.isEmpty) return null;
    for (final row in table) {
      if (mean >= row.lowerValue && mean <= row.upperValue) return row;
    }
    if (mean < table.first.lowerValue) return table.first;
    if (mean > table.last.upperValue) return table.last;
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

  List<double?> calculateMeterCorrections(List<MeterEntry> meterTable) {
    final List<double?> results = [];

    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
      final valid = parsed.where((x) => x != null).cast<double>().toList();
      if (valid.isEmpty) {
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
      final corrStr = corr.toStringAsFixed(4);
      cp.meterCorrPerRow = List.generate(6, (_) => corrStr);
      results.add(corr);
    }


    notifyListeners();
    return results;
  }

  // ------------------------- reference table generation (unchanged) -------------------------
  List<List<double>> generateTableForCalPoint(int index) {
    final cp = calPoints[index];
    if (cp.setting.isEmpty) return [];

    int settingValue = int.tryParse(cp.setting) ?? 0;
    SampleData sample = numericalReferenceData['ST-S6']!;

    List<int> col2 = List.filled(7, 0);
    col2[3] = settingValue;
    for (int i = 2; i >= 0; i--) col2[i] = col2[i + 1] - 1;
    for (int i = 4; i < 7; i++) col2[i] = col2[i - 1] + 1;

    List<double> col1 = [];
    for (int i = 0; i < 7; i++) {
      double AL = col2[i].toDouble();
      double value;
      if (AL < 0) {
        value = 1 +
            sample.row3[0] * (AL / 100) +
            sample.row4[0] * pow(AL / 100, 2) +
            sample.row5[0] * pow(AL / 100, 3) * ((AL / 100) - 1);
      } else {
        value = 1 +
            sample.row3[0] * (AL / 100) +
            sample.row4[0] * pow(AL / 100, 2) +
            0.00E+11 * pow(AL / 100, 3);
      }
      col1.add(value);
    }

    List<double> col3 = col1.sublist(1);
    col3.add(0);
    List<int> col4 = col2.sublist(1);
    col4.add(0);

    List<List<double>> table = [];
    for (int i = 0; i < 7; i++) {
      table.add([col1[i], col2[i].toDouble(), col3[i], col4[i].toDouble()]);
    }
    return table;
  }

  List<String> computeFinalInterpolated(int calIndex, List<double> colX, List<double> colY,
      List<double> colZ, List<double> colAA, List<double> colAB) {
    final List<String> result = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      try {
        final double x = colX[r];
        final double y = colY[r];
        final double z = colZ[r];
        final double aa = colAA[r];
        final double ab = colAB[r];

        final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
        result[r] = interpolated.toStringAsFixed(4);
      } catch (_) {
        result[r] = '';
      }
    }
    return result;
  }

  // ------------------------- therm interpolation (existing) -------------------------
  List<String> computeTherCorrections(int calIndex) {
    debugPrint('>>> computeTherCorrections called for calIndex=$calIndex');
    final cp = calPoints[calIndex];
    final List<double> colX = List.filled(6, double.nan);

    for (int r = 0; r < 6; r++) {
      final refVal = (r < cp.refReadings.length) ? _safeParseDouble(cp.refReadings[r]) : null;
      final meterVal = (r < cp.meterCorrPerRow.length) ? _safeParseDouble(cp.meterCorrPerRow[r]) : null;

      debugPrint('computeTherCorrections: calIndex=$calIndex row=$r refVal=$refVal meterVal=$meterVal');

      if (refVal == null || meterVal == null) {
        debugPrint('  -> skipping row $r because ${refVal == null ? "refVal==null" : ""} ${meterVal == null ? "meterVal==null" : ""}');
        colX[r] = double.nan;
        continue;
      }

      const double factorLow = 100.0479;
      const double factorHigh = 100.0479;
      final thermCorr = (refVal < 100) ? (refVal / factorLow) : (refVal / factorHigh);

      debugPrint('  -> thermCorr (scaled before *100) for row $r = $thermCorr (refVal=$refVal)');
      colX[r] = thermCorr * 100.0;
    }

    final table = generateTableForCalPoint(calIndex);
    if (table.isEmpty) return List.generate(6, (_) => '');

    int _findSegmentIndex(double x) {
      for (int i = 0; i < table.length; i++) {
        final leftX = table[i][0] * 100.0;
        final rightX = table[i][2] * 100.0;
        final minX = leftX <= rightX ? leftX : rightX;
        final maxX = leftX <= rightX ? rightX : leftX;
        if (x >= minX && x <= maxX) return i;
      }
      int best = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < table.length; i++) {
        final leftX = table[i][0] * 100.0;
        final rightX = table[i][2] * 100.0;
        final mid = (leftX + rightX) / 2.0;
        final d = (mid - x).abs();
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }
      return best;
    }

    final List<String> finalResults = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      final x = colX[r];
      if (x.isNaN) {
        finalResults[r] = '';
        continue;
      }

      final segIdx = _findSegmentIndex(x);
      final seg = table[segIdx];

      final double z = seg[0] * 100.0;
      final double y = seg[1];
      final double aa = seg[2] * 100.0;
      final double ab = seg[3];

      try {
        final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
        finalResults[r] = interpolated.toStringAsFixed(4);
      } catch (_) {
        finalResults[r] = '';
      }
    }

    debugPrint('computeTherCorrections => $finalResults');
    return finalResults;
  }

  // ------------------------- NEW: therm-corr extraction helper -------------------------
  /// Return the therm-corrected *scaled* value (the C17-like value, e.g. 90.1828)
  /// Preference order:
  ///  1) check cp.rightInfo for common keys that may contain the therm-corr value
  ///  2) fallback to computing (ref + meterCorr) and scaling by 100
  // ------------------------- NEW: therm-corr extraction helper (FIXED) -------------------------
  /// Return the therm-corrected value in the SAME UNIT as R (e.g. ~90.1828).
  /// Preference order:
  ///  1) check cp.rightInfo for common keys that may contain the therm-corr value
  ///     - if value looks like 90.x, return it (already scaled)
  ///     - if value looks like 0.90, return value * 100
  ///  2) fallback to computing (ref + meterCorr)
  double? _getThermCorrScaledForRow(CalibrationPoint cp, int rowIndex) {
    final possibleKeys = [
      'Ther. Corr.', 'Ther Corr', 'TherCorr',
      'Ref. Ind.', 'Ref Ind.', 'RefInd', 'Ref Indicated'
    ];

    for (final k in possibleKeys) {
      if (cp.rightInfo.containsKey(k)) {
        final s = cp.rightInfo[k]!.trim();
        if (s.isNotEmpty) {
          final v = double.tryParse(s);
          if (v != null) {
            debugPrint('_getThermCorrScaledForRow: found rightInfo[$k]=$v for row=$rowIndex');
            // if already in 90.x range (or >10), assume it's scaled and return as-is
            if (v.abs() > 10.0) return v;
            // otherwise it's likely normalized (0.90...) -> convert to 90.x
            return v * 100.0;
          }
        }
      }
    }

    // fallback: derive from ref + meterCorr (assume ref & meterCorr are already in same unit as R, e.g. 90.x)
    if (rowIndex < cp.refReadings.length && rowIndex < cp.meterCorrPerRow.length) {
      final refStr = cp.refReadings[rowIndex].trim();
      final meterCorrStr = cp.meterCorrPerRow[rowIndex].trim();
      final refVal = double.tryParse(refStr);
      final meterCorrVal = double.tryParse(meterCorrStr);
      debugPrint('_getThermCorrScaledForRow: fallback ref=$refVal meterCorr=$meterCorrVal for row=$rowIndex');
      if (refVal != null && meterCorrVal != null) {
        final refInd = refVal + meterCorrVal;
        // IMPORTANT: do NOT multiply by 100 here — refInd should already be e.g. 90.1828
        return refInd;
      }
    }

    return null;
  }

  // ------------------------- NEW: compute final Actual Ref per cal-point (FIXED units) -------------------------
  void computeActualRefsForCalPoint(int calIndex) {
    if (calIndex < 0 || calIndex >= calPoints.length) return;
    final cp = calPoints[calIndex];

    debugPrint('computeActualRefsForCalPoint: called calIndex=$calIndex setting="${cp.setting}"');

    // --- find an effective setting: prefer cp.setting, fallback to nearest non-empty setting ---
    int effectiveSetting = int.tryParse(cp.setting) ?? 0;
    if (cp.setting.trim().isEmpty) {
      int fallbackIndex = -1;
      int bestDist = 1 << 20;
      for (int j = 0; j < calPoints.length; j++) {
        if (calPoints[j].setting.trim().isNotEmpty) {
          final s = int.tryParse(calPoints[j].setting) ?? 0;
          final d = (j - calIndex).abs();
          if (d < bestDist) {
            bestDist = d;
            fallbackIndex = j;
            effectiveSetting = s;
          }
        }
      }
      if (fallbackIndex != -1) {
        debugPrint(' computeActualRefsForCalPoint: using fallback setting from index=$fallbackIndex => $effectiveSetting');
      } else {
        debugPrint(' computeActualRefsForCalPoint: no setting found anywhere; cannot build table -> clearing actualRefPerRow');
        cp.actualRefPerRow = List.generate(6, (_) => '');
        notifyListeners();
        return;
      }
    }

    // Build the AL sequence locally (7 values) using effectiveSetting
    final List<int> al = List.filled(7, 0);
    al[3] = effectiveSetting;
    for (int i = 2; i >= 0; i--) al[i] = al[i + 1] - 1;
    for (int i = 4; i < 7; i++) al[i] = al[i - 1] + 1;

    // Use the same sample selection as generateTableForCalPoint
    final SampleData sample = numericalReferenceData['ST-S6']!;
    final double R = sample.row1[0];

    // Build the table (7 rows) the same way generateTableForCalPoint does
    List<double> col1 = [];
    for (int i = 0; i < 7; i++) {
      final double AL = al[i].toDouble();
      double value;
      if (AL < 0) {
        value = 1 +
            sample.row3[0] * (AL / 100) +
            sample.row4[0] * pow(AL / 100, 2) +
            sample.row5[0] * pow(AL / 100, 3) * ((AL / 100) - 1);
      } else {
        value = 1 +
            sample.row3[0] * (AL / 100) +
            sample.row4[0] * pow(AL / 100, 2) +
            0.00E+11 * pow(AL / 100, 3);
      }
      col1.add(value);
    }
    // col3 is col1 shifted left by 1, col2 is al, col4 is al shifted
    List<double> col3 = col1.sublist(1)..add(0.0);
    List<double> col2 = al.map((e) => e.toDouble()).toList();
    List<double> col4 = col2.sublist(1)..add(0.0);
    final List<List<double>> table = List.generate(7, (i) => [col1[i], col2[i], col3[i], col4[i]]);

    // Now compute actualRef per row
    final List<String> finalTemps = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      final double? thermScaled = _getThermCorrScaledForRow(cp, r);
      debugPrint(' computeActualRefsForCalPoint: row=$r thermScaled=$thermScaled');
      if (thermScaled == null) {
        finalTemps[r] = '';
        continue;
      }

      // Xnorm = thermScaled / R (thermScaled and R are in same units e.g. ~90.x and ~100.x)
      final double xnorm = thermScaled / R;
      debugPrint('  -> xnorm=$xnorm (thermScaled=$thermScaled R=$R)');

      // find best segment in our locally-built table
      int best = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < table.length; i++) {
        final leftX = table[i][0];
        final rightX = table[i][2];
        final minX = leftX <= rightX ? leftX : rightX;
        final maxX = leftX <= rightX ? rightX : leftX;
        if (xnorm >= minX && xnorm <= maxX) {
          best = i;
          break;
        }
        final mid = (leftX + rightX) / 2.0;
        final d = (mid - xnorm).abs();
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }

      final seg = table[best];
      final double leftX = seg[0];
      final double leftTemp = seg[1];
      final double rightX = seg[2];
      final double rightTemp = seg[3];

      double temp;
      if ((rightX - leftX).abs() < 1e-12) {
        temp = leftTemp;
      } else {
        temp = ((rightTemp - leftTemp) / (rightX - leftX)) * (xnorm - leftX) + leftTemp;
      }

      finalTemps[r] = temp.toStringAsFixed(8);
      debugPrint('  -> row=$r seg=$best leftX=$leftX rightX=$rightX leftT=$leftTemp rightT=$rightTemp => temp=$temp');
    }

    cp.actualRefPerRow = finalTemps;
    notifyListeners();
  }



  // ------------------------- other utilities -------------------------
  List<Address> addresses = [];

  void setAddresses(List<Address> list) {
    addresses = list;
    debugPrint('Loaded addresses: ${addresses.length}');
    notifyListeners();
  }

  Map<String, List<String>> masterOptions = {};

  Future<void> loadMasterOptions() async {
    final res = await supabase.from('ref_master').select().order('value');
    masterOptions.clear();
    for (final row in res) {
      final category = row['category'] as String;
      final value = row['value'] as String;
      if (!masterOptions.containsKey(category)) masterOptions[category] = [];
      masterOptions[category]!.add(value);
    }
    notifyListeners();
  }
}



// actual values partially completed - fetching the rigth side table values
// import 'dart:math';
//
// import 'package:flutter/foundation.dart';
// import '../main.dart';
// import '../models/address.dart';
// import '../models/calibration_basic_data.dart';
// import '../models/meter_entry.dart';
// import '../models/undefined_models.dart';
//
// class CalibrationProvider extends ChangeNotifier {
//   final CalibrationBasicData data = CalibrationBasicData();
//   final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());
//
//   void updateField(String fieldName, String value) {
//     switch (fieldName) {
//       case 'CertificateNo':
//         data.certificateNo = value;
//         break;
//       case 'Instrument':
//         data.instrument = value;
//         break;
//       case 'Make':
//         data.make = value;
//         break;
//       case 'Model':
//         data.model = value;
//         break;
//       case 'SerialNo':
//         data.serialNo = value;
//         break;
//       case 'CustomerName':
//         data.customerName = value;
//         break;
//       case 'CMRNo':
//         data.cmrNo = value;
//         break;
//       case 'DateReceived':
//         data.dateReceived = value;
//         break;
//       case 'DateCalibrated':
//         data.dateCalibrated = value;
//         break;
//       case 'AmbientTempMax':
//         data.ambientTempMax = value;
//         break;
//       case 'AmbientTempMin':
//         data.ambientTempMin = value;
//         break;
//       case 'RHMax':
//         data.relativeHumidityMax = value;
//         break;
//       case 'RHMin':
//         data.relativeHumidityMin = value;
//         break;
//       case 'Thermohygrometer':
//         data.thermohygrometer = value;
//         break;
//       case 'RefMethod':
//         data.refMethod = value;
//         break;
//       case 'CalibratedAt':
//         data.calibratedAt = value;
//         break;
//       case 'Remark':
//         data.remark = value;
//         break;
//       case 'Resolution':
//         data.resolution = value;
//         break;
//     }
//     notifyListeners();
//   }
//
//   String? getFieldValue(String fieldName) {
//     switch (fieldName) {
//       case 'CertificateNo':
//         return data.certificateNo;
//       case 'Instrument':
//         return data.instrument;
//       case 'Make':
//         return data.make;
//       case 'Model':
//         return data.model;
//       case 'SerialNo':
//         return data.serialNo;
//       case 'CustomerName':
//         return data.customerName;
//       case 'CMRNo':
//         return data.cmrNo;
//       case 'DateReceived':
//         return data.dateReceived;
//       case 'DateCalibrated':
//         return data.dateCalibrated;
//       case 'AmbientTempMax':
//         return data.ambientTempMax;
//       case 'AmbientTempMin':
//         return data.ambientTempMin;
//       case 'RHMax':
//         return data.relativeHumidityMax;
//       case 'RHMin':
//         return data.relativeHumidityMin;
//       case 'Thermohygrometer':
//         return data.thermohygrometer;
//       case 'RefMethod':
//         return data.refMethod;
//       case 'CalibratedAt':
//         return data.calibratedAt;
//       case 'Remark':
//         return data.remark;
//       case 'Resolution':
//         return data.resolution;
//       default:
//         return null;
//     }
//   }
//
//   void updateCondition(String which, String value) {
//     if (which == 'Received') {
//       data.instrumentConditionReceived = value;
//     } else {
//       data.instrumentConditionReturned = value;
//     }
//     notifyListeners();
//   }
//
//   // Cal point updates
//   void updateCalPointSetting(int index, String value) {
//     if (index < 0 || index >= calPoints.length) return;
//     calPoints[index].setting = value;
//     notifyListeners();
//   }
//
//   void updateRefReading(int pointIndex, int rowIndex, String value) {
//     if (!_validPointRow(pointIndex, rowIndex)) return;
//     calPoints[pointIndex].refReadings[rowIndex] = value;
//     notifyListeners();
//   }
//
//   void updateTestReading(int pointIndex, int rowIndex, String value) {
//     if (!_validPointRow(pointIndex, rowIndex)) return;
//     calPoints[pointIndex].testReadings[rowIndex] = value;
//     notifyListeners();
//   }
//
//   void updateCalPointRightInfo(int pointIndex, String key, String value) {
//     if (pointIndex < 0 || pointIndex >= calPoints.length) return;
//     calPoints[pointIndex].rightInfo[key] = value;
//     notifyListeners();
//   }
//
//   bool _validPointRow(int pointIndex, int rowIndex) {
//     if (pointIndex < 0 || pointIndex >= calPoints.length) return false;
//     final p = calPoints[pointIndex];
//     return rowIndex >= 0 && rowIndex < (p.refReadings.length);
//   }
//
//   void resetAll() {
//     data.clear();
//
//     for (var p in calPoints) {
//       p.setting = '';
//       // ensure lists exist and have length 6
//       p.refReadings = List.generate(6, (_) => '');
//       p.testReadings = List.generate(6, (_) => '');
//       // clear rightInfo values but keep keys if needed
//       if (p.rightInfo.isNotEmpty) {
//         p.rightInfo.updateAll((key, value) => '');
//       }
//       p.meterCorrPerRow = List.generate(6, (_) => '');
//       p.actualRefPerRow = List.generate(6, (_) => '');
//     }
//     notifyListeners();
//   }
//
//   Map<String, dynamic> exportAll() => {
//     'basic': data.toMap(),
//     'calPoints': calPoints.map((c) => c.toMap()).toList(),
//   };
//
//   // -------------------------
//   // Averaging logic (only computes average of refReadings; doesn't change them)
//   double? _safeParseDouble(String? s) {
//     if (s == null) return null;
//     final cleaned = s.trim();
//     if (cleaned.isEmpty) return null;
//     return double.tryParse(cleaned);
//   }
//
//   double? averageDoubleList(List<double?> values) {
//     final valid = values.where((v) => v != null).cast<double>().toList();
//     if (valid.isEmpty) return null;
//     final sum = valid.reduce((a, b) => a + b);
//     return sum / valid.length;
//   }
//
//   /// compute & store ONLY averages into rightInfo['Meter Corr.'] (preserves refReadings)
//   List<double?> computeAndStoreMeterCorrections() {
//     final List<double?> results = [];
//     for (var i = 0; i < calPoints.length; i++) {
//       final cp = calPoints[i];
//       // Use _safeParseDouble to tolerate '', null and spaces
//       final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
//       final avg = averageDoubleList(parsed);
//       // if you want to store into rightInfo uncomment below:
//       // if (avg != null) {
//       //   cp.rightInfo['Meter Corr.'] = avg.toStringAsFixed(8);
//       // } else {
//       //   cp.rightInfo['Meter Corr.'] = '';
//       // }
//       results.add(avg);
//     }
//     notifyListeners();
//     return results;
//   }
//
//   // -------------------------
//   // Meter table interpolation logic
//   MeterEntry? _findSegmentForMean(double mean, List<MeterEntry> table) {
//     if (table.isEmpty) return null;
//     for (final row in table) {
//       if (mean >= row.lowerValue && mean <= row.upperValue) return row;
//     }
//     if (mean < table.first.lowerValue) return table.first;
//     if (mean > table.last.upperValue) return table.last;
//     // fallback: choose nearest midpoint
//     MeterEntry? best;
//     double bestDiff = double.infinity;
//     for (final r in table) {
//       final mid = (r.lowerValue + r.upperValue) / 2.0;
//       final diff = (mid - mean).abs();
//       if (diff < bestDiff) {
//         bestDiff = diff;
//         best = r;
//       }
//     }
//     return best;
//   }
//
//   double _interpolateCorrection(double mean, MeterEntry seg) {
//     final lv = seg.lowerValue;
//     final uv = seg.upperValue;
//     final lc = seg.lowerCorrection;
//     final uc = seg.upperCorrection;
//
//     if ((uv - lv).abs() < 1e-12) return lc;
//     final slope = (uc - lc) / (uv - lv);
//     final corr = slope * (mean - lv) + lc;
//     return corr;
//   }
//
//   /// Public: compute meter correction for each cal point using the meter table
//   /// and write the same computed correction into calPoint.meterCorrPerRow (all 6 rows).
//   List<double?> calculateMeterCorrections(List<MeterEntry> meterTable) {
//     final List<double?> results = [];
//
//     for (var i = 0; i < calPoints.length; i++) {
//       final cp = calPoints[i];
//
//       // parse reference readings safely using _safeParseDouble
//       final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
//
//       final valid = parsed.where((x) => x != null).cast<double>().toList();
//       if (valid.isEmpty) {
//         // nothing valid -> clear meterCorr entries
//         cp.meterCorrPerRow = List.generate(6, (_) => '');
//         results.add(null);
//         continue;
//       }
//
//       final mean = valid.reduce((a, b) => a + b) / valid.length;
//
//       final seg = _findSegmentForMean(mean, meterTable);
//       if (seg == null) {
//         cp.meterCorrPerRow = List.generate(6, (_) => '');
//         results.add(null);
//         continue;
//       }
//
//       final corr = _interpolateCorrection(mean, seg);
//       final corrStr = corr.toStringAsFixed(4); // format to 4 decimals
//
//       // fill same value for all 6 rows
//       cp.meterCorrPerRow = List.generate(6, (_) => corrStr);
//
//       results.add(corr);
//     }
//
//     notifyListeners();
//     return results;
//   }
//
//   List<List<double>> generateTableForCalPoint(int index) {
//     final cp = calPoints[index];
//     if (cp.setting.isEmpty) return [];
//
//     int settingValue = int.tryParse(cp.setting) ?? 0;
//
//     // Choose sample based on requirement
//     SampleData sample = numericalReferenceData['ST-S5']!;
//
//     // Step 1: Create 2nd column
//     List<int> col2 = List.filled(7, 0);
//     col2[3] = settingValue; // middle row
//     for (int i = 2; i >= 0; i--) col2[i] = col2[i + 1] - 1;
//     for (int i = 4; i < 7; i++) col2[i] = col2[i - 1] + 1;
//
//     // Step 2: Calculate 1st column using the formula
//     List<double> col1 = [];
//     for (int i = 0; i < 7; i++) {
//       double AL = col2[i].toDouble();
//       double value;
//       if (AL < 0) {
//         value = 1 +
//             sample.row3[0] * (AL / 100) +
//             sample.row4[0] * pow(AL / 100, 2) +
//             sample.row5[0] * pow(AL / 100, 3) * ((AL / 100) - 1);
//       } else {
//         value = 1 +
//             sample.row3[0] * (AL / 100) +
//             sample.row4[0] * pow(AL / 100, 2) +
//             0.00E+11 * pow(AL / 100, 3);
//       }
//       col1.add(value);
//     }
//
//     // Step 3: 3rd and 4th columns are just col1 and col2 shifted
//     List<double> col3 = col1.sublist(1);
//     col3.add(0);
//     List<int> col4 = col2.sublist(1);
//     col4.add(0);
//
//     // Combine into 7x4 table
//     List<List<double>> table = [];
//     for (int i = 0; i < 7; i++) {
//       table.add([col1[i], col2[i].toDouble(), col3[i], col4[i].toDouble()]);
//     }
//     return table;
//   }
//
//   List<String> computeFinalInterpolated(int calIndex, List<double> colX, List<double> colY, List<double> colZ, List<double> colAA, List<double> colAB) {
//     final List<String> result = List.generate(6, (_) => '');
//     for (int r = 0; r < 6; r++) {
//       try {
//         final double x = colX[r];
//         final double y = colY[r];
//         final double z = colZ[r];
//         final double aa = colAA[r];
//         final double ab = colAB[r];
//
//         final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
//         result[r] = interpolated.toStringAsFixed(4);
//       } catch (_) {
//         result[r] = '';
//       }
//     }
//     return result;
//   }
//
//   List<String> computeThermCorrections(int calIndex) {
//     final cp = calPoints[calIndex];
//
//     // --- Step A: compute therm-corrected X values (safe parsing) ---
//     final List<double> colX = List.filled(6, double.nan);
//
//     for (int r = 0; r < 6; r++) {
//       final refVal = (r < cp.refReadings.length) ? _safeParseDouble(cp.refReadings[r]) : null;
//       final meterVal = (r < cp.meterCorrPerRow.length) ? _safeParseDouble(cp.meterCorrPerRow[r]) : null;
//
//       if (refVal == null || meterVal == null) {
//         colX[r] = double.nan;
//         continue;
//       }
//
//       const double factorLow = 100.0479;
//       const double factorHigh = 100.0479;
//       final thermCorr = (refVal < 100) ? (refVal / factorLow) : (refVal / factorHigh);
//
//       // SCALE to match the table units (your sample/output uses values ~90.x not 0.90x)
//       colX[r] = thermCorr * 100.0;
//     }
//
//     // --- Step B: build the 7x4 reference table for this cal point ---
//     final table = generateTableForCalPoint(calIndex);
//     if (table.isEmpty) return List.generate(6, (_) => '');
//
//     // Helper: find segment index i such that x is between leftX and rightX
//     int _findSegmentIndex(double x) {
//       for (int i = 0; i < table.length; i++) {
//         // table row layout: [col1LeftX, col2LeftTemp, col3RightX, col4RightTemp]
//         final leftX = table[i][0] * 100.0;   // scale table Xs too
//         final rightX = table[i][2] * 100.0;  // scale table Xs too
//
//         final minX = leftX <= rightX ? leftX : rightX;
//         final maxX = leftX <= rightX ? rightX : leftX;
//         if (x >= minX && x <= maxX) return i;
//       }
//       // not contained: choose nearest segment by midpoint distance
//       int best = 0;
//       double bestDist = double.infinity;
//       for (int i = 0; i < table.length; i++) {
//         final leftX = table[i][0] * 100.0;
//         final rightX = table[i][2] * 100.0;
//         final mid = (leftX + rightX) / 2.0;
//         final d = (mid - x).abs();
//         if (d < bestDist) {
//           bestDist = d;
//           best = i;
//         }
//       }
//       return best;
//     }
//
//     // --- Step C: per-row build interpolation inputs and compute final values ---
//     final List<String> finalResults = List.generate(6, (_) => '');
//     for (int r = 0; r < 6; r++) {
//       final x = colX[r];
//       if (x.isNaN) {
//         finalResults[r] = '';
//         continue;
//       }
//
//       final segIdx = _findSegmentIndex(x);
//       final seg = table[segIdx];
//
//       // seg: [leftX (col1), leftTemp (col2), rightX (col3), rightTemp (col4)]
//       final double z = seg[0] * 100.0;   // left X (scale)
//       final double y = seg[1];          // left temperature (e.g. -26)
//       final double aa = seg[2] * 100.0; // right X (scale)
//       final double ab = seg[3];         // right temperature (e.g. -25)
//
//       // interpolation formula ((AB - Z) / (AA - Y)) * (X - Y) + Z
//       try {
//         final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
//         finalResults[r] = interpolated.toStringAsFixed(4); // round to 4 decimals
//       } catch (_) {
//         finalResults[r] = '';
//       }
//     }
//
//     debugPrint('computeThermCorrections => $finalResults');
//     return finalResults;
//   }
//
//   // -------------------------
//   // NEW: compute Actual Ref (left-column) from master coefficients
//   /// Compute the left-column (Actual Ref) values for given AL temps
//   List<double> computeActualRefForALs({
//     required double A,
//     required double B,
//     required double C,
//     required List<int> alList, // e.g. [-28, -27, -26, -25, -24, -23, -22]
//   }) {
//     final List<double> results = [];
//     for (final al in alList) {
//       final x = al / 100.0;
//       double value;
//       if (al < 0) {
//         // negative branch (matches your IF(AL<0, ... ) formula)
//         value = 1.0 + A * x + B * (x * x) + C * (x * x * x) * (x - 1.0);
//       } else {
//         // positive branch — keep same pattern; replace coefficients if you have them
//         value = 1.0 + A * x + B * (x * x) + 0.00E+11 * (x * x * x);
//       }
//       results.add(value);
//     }
//     print('5400 -=-=-= ${results}');
//     return results;
//   }
//
//   /// Build AL list for a cal-point (7 values) and compute + store the first 6
//   void computeActualRefsForCalPoint(int calIndex) {
//     if (calIndex < 0 || calIndex >= calPoints.length) return;
//     final cp = calPoints[calIndex];
//
//     // Build AL sequence (7 values): middle = setting, neighbours +/-1
//     final int settingValue = int.tryParse(cp.setting) ?? 0;
//     final List<int> al = List.filled(7, 0);
//     al[3] = settingValue;
//     for (int i = 2; i >= 0; i--) al[i] = al[i + 1] - 1;
//     for (int i = 4; i < 7; i++) al[i] = al[i - 1] + 1;
//
//     // Choose the sample coefficients used in generateTableForCalPoint.
//     // If you use dynamic sample keys per cal-point, change this to pick that sample.
//     final SampleData sample = numericalReferenceData['ST-S5']!;
//     final double A = sample.row3[0];
//     final double B = sample.row4[0];
//     final double C = sample.row5[0];
//
//     final List<double> computed = computeActualRefForALs(A: A, B: B, C: C, alList: al);
//
//     // Store first 6 rows formatted to 4 decimal places (UI currently shows 4 dp)
//     cp.actualRefPerRow = List.generate(6, (i) {
//       if (i < computed.length) return computed[i].toStringAsFixed(4);
//       return '';
//     });
//
//     notifyListeners();
//   }
//
//   // for adding address from masters
//   List<Address> addresses = [];
//
//   void setAddresses(List<Address> list) {
//     addresses = list;
//     debugPrint('Loaded addresses: ${addresses.length}');
//     notifyListeners();
//   }
//
//   Map<String, List<String>> masterOptions = {};
//
//   Future<void> loadMasterOptions() async {
//     final res = await supabase.from('ref_master').select().order('value');
//
//     masterOptions.clear();
//
//     for (final row in res) {
//       final category = row['category'] as String;
//       final value = row['value'] as String;
//
//       if (!masterOptions.containsKey(category)) {
//         masterOptions[category] = [];
//       }
//       masterOptions[category]!.add(value);
//     }
//
//     notifyListeners();
//   }
// }

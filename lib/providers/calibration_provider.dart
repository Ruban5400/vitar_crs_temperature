// new code worked on 07/11/25
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../models/calibration_basic_data.dart';
import '../models/meter_entry.dart';
import '../models/undefined_models.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

  // -------------------------
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
    debugPrint('Resetting calibration provider (resetAll)');
    data.clear();

    for (var p in calPoints) {
      p.setting = '';
      // ensure lists exist and have length 6
      p.refReadings = List.generate(6, (_) => '');
      p.testReadings = List.generate(6, (_) => '');
      // clear rightInfo values but keep keys if needed
      if (p.rightInfo.isNotEmpty) {
        p.rightInfo.updateAll((key, value) => '');
      }
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
      // Use _safeParseDouble to tolerate '', null and spaces
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
    // fallback: choose nearest midpoint
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

      // parse reference readings safely using _safeParseDouble
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();

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

  List<List<double>> generateTableForCalPoint(int index) {
    final cp = calPoints[index];
    if (cp.setting.isEmpty) return [];

    int settingValue = int.tryParse(cp.setting) ?? 0;

    // Choose sample based on requirement
    SampleData sample = numericalReferenceData['ST-S5']!;

    // Step 1: Create 2nd column
    List<int> col2 = List.filled(7, 0);
    col2[3] = settingValue; // middle row
    for (int i = 2; i >= 0; i--) col2[i] = col2[i + 1] - 1;
    for (int i = 4; i < 7; i++) col2[i] = col2[i - 1] + 1;

    // Step 2: Calculate 1st column using the formula
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

    // Step 3: 3rd and 4th columns are just col1 and col2 shifted
    List<double> col3 = col1.sublist(1);
    col3.add(0);
    List<int> col4 = col2.sublist(1);
    col4.add(0);

    // Combine into 7x4 table
    List<List<double>> table = [];
    for (int i = 0; i < 7; i++) {
      table.add([col1[i], col2[i].toDouble(), col3[i], col4[i].toDouble()]);
    }
    return table;
  }

  List<String> computeFinalInterpolated(int calIndex, List<double> colX, List<double> colY, List<double> colZ, List<double> colAA, List<double> colAB) {
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

  List<String> computeThermCorrections(int calIndex) {
    final cp = calPoints[calIndex];

    // --- Step A: compute therm-corrected X values (safe parsing) ---
    final List<double> colX = List.filled(6, double.nan);

    for (int r = 0; r < 6; r++) {
      final refVal = (r < cp.refReadings.length) ? _safeParseDouble(cp.refReadings[r]) : null;
      final meterVal = (r < cp.meterCorrPerRow.length) ? _safeParseDouble(cp.meterCorrPerRow[r]) : null;

      if (refVal == null || meterVal == null) {
        colX[r] = double.nan;
        continue;
      }

      const double factorLow = 100.0479;
      const double factorHigh = 100.0479;
      final thermCorr = (refVal < 100) ? (refVal / factorLow) : (refVal / factorHigh);

      // SCALE to match the table units (your sample/output uses values ~90.x not 0.90x)
      colX[r] = thermCorr * 100.0;
    }

    // --- Step B: build the 7x4 reference table for this cal point ---
    final table = generateTableForCalPoint(calIndex);
    if (table.isEmpty) return List.generate(6, (_) => '');

    // Helper: find segment index i such that x is between leftX and rightX
    int _findSegmentIndex(double x) {
      for (int i = 0; i < table.length; i++) {
        // table row layout: [col1LeftX, col2LeftTemp, col3RightX, col4RightTemp]
        final leftX = table[i][0] * 100.0;   // scale table Xs too
        final rightX = table[i][2] * 100.0;  // scale table Xs too

        final minX = leftX <= rightX ? leftX : rightX;
        final maxX = leftX <= rightX ? rightX : leftX;
        if (x >= minX && x <= maxX) return i;
      }
      // not contained: choose nearest segment by midpoint distance
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

    // --- Step C: per-row build interpolation inputs and compute final values ---
    final List<String> finalResults = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      final x = colX[r];
      if (x.isNaN) {
        finalResults[r] = '';
        continue;
      }

      final segIdx = _findSegmentIndex(x);
      final seg = table[segIdx];

      // seg: [leftX (col1), leftTemp (col2), rightX (col3), rightTemp (col4)]
      final double z = seg[0] * 100.0;   // left X (scale)
      final double y = seg[1];          // left temperature (e.g. -26)
      final double aa = seg[2] * 100.0; // right X (scale)
      final double ab = seg[3];         // right temperature (e.g. -25)

      // interpolation formula ((AB - Z) / (AA - Y)) * (X - Y) + Z
      try {
        final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
        finalResults[r] = interpolated.toStringAsFixed(4); // round to 4 decimals
      } catch (_) {
        finalResults[r] = '';
      }
    }

    debugPrint('computeThermCorrections => $finalResults');
    return finalResults;
  }

  // for adding address from masters
  // List<Address> addresses = [];
  // void loadAddressesFromJson(List<Map<String, dynamic>> list) {
  //   addresses = list.map((m) => Address.fromJson(m)).toList();
  //   debugPrint('Loaded addresses: ${addresses.length}');
  //   notifyListeners();
  // }
  List<Address> addresses = [];

  void setAddresses(List<Address> list) {
    addresses = list;
    debugPrint('Loaded addresses: ${addresses.length}');
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


}


// old code
// import 'dart:math';
//
// import 'package:flutter/foundation.dart';
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
//     calPoints[index].setting = value;
//     notifyListeners();
//   }
//
//   void updateRefReading(int pointIndex, int rowIndex, String value) {
//     calPoints[pointIndex].refReadings[rowIndex] = value;
//     notifyListeners();
//   }
//
//   void updateTestReading(int pointIndex, int rowIndex, String value) {
//     calPoints[pointIndex].testReadings[rowIndex] = value;
//     notifyListeners();
//   }
//
//   void updateCalPointRightInfo(int pointIndex, String key, String value) {
//     calPoints[pointIndex].rightInfo[key] = value;
//     notifyListeners();
//   }
//
//   void resetAll() {
//     print('5400');
//     data.clear();
//
//     for (var p in calPoints) {
//       p.setting = '';
//       for (int i = 0; i < 6; i++) {
//         p.refReadings[i] = '';
//         p.testReadings[i] = '';
//       }
//       p.rightInfo.updateAll((key, value) => '');
//       p.meterCorrPerRow = List.generate(6, (_) => '');
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
//       final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
//       final avg = averageDoubleList(parsed);
//       if (avg != null) {
//         cp.rightInfo['Meter Corr.'] = avg.toStringAsFixed(8);
//       } else {
//         cp.rightInfo['Meter Corr.'] = '';
//       }
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
//     // fallback
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
//       // parse reference readings safely
//       final parsed = cp.refReadings.map((s) {
//         if (s == null) return null;
//         final t = s.trim();
//         if (t.isEmpty) return null;
//         return double.tryParse(t);
//       }).toList();
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
//
//     notifyListeners();
//     return results;
//   }
//
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
//         print('Ruby -=-=>>> ab = $ab, z = $z, aa = $aa, y = $y, x = $x');
//         print(
//             'Ruby ab = ${ab.toStringAsFixed(4)}, z = ${z.toStringAsFixed(4)}, aa = ${aa.toStringAsFixed(4)}, y = ${y.toStringAsFixed(4)}, x = ${x.toStringAsFixed(4)}');
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
//     // --- Step A: compute therm-corrected X values (same as before) ---
//     // But NOTE: multiply by 100 so units match the generateTableForCalPoint output
//     final List<double> colX = List.filled(6, double.nan);
//     for (int r = 0; r < 6; r++) {
//       final refStr = cp.refReadings[r].trim();
//       final meterCorrStr = cp.meterCorrPerRow[r].trim();
//
//       final refVal = double.tryParse(refStr);
//       final meterVal = double.tryParse(meterCorrStr);
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
//       // debug print - rounded to 4 decimals
//       debugPrint('Ruby -=-=> ab=${ab.toStringAsFixed(4)}, z=${z.toStringAsFixed(4)}, aa=${aa.toStringAsFixed(4)}, y=${y.toStringAsFixed(4)}, x=${x.toStringAsFixed(4)}');
//
//       // interpolation formula ((AB - Z) / (AA - Y)) * (X - Y) + Z
//       // Note: we keep the same structure you had, but pass numeric values
//       try {
//         final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
//         finalResults[r] = interpolated.toStringAsFixed(4); // round to 4 decimals
//       } catch (_) {
//         finalResults[r] = '';
//       }
//     }
//
//     debugPrint('5400 -=-=-=- >>>> $finalResults');
//     return finalResults;
//   }
//
//   // for adding address from masters
//   List<Address> addresses = [];
//   void loadAddressesFromJson(List<Map<String, dynamic>> list) {
//     addresses = list.map((m) => Address.fromJson(m)).toList();
//     print('5400 -=-=-=-= $addresses');
//     notifyListeners();
//   }
//
// }

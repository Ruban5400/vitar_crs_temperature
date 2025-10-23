import 'dart:math';

import 'package:flutter/foundation.dart';
import '../models/calibration_basic_data.dart';
import '../models/meter_entry.dart';
import '../models/undefined_models.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

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

  // values mismatch === Ruby -=-=>>> ab = -25, z = 0, aa = -0.0092, y = 0, x = 0.9014881871583511
  // List<String> computeThermCorrections(int calIndex) {
  //   final cp = calPoints[calIndex];
  //
  //   // Step 1: Compute therm corrections (from your existing logic)
  //   final thermCorrections = <double>[];
  //   for (int r = 0; r < 6; r++) {
  //     final refStr = cp.refReadings[r].trim();
  //     final meterCorrStr = cp.meterCorrPerRow[r].trim();
  //
  //     final refVal = double.tryParse(refStr);
  //     final meterVal = double.tryParse(meterCorrStr);
  //
  //     if (refVal == null || meterVal == null) {
  //       thermCorrections.add(0.0); // placeholder
  //       continue;
  //     }
  //
  //     const double factorLow = 100.0479;
  //     const double factorHigh = 100.0479;
  //
  //     double thermCorr = refVal < 100 ? refVal / factorLow : refVal / factorHigh;
  //     thermCorrections.add(thermCorr);
  //   }
  //
  //   // Step 2: Prepare columns for interpolation
  //   final colX = thermCorrections; // X = therm corrections
  //   final colY = List.generate(6, (_) => 0.0); // replace with actual Y column if needed
  //   final colZ = List.generate(6, (_) => 0.0); // replace with actual Z column if needed
  //   final colAA = cp.meterCorrPerRow.map((s) => double.tryParse(s) ?? 0).toList();
  //   final colAB = List.generate(6, (_) => -25.0); // replace with actual AB column values
  //
  //   // Step 3: Compute final interpolated values
  //   final finalColumn = computeFinalInterpolated(calIndex, colX, colY, colZ, colAA, colAB);
  //
  //   print('Actual Ref Column: $finalColumn');
  //   return finalColumn; // This is your Actual Ref values
  // }
  //
  //
  // /// Computes final interpolated value for the "last column" in your table
  // /// formula: ((AB-Z)/(AA-Y))*(X-Y)+Z
  List<String> computeFinalInterpolated(int calIndex, List<double> colX, List<double> colY, List<double> colZ, List<double> colAA, List<double> colAB) {
    final List<String> result = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      try {
        final double x = colX[r];
        final double y = colY[r];
        final double z = colZ[r];
        final double aa = colAA[r];
        final double ab = colAB[r];
        print('Ruby -=-=>>> ab = $ab, z = $z, aa = $aa, y = $y, x = $x');
        print(
            'Ruby ab = ${ab.toStringAsFixed(4)}, z = ${z.toStringAsFixed(4)}, aa = ${aa.toStringAsFixed(4)}, y = ${y.toStringAsFixed(4)}, x = ${x.toStringAsFixed(4)}');

        final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
        result[r] = interpolated.toStringAsFixed(4);
      } catch (_) {
        result[r] = '';
      }
    }
    return result;
  }

  // List<String> computeThermCorrections(int calIndex) {
  //   final cp = calPoints[calIndex];
  //
  //   // --- Step A: compute therm-corrected X values (same as before) ---
  //   final List<double> colX = List.filled(6, double.nan);
  //   for (int r = 0; r < 6; r++) {
  //     final refStr = cp.refReadings[r].trim();
  //     final meterCorrStr = cp.meterCorrPerRow[r].trim();
  //
  //     final refVal = double.tryParse(refStr);
  //     final meterVal = double.tryParse(meterCorrStr);
  //
  //     if (refVal == null || meterVal == null) {
  //       colX[r] = double.nan;
  //       continue;
  //     }
  //
  //     const double factorLow = 100.0479;
  //     const double factorHigh = 100.0479;
  //     final thermCorr = (refVal < 100) ? (refVal / factorLow) : (refVal / factorHigh);
  //     colX[r] = thermCorr;
  //   }
  //
  //   // --- Step B: build the 7x4 reference table for this cal point ---
  //   // generateTableForCalPoint returns List<List<double>> where each row is
  //   // [col1, col2, col3, col4] matching your earlier logic.
  //   final table = generateTableForCalPoint(calIndex);
  //   if (table.isEmpty) {
  //     // no table -> return blanks
  //     return List.generate(6, (_) => '');
  //   }
  //
  //   // helper: find segment index i such that x is between table[i][0] and table[i][2]
  //   int _findSegmentIndex(double x) {
  //     // tolerant search: prefer exact containment, else nearest segment
  //     for (int i = 0; i < table.length; i++) {
  //       final leftX = table[i][0];
  //       final rightX = table[i][2];
  //       // handle ordering: leftX may be <= or >= rightX depending on data, so normalize:
  //       final minX = leftX <= rightX ? leftX : rightX;
  //       final maxX = leftX <= rightX ? rightX : leftX;
  //       if (x >= minX && x <= maxX) return i;
  //     }
  //     // if not contained, pick closest by distance to mid of each segment
  //     int best = 0;
  //     double bestDist = double.infinity;
  //     for (int i = 0; i < table.length; i++) {
  //       final leftX = table[i][0];
  //       final rightX = table[i][2];
  //       final mid = (leftX + rightX) / 2.0;
  //       final d = (mid - x).abs();
  //       if (d < bestDist) {
  //         bestDist = d;
  //         best = i;
  //       }
  //     }
  //     return best;
  //   }
  //
  //   // --- Step C: prepare the column arrays for computeFinalInterpolated ---
  //   final colY = List<double>.filled(6, 0.0);  // left temperatures
  //   final colZ = List<double>.filled(6, 0.0);  // left X values
  //   final colAA = List<double>.filled(6, 0.0); // right X values
  //   final colAB = List<double>.filled(6, 0.0); // right temperatures
  //
  //   for (int r = 0; r < 6; r++) {
  //     final x = colX[r];
  //     if (x.isNaN) {
  //       // leave default zeros -> will produce '' in computeFinalInterpolated try/catch
  //       colY[r] = 0.0;
  //       colZ[r] = 0.0;
  //       colAA[r] = 0.0;
  //       colAB[r] = 0.0;
  //       continue;
  //     }
  //
  //     final segIndex = _findSegmentIndex(x);
  //     final seg = table[segIndex];
  //     // seg layout: [col1 (left X), col2 (left temp), col3 (right X), col4 (right temp)]
  //     final leftX = seg[0];
  //     final leftTemp = seg[1];
  //     final rightX = seg[2];
  //     final rightTemp = seg[3];
  //
  //     colZ[r] = leftX;
  //     colY[r] = leftTemp;
  //     colAA[r] = rightX;
  //     colAB[r] = rightTemp;
  //   }
  //
  //   // --- Step D: compute final interpolated values using your existing function ---
  //   final finalColumn = computeFinalInterpolated(calIndex, colX, colY, colZ, colAA, colAB);
  //
  //   return finalColumn;
  // }
  List<String> computeThermCorrections(int calIndex) {
    final cp = calPoints[calIndex];

    // --- Step A: compute therm-corrected X values (same as before) ---
    // But NOTE: multiply by 100 so units match the generateTableForCalPoint output
    final List<double> colX = List.filled(6, double.nan);
    for (int r = 0; r < 6; r++) {
      final refStr = cp.refReadings[r].trim();
      final meterCorrStr = cp.meterCorrPerRow[r].trim();

      final refVal = double.tryParse(refStr);
      final meterVal = double.tryParse(meterCorrStr);

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

      // debug print - rounded to 4 decimals
      debugPrint('Ruby -=-=> ab=${ab.toStringAsFixed(4)}, z=${z.toStringAsFixed(4)}, aa=${aa.toStringAsFixed(4)}, y=${y.toStringAsFixed(4)}, x=${x.toStringAsFixed(4)}');

      // interpolation formula ((AB - Z) / (AA - Y)) * (X - Y) + Z
      // Note: we keep the same structure you had, but pass numeric values
      try {
        final interpolated = ((ab - z) / (aa - y)) * (x - y) + z;
        finalResults[r] = interpolated.toStringAsFixed(4); // round to 4 decimals
      } catch (_) {
        finalResults[r] = '';
      }
    }

    debugPrint('5400 -=-=-=- >>>> $finalResults');
    return finalResults;
  }


}

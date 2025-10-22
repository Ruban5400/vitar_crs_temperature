import 'package:flutter/foundation.dart';
import '../models/calibration_basic_data.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(
    8,
    (_) => CalibrationPoint(),
  );

  // Basic data updates
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
    }
    notifyListeners();
  }

  Map<String, dynamic> exportAll() => {
    'basic': data.toMap(),
    'calPoints': calPoints.map((c) => c.toMap()).toList(),
  };
  /// For each cal point, compute the average of the 6 reference readings
  /// (parsing string values) and save it into calPoint.rightInfo['Meter Corr.']
  /// Returns the list of computed averages (null allowed if a cal point had no valid readings).
  List<double?> computeAndStoreMeterCorrections() {
    final List<double?> results = [];
    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];

      // parse all refReadings to double? safely
      final parsed = cp.refReadings.map((s) {
        if (s == null) return null;
        final x = double.tryParse(s.trim());
        return x;
      }).toList();

      final avg = averageDoubleList(parsed);
      print('5400v-=-=-= >>> $avg');

      // store as string with desired precision for UI/export
      if (avg != null) {
        cp.rightInfo['Meter Corr.'] = avg.toStringAsFixed(8); // choose precision you want
      } else {
        cp.rightInfo['Meter Corr.'] = '';
      }

      results.add(avg);
    }

    notifyListeners();
    return results;
  }


  double? _safeParseDouble(String? s) {
    if (s == null) return null;
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Returns null if no valid numbers found.
  double? averageDoubleList(List<double?> values) {
    final valid = values.where((v) => v != null).cast<double>().toList();
    if (valid.isEmpty) return null;
    final sum = valid.reduce((a, b) => a + b);
    return sum / valid.length;
  }

  /// Find the segment in table where mean lies between lowerValue and upperValue.
  /// If not found:
  ///  - if mean < first.lowerValue -> use first row (extrapolate)
  ///  - if mean > last.upperValue -> use last row (extrapolate)
  /// Returns null if table empty.
  // MeterEntry? _findSegmentForMean(double mean, List<MeterEntry> table) {
  //   if (table.isEmpty) return null;
  //
  //   // direct containment
  //   for (final row in table) {
  //     if (mean >= row.lowerValue && mean <= row.upperValue) return row;
  //   }
  //
  //   // not inside any segment -> choose nearest endpoint segment for extrapolation
  //   if (mean < table.first.lowerValue) return table.first;
  //   if (mean > table.last.upperValue) return table.last;
  //
  //   // as fallback (shouldn't reach if above handled), return nearest by distance to midpoints
  //   MeterEntry? best;
  //   double bestDiff = double.infinity;
  //   for (final r in table) {
  //     final mid = (r.lowerValue + r.upperValue) / 2.0;
  //     final diff = (mid - mean).abs();
  //     if (diff < bestDiff) {
  //       bestDiff = diff;
  //       best = r;
  //     }
  //   }
  //   return best;
  // }
  //
  // /// Compute linear interpolation correction for a given mean using the supplied segment row.
  // /// returns double correction
  // double _interpolateCorrection(double mean, MeterEntry seg) {
  //   final lv = seg.lowerValue;
  //   final uv = seg.upperValue;
  //   final lc = seg.lowerCorrection;
  //   final uc = seg.upperCorrection;
  //
  //   // Avoid division by zero
  //   if ((uv - lv).abs() < 1e-12) return lc;
  //
  //   final slope = (uc - lc) / (uv - lv);
  //   final corr = slope * (mean - lv) + lc;
  //   return corr;
  // }
  //
  // /// For each cal point compute mean of its 6 refReadings, compute meter correction
  // /// using the provided meter table and store into calPoint.rightInfo['Meter Corr.'].
  // /// Returns the list of computed corrections (nullable if mean invalid).
  // List<double?> computeAndStoreMeterCorrectionsFromTable(List<MeterEntry> table) {
  //   final List<double?> results = [];
  //
  //   for (var i = 0; i < calPoints.length; i++) {
  //     final cp = calPoints[i];
  //
  //     // Parse refReadings to doubles safely
  //     final parsed = cp.refReadings.map((s) {
  //       if (s == null) return null;
  //       final trimmed = s.trim();
  //       if (trimmed.isEmpty) return null;
  //       return double.tryParse(trimmed);
  //     }).toList();
  //
  //     // compute mean if any valid
  //     final valid = parsed.where((e) => e != null).cast<double>().toList();
  //     if (valid.isEmpty) {
  //       cp.rightInfo['Meter Corr.'] = '';
  //       results.add(null);
  //       continue;
  //     }
  //     final mean = valid.reduce((a, b) => a + b) / valid.length;
  //
  //     // find segment row
  //     final seg = _findSegmentForMean(mean, table);
  //
  //     if (seg == null) {
  //       cp.rightInfo['Meter Corr.'] = '';
  //       results.add(null);
  //       continue;
  //     }
  //
  //     // compute correction (interpolation/extrapolation as needed)
  //     final corr = _interpolateCorrection(mean, seg);
  //
  //     // store (format as you prefer; here 4 decimal places like your example)
  //     cp.rightInfo['Meter Corr.'] = corr.toStringAsFixed(4);
  //
  //     results.add(corr);
  //   }
  //
  //   notifyListeners();
  //   return results;
  // }


}

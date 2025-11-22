// filename: lib/providers/calibration_provider.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:vitar_crs_temperature/models/calibration_basic_data.dart';
import 'package:vitar_crs_temperature/models/meter_entry.dart';
import 'package:vitar_crs_temperature/models/address.dart';
import 'package:vitar_crs_temperature/models/reference_data.dart';
import 'package:vitar_crs_temperature/services/address_service.dart';
import 'package:vitar_crs_temperature/services/meter_service.dart';
import 'package:vitar_crs_temperature/services/master_lookup_service.dart';
import 'package:vitar_crs_temperature/services/reference_service.dart';

import '../models/calibration_point.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

  // Services (injectable for tests)
  final AddressService _addressService;
  final MeterService _meterService;
  final MasterService _masterService;
  final ReferenceService _referenceService;

  // dynamic data loaded from Supabase
  List<Address> addresses = [];
  Map<String, List<String>> masterOptions = {};
  List<MeterEntry> meterTable = [];
  Map<String, SampleData> referenceSamples = {}; // e.g., 'ST-S5' -> SampleData

  CalibrationProvider({
    AddressService? addressService,
    MeterService? meterService,
    MasterService? masterService,
    ReferenceService? referenceService,
  })  : _addressService = addressService ?? AddressService(),
        _meterService = meterService ?? MeterService(),
        _masterService = masterService ?? MasterService(),
        _referenceService = referenceService ?? ReferenceService() {
    // schedule async initialization after object is created
    Future.microtask(() async {
      await loadMasterOptions();
      await loadReferenceSamples();
      await loadMeterTable();
    });
  }

  // -------------------- load/fetch helpers --------------------
  Future<void> loadAddresses() async {
    try {
      final list = await _addressService.fetchAddressData();
      addresses = list;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadAddresses error: $e\n$st');
    }
  }

  /// Loads master lookup options from `vitar_master_lookup` and stores as
  /// category -> List<String> in masterOptions.
  Future<void> loadMasterOptions() async {
    try {
      final map = await _masterService.fetchMasterOptions();
      masterOptions = map;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadMasterOptions error: $e\n$st');
    }
  }

  /// Loads reference/sample tables (vitar_calibration_reference_values).
  Future<void> loadReferenceSamples() async {
    try {
      final map = await _referenceService.fetchReferenceSamples();
      // map keys like 'ST-S5', 'ST-S6', 'ST-S4' expected
      referenceSamples = map;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadReferenceSamples error: $e\n$st');
    }
  }

  /// Loads meter table from vitar_meter and caches into meterTable.
  Future<void> loadMeterTable() async {
    try {
      final rows = await _meterService.fetchMeterData();
      if (rows.isNotEmpty) {
        meterTable = rows;
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('loadMeterTable error: $e\n$st');
    }
  }

  // ---------------- core setters/getters ----------------
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

  // ---------------- point updates, reset, export ----------------
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

  /// Update a right-info key (dropdown) for a cal-point.
  /// This now triggers recalculation:
  ///  - always recompute meter corrections (they depend on reference readings)
  ///  - recompute actual refs for either the single cal point or all cal-points
  ///    if the changed key is global (e.g. Ref. Ther.)
  void updateCalPointRightInfo(int pointIndex, String key, String value) {
    if (pointIndex < 0 || pointIndex >= calPoints.length) return;
    calPoints[pointIndex].rightInfo[key] = value;
    notifyListeners();

    // recompute meter corrections using current meterTable
    calculateMeterCorrections();

    // if changing reference sample (affects table generation) we should update ALL points
    final keyLower = key.toLowerCase();
    if (keyLower.contains('ref') && keyLower.contains('ther')) {
      for (int i = 0; i < calPoints.length; i++) {
        computeActualRefsForCalPoint(i);
      }
    } else {
      // otherwise recompute only the affected cal point
      computeActualRefsForCalPoint(pointIndex);
    }
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

  /// Compute simple averages of each cal-point's refReadings (returns list)
  List<double?> computeAndStoreMeterCorrections() {
    final List<double?> results = [];
    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
      final avg = averageDoubleList(parsed);
      results.add(avg);
    }
    // this function intentionally does not mutate meterCorrPerRow (averages are used upstream)
    notifyListeners();
    return results;
  }

  // Use meterTable (loaded from Supabase) when calculating corrections.
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

  /// Calculates meter corrections for each cal point using `meterTable` (or overrideTable).
  /// Stores the same formatted correction string into cp.meterCorrPerRow repeated for 6 rows.
  List<double?> calculateMeterCorrections([List<MeterEntry>? overrideTable]) {
    final tableToUse = overrideTable ?? meterTable;
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
      final seg = _findSegmentForMean(mean, tableToUse);
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

  // ------------------------- sample selection helper -------------------------
  /// Choose the SampleData to use for a cal-point.
  /// Preference:
  /// 1) explicit user selection in cp.rightInfo (e.g. 'Ref. Ther.')
  /// 2) masterOptions['Ref. Ther.'] first non-empty value (if it matches referenceSamples)
  /// 3) any loaded referenceSamples.first
  /// 4) fallback numericalReferenceData['ST-S6']
  SampleData _chooseSampleForCalPoint(CalibrationPoint cp) {
    // 1) try explicit keys on this cal-point
    final keysToTry = [
      'Ref. Ther.',
      'Ref Ther.',
      'RefTher',
    ];
    for (final k in keysToTry) {
      final v = (cp.rightInfo[k] ?? '').toString().trim();
      if (v.isNotEmpty && referenceSamples.containsKey(v)) {
        return referenceSamples[v]!;
      }
    }

    // 2) try to use provider.masterOptions 'Ref. Ther.' default value
    try {
      final masterList = masterOptions['Ref. Ther.'] ?? masterOptions['Ref. Ther'] ?? masterOptions['RefTher'];
      if (masterList != null && masterList.isNotEmpty) {
        // pick first meaningful entry that exists in referenceSamples
        for (final candidate in masterList) {
          final cand = candidate.trim();
          if (cand.isEmpty || cand == 'Other...') continue;
          if (referenceSamples.containsKey(cand)) return referenceSamples[cand]!;
        }
      }
    } catch (_) {
      // ignore
    }

    // 3) any loaded reference sample
    if (referenceSamples.isNotEmpty) return referenceSamples.values.first;

    // 4) fallback to built-in numeric table
    return numericalReferenceData['ST-S6']!;
  }

  // ------------------------- table generation and therm corrections -------------------------
  List<List<double>> generateTableForCalPoint(int index) {
    final cp = calPoints[index];
    if (cp.setting.isEmpty) return [];

    int settingValue = int.tryParse(cp.setting) ?? 0;

    // Choose sample via centralized helper
    final SampleData sample = _chooseSampleForCalPoint(cp);

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
    col3.add(0.0);
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

  double? _getThermCorrScaledForRow(CalibrationPoint cp, int rowIndex) {
    // 1) Check explicit rightInfo therm/ref-indicated keys (existing behavior)
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
            // NORMALIZED: assume rightInfo value is an indicated reference (same units as R)
            return v;
          }
        }
      }
    }

    // 2) Try to parse refReading and meterCorrRow (existing fallback)
    final refStr = (rowIndex < cp.refReadings.length) ? cp.refReadings[rowIndex].trim() : '';
    final meterCorrStr = (rowIndex < cp.meterCorrPerRow.length) ? cp.meterCorrPerRow[rowIndex].trim() : '';

    final refVal = double.tryParse(refStr);
    final meterCorrVal = double.tryParse(meterCorrStr);

    debugPrint('_getThermCorrScaledForRow: fallback ref=$refVal meterCorr=$meterCorrVal for row=$rowIndex');

    if (refVal != null && meterCorrVal != null) {
      final refInd = refVal + meterCorrVal; // indicated reference (numeric, same units as R)
      return refInd;
    }

    // 3) NEW: If no measured refVal, try to compute theoretical ref from reference sample table
    //    (so we can still compute a thermScaled when user hasn't measured all rows)
    try {
      // choose sample same as generateTableForCalPoint
      final String chosenKey = (cp.rightInfo['Ref. Ther.'] ?? cp.rightInfo['Ref Ther.'] ?? cp.rightInfo['RefTher'] ?? '').trim();
      SampleData sample;
      if (chosenKey.isNotEmpty && referenceSamples.containsKey(chosenKey)) {

        sample = referenceSamples[chosenKey]!;
        print('5400 -=-=-=- ${sample.row1}');
      } else if (referenceSamples.isNotEmpty) {
        sample = referenceSamples.values.first;
      }
      else {
        sample = numericalReferenceData['ST-S6']!;
      }

      // Build AL positions identical to generateTableForCalPoint
      int effectiveSetting = int.tryParse(cp.setting) ?? 0;
      if (cp.setting.trim().isEmpty) {
        // fallback: find nearest non-empty setting from other calPoints
        int fallbackIndex = -1;
        int bestDist = 1 << 20;
        for (int j = 0; j < calPoints.length; j++) {
          if (calPoints[j].setting.trim().isNotEmpty) {
            final s = int.tryParse(calPoints[j].setting) ?? 0;
            final d = (j - calPoints.indexOf(cp)).abs();
            if (d < bestDist) {
              bestDist = d;
              fallbackIndex = j;
              effectiveSetting = s;
            }
          }
        }
      }

      final List<int> al = List.filled(7, 0);
      al[3] = effectiveSetting;
      for (int i = 2; i >= 0; i--) al[i] = al[i + 1] - 1;
      for (int i = 4; i < 7; i++) al[i] = al[i - 1] + 1;

      // Build col1 multipliers (same formula used elsewhere)
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

      // Theoretical reference value for this row = R * multiplier
      final double R = sample.row1[0];
      // map rowIndex (0..5) to table index 0..5 (same mapping used elsewhere)
      if (rowIndex >= 0 && rowIndex < 6) {
        final double theoreticalRef = (rowIndex < col1.length) ? (R * col1[rowIndex]) : double.nan;
        if (!theoreticalRef.isNaN) {
          // if we also have meterCorr, add it
          if (meterCorrVal != null) {
            final refInd = theoreticalRef + meterCorrVal;
            debugPrint('_getThermCorrScaledForRow: using theoreticalRef=$theoreticalRef meterCorr=$meterCorrVal => refInd=$refInd');
            return refInd;
          } else {
            debugPrint('_getThermCorrScaledForRow: using theoreticalRef=$theoreticalRef (no meterCorr)');
            return theoreticalRef;
          }
        }
      }
    } catch (e, st) {
      debugPrint('_getThermCorrScaledForRow: error computing theoretical ref fallback: $e\n$st');
    }

    // Nothing useful found.
    return null;
  }

  void computeActualRefsForCalPoint(int calIndex) {
    if (calIndex < 0 || calIndex >= calPoints.length) return;
    final cp = calPoints[calIndex];

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
      if (fallbackIndex == -1) {
        cp.actualRefPerRow = List.generate(6, (_) => '');
        notifyListeners();
        return;
      }
    }

    // Build AL sequence & sample selection
    final List<int> al = List.filled(7, 0);
    al[3] = effectiveSetting;
    for (int i = 2; i >= 0; i--) al[i] = al[i + 1] - 1;
    for (int i = 4; i < 7; i++) al[i] = al[i - 1] + 1;

    // pick sample via helper
    final SampleData sample = _chooseSampleForCalPoint(cp);
    print('5400 ===== ${sample.row1}');
    print('5400 ===== $cp');


    final double R = sample.row1[0];

    // Build table (same as generateTableForCalPoint)
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
    List<double> col3 = col1.sublist(1)..add(0.0);
    List<double> col2 = al.map((e) => e.toDouble()).toList();
    List<double> col4 = col2.sublist(1)..add(0.0);
    final List<List<double>> table = List.generate(7, (i) => [col1[i], col2[i], col3[i], col4[i]]);

    final List<String> finalTemps = List.generate(6, (_) => '');
    for (int r = 0; r < 6; r++) {
      final double? thermScaled = _getThermCorrScaledForRow(cp, r);
      debugPrint(' computeActualRefsForCalPoint: row=$r thermScaled=$thermScaled');
      if (thermScaled == null) {
        finalTemps[r] = '';
        continue;
      }

      final double xnorm = thermScaled / R;
      debugPrint('  -> xnorm=$xnorm (thermScaled=$thermScaled R=$R)');

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
  /// Backwards-compatible setter (some screens used setAddresses previously)
  void setAddresses(List<Address> list) {
    addresses = list;
    debugPrint('Loaded addresses: ${addresses.length}');
    notifyListeners();
  }
}

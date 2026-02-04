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
import '../models/permission_names.dart';
import '../services/names_service.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationBasicData data = CalibrationBasicData();
  final List<CalibrationPoint> calPoints = List.generate(8, (_) => CalibrationPoint());

  // Services (injectable for tests)
  final AddressService _addressService;
  final MeterService _meterService;
  final NamesService _namesService;
  final MasterService _masterService;
  final ReferenceService _referenceService;

  // dynamic data loaded from Supabase
  List<Address> addresses = [];
  Map<String, List<String>> masterOptions = {};
  Map<String, List<PermissionName>> namesOptions = {};
  List<MeterEntry> meterTable = [];
  Map<String, SampleData> referenceSamples = {}; // e.g., 'ST-S5' -> SampleData

  CalibrationProvider({
    AddressService? addressService,
    MeterService? meterService,
    NamesService? namesService,
    MasterService? masterService,
    ReferenceService? referenceService,
  })  : _addressService = addressService ?? AddressService(),
        _meterService = meterService ?? MeterService(),
        _namesService = namesService ?? NamesService(),
        _masterService = masterService ?? MasterService(),
        _referenceService = referenceService ?? ReferenceService() {
    // schedule async initialization after object is created
    Future.microtask(() async {
      await loadMasterOptions();
      await loadReferenceSamples();
      // await loadMeterTable();
      await loadNamesOptions();
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

  Future<void> loadMasterOptions() async {
    try {
      final map = await _masterService.fetchMasterOptions();
      masterOptions = map;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadMasterOptions error: $e\n$st');
    }
  }

  Future<void> loadNamesOptions() async {
    try {
      final map = await NamesService().fetchCalibratedAndApproved();
      // fetchCalibratedAndApproved returns Map<String, List<PermissionName>>
      namesOptions = map;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadNamesOptions error: $e\n$st');
    }
  }

  Future<void> loadReferenceSamples() async {
    try {
      final map = await _referenceService.fetchReferenceSamples();
      referenceSamples = map;
      notifyListeners();
    } catch (e, st) {
      debugPrint('loadReferenceSamples error: $e\n$st');
    }
  }

  // Future<void> loadMeterTable() async {
  //   try {
  //     final rows = await _meterService.fetchMeterData();
  //     if (rows.isNotEmpty) {
  //       meterTable = rows;
  //       notifyListeners();
  //     }
  //   } catch (e, st) {
  //     debugPrint('loadMeterTable error: $e\n$st');
  //   }
  // }

  Future<void> loadNamesTable(String type) async {
    try {
      final rows = await _namesService.fetchByType(type);
      if (rows.isNotEmpty) {
        // This should not assign to `meterTable`!
        // If this is names data, assign to namesOptions
        namesOptions[type] = rows;
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('loadNamesTable error: $e\n$st');
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
    // when user explicitly updates a ref reading, recalc meter corr & actual refs for that point
    calculateMeterCorrections(); // will remain blank if insufficient user data
    computeActualRefsForCalPoint(pointIndex);
    notifyListeners();
  }

  void updateTestReading(int pointIndex, int rowIndex, String value) {
    if (!_validPointRow(pointIndex, rowIndex)) return;
    calPoints[pointIndex].testReadings[rowIndex] = value;
    // test readings don't affect meterCorr directly in current logic,
    // but you may want to recompute derived values when tests change.
    notifyListeners();
  }

  /// Update a right-info key (dropdown) for a cal-point.
  /// This now triggers recalculation:
  ///  - always recompute meter corrections (they depend on reference readings)
  ///  - recompute actual refs for either the single cal point or all cal-points
  ///    if the changed key is global (e.g. Ref. Ther.)
  // void updateCalPointRightInfo(int pointIndex, String key, String value) {
  //   if (pointIndex < 0 || pointIndex >= calPoints.length) return;
  //   calPoints[pointIndex].rightInfo[key] = value;
  //   notifyListeners();
  //
  //   // recompute meter corrections using current meterTable (will be blank unless user has ref readings)
  //   calculateMeterCorrections();
  //
  //   // if changing reference sample (affects table generation) we should update ALL points
  //   final keyLower = key.toLowerCase();
  //   if (keyLower.contains('ref') && keyLower.contains('ther')) {
  //     for (int i = 0; i < calPoints.length; i++) {
  //       computeActualRefsForCalPoint(i);
  //     }
  //   } else {
  //     // otherwise recompute only the affected cal point
  //     computeActualRefsForCalPoint(pointIndex);
  //   }
  // }

  // Inside lib/providers/calibration_provider.dart

  void updateCalPointRightInfo(int pointIndex, String key, String value) async {
    if (pointIndex < 0 || pointIndex >= calPoints.length) return;

    calPoints[pointIndex].rightInfo[key] = value;
    notifyListeners();

    // NEW LOGIC: If the user selects a specific Reference Indicator (meter_model)
    if (key == 'Ref. Ind.' || key == 'Ref Ind.') {
      try {
        // Fetch only the rows matching the selected model
        final rows = await _meterService.fetchMeterData(modelName: value);

        // Update the provider's meterTable with these specific rows
        if (rows.isNotEmpty) {
          meterTable = rows;
          // Re-run calculations for this point using the new meter data
          calculateMeterCorrections();
          computeActualRefsForCalPoint(pointIndex);
        }
      } catch (e) {
        debugPrint('Error fetching specific meter data: $e');
      }
    } else {
      // Standard re-calculation for other field changes
      calculateMeterCorrections();
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

  bool _hasAnyUserRef(CalibrationPoint cp) {
    for (final s in cp.refReadings) {
      if (s.trim().isNotEmpty) return true;
    }
    return false;
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
  /// IMPORTANT: this will NOT fill meterCorrPerRow unless the user has entered at least one numeric
  /// reference reading for that cal point. If no user ref readings exist, meterCorrPerRow remains blank.
  List<double?> calculateMeterCorrections([List<MeterEntry>? overrideTable]) {
    final tableToUse = overrideTable ?? meterTable;
    final List<double?> results = [];

    for (var i = 0; i < calPoints.length; i++) {
      final cp = calPoints[i];

      // Require at least one user-entered ref reading (non-empty & numeric) before computing.
      final parsed = cp.refReadings.map((s) => _safeParseDouble(s)).toList();
      final valid = parsed.where((x) => x != null).cast<double>().toList();

      if (valid.isEmpty) {
        // leave meterCorrPerRow blank when there's no user-entered numeric ref readings
        cp.meterCorrPerRow = List.generate(6, (_) => '');
        results.add(null);
        continue;
      }

      // compute mean on available numeric reference readings
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
  SampleData _chooseSampleForCalPoint(CalibrationPoint cp) {
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

    try {
      final masterList = masterOptions['Ref. Ther.'] ?? masterOptions['Ref. Ther'] ?? masterOptions['RefTher'];
      if (masterList != null && masterList.isNotEmpty) {
        for (final candidate in masterList) {
          final cand = candidate.trim();
          if (cand.isEmpty || cand == 'Other...') continue;
          if (referenceSamples.containsKey(cand)) return referenceSamples[cand]!;
        }
      }
    } catch (_) {
      // ignore
    }

    if (referenceSamples.isNotEmpty) return referenceSamples.values.first;
    return numericalReferenceData['ST-S6']!;
  }

  // ------------------------- table generation and therm corrections -------------------------
  List<List<double>> generateTableForCalPoint(int index) {
    final cp = calPoints[index];
    if (cp.setting.isEmpty) return [];

    int settingValue = int.tryParse(cp.setting) ?? 0;
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

      // Only calculate therm correction where both a measured ref and a meter correction exist.
      if (refVal == null || meterVal == null) {
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

  /// Returns indicated reference (same units as sample.row1[0]) or null.
  /// Theoretical/sample fallback is only used when `allowTheoretical` is true.
  double? _getThermCorrScaledForRow(CalibrationPoint cp, int rowIndex, {bool allowTheoretical = false}) {
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
            // assume rightInfo value is an indicated reference (same units as R)
            return v;
          }
        }
      }
    }

    // 2) Try to parse refReading and meterCorrRow (explicit user/measured data)
    final refStr = (rowIndex < cp.refReadings.length) ? cp.refReadings[rowIndex].trim() : '';
    final meterCorrStr = (rowIndex < cp.meterCorrPerRow.length) ? cp.meterCorrPerRow[rowIndex].trim() : '';

    final refVal = double.tryParse(refStr);
    final meterCorrVal = double.tryParse(meterCorrStr);

    debugPrint('_getThermCorrScaledForRow: fallback ref=$refVal meterCorr=$meterCorrVal for row=$rowIndex');

    if (refVal != null && meterCorrVal != null) {
      final refInd = refVal + meterCorrVal; // indicated reference (numeric, same units as R)
      return refInd;
    }

    // 3) Theoretical/sample fallback (only if caller explicitly allows it)
    if (!allowTheoretical) return null;

    try {
      final String chosenKey = (cp.rightInfo['Ref. Ther.'] ?? cp.rightInfo['Ref Ther.'] ?? cp.rightInfo['RefTher'] ?? '').trim();
      SampleData sample;
      if (chosenKey.isNotEmpty && referenceSamples.containsKey(chosenKey)) {
        sample = referenceSamples[chosenKey]!;
      } else if (referenceSamples.isNotEmpty) {
        sample = referenceSamples.values.first;
      } else {
        sample = numericalReferenceData['ST-S6']!;
      }

      int effectiveSetting = int.tryParse(cp.setting) ?? 0;
      if (cp.setting.trim().isEmpty) {
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

      final double R = sample.row1[0];
      if (rowIndex >= 0 && rowIndex < 6) {
        final double theoreticalRef = (rowIndex < col1.length) ? (R * col1[rowIndex]) : double.nan;
        if (!theoreticalRef.isNaN) {
          if (meterCorrVal != null) {
            final refInd = theoreticalRef + meterCorrVal;
            return refInd;
          } else {
            return theoreticalRef;
          }
        }
      }
    } catch (e, st) {
      debugPrint('_getThermCorrScaledForRow: error computing theoretical ref fallback: $e\n$st');
    }

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

    final List<int> al = List.filled(7, 0);
    al[3] = effectiveSetting;
    for (int i = 2; i >= 0; i--) al[i] = al[i + 1] - 1;
    for (int i = 4; i < 7; i++) al[i] = al[i - 1] + 1;

    final SampleData sample = _chooseSampleForCalPoint(cp);
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
      // IMPORTANT: do not allow theoretical fallback here — only compute for rows with explicit user data
      final double? thermScaled = _getThermCorrScaledForRow(cp, r, allowTheoretical: false);
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
  void setAddresses(List<Address> list) {
    addresses = list;
    debugPrint('Loaded addresses: ${addresses.length}');
    notifyListeners();
  }
  String? calibratedBy;
  String? approvedSignatory;

  void setCalibratedBy(String? value) {
    calibratedBy = value;
    notifyListeners();
  }

  void setApprovedSignatory(String? value) {
    approvedSignatory = value;
    notifyListeners();
  }

}

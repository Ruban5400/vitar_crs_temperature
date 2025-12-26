// filename: lib/models/calibration_basic_data.dart
import 'package:vitar_crs_temperature/models/permission_names.dart';

class CalibrationBasicData {
  String certificateNo;
  String instrument;
  String make;
  String model;
  String serialNo;
  String customerName;
  String cmrNo;
  String dateReceived;
  String dateCalibrated;
  String ambientTempMax;
  String ambientTempMin;
  String relativeHumidityMax;
  String relativeHumidityMin;
  String thermohygrometer;
  String refMethod;
  String calibratedAt;
  String remark;
  String instrumentConditionReceived;
  String instrumentConditionReturned;
  String resolution;
  PermissionName? calibratedBy;
  PermissionName? approvedBy;


  CalibrationBasicData({
    this.certificateNo = '',
    this.instrument = '',
    this.make = '',
    this.model = '',
    this.serialNo = '',
    this.customerName = '',
    this.cmrNo = '',
    this.dateReceived = '',
    this.dateCalibrated = '',
    this.ambientTempMax = '',
    this.ambientTempMin = '',
    this.relativeHumidityMax = '',
    this.relativeHumidityMin = '',
    this.thermohygrometer = '',
    this.refMethod = '',
    this.calibratedAt = '',
    this.remark = '',
    this.instrumentConditionReceived = '',
    this.instrumentConditionReturned = '',
    this.resolution = '',
    this.calibratedBy,
    this.approvedBy,
  });

  Map<String, dynamic> toMap() => {
    'certificateNo': certificateNo,
    'instrument': instrument,
    'make': make,
    'model': model,
    'serialNo': serialNo,
    'customerName': customerName,
    'cmrNo': cmrNo,
    'dateReceived': dateReceived,
    'dateCalibrated': dateCalibrated,
    'ambientTempMax': ambientTempMax,
    'ambientTempMin': ambientTempMin,
    'relativeHumidityMax': relativeHumidityMax,
    'relativeHumidityMin': relativeHumidityMin,
    'thermohygrometer': thermohygrometer,
    'refMethod': refMethod,
    'calibratedAt': calibratedAt,
    'remark': remark,
    'instrumentConditionReceived': instrumentConditionReceived,
    'instrumentConditionReturned': instrumentConditionReturned,
    'resolution': resolution,
    'calibratedBy': calibratedBy?.toMap(),
    'approvedBy': approvedBy?.toMap(),
  };

  factory CalibrationBasicData.fromMap(Map<String, dynamic> map) {
    return CalibrationBasicData(
      certificateNo: map['certificateNo'] as String? ?? '',
      instrument: map['instrument'] as String? ?? '',
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      serialNo: map['serialNo'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      cmrNo: map['cmrNo'] as String? ?? '',
      dateReceived: map['dateReceived'] as String? ?? '',
      dateCalibrated: map['dateCalibrated'] as String? ?? '',
      ambientTempMax: map['ambientTempMax'] as String? ?? '',
      ambientTempMin: map['ambientTempMin'] as String? ?? '',
      relativeHumidityMax: map['relativeHumidityMax'] as String? ?? '',
      relativeHumidityMin: map['relativeHumidityMin'] as String? ?? '',
      thermohygrometer: map['thermohygrometer'] as String? ?? '',
      refMethod: map['refMethod'] as String? ?? '',
      calibratedAt: map['calibratedAt'] as String? ?? '',
      remark: map['remark'] as String? ?? '',
      instrumentConditionReceived:
      map['instrumentConditionReceived'] as String? ?? '',
      instrumentConditionReturned:
      map['instrumentConditionReturned'] as String? ?? '',
      resolution: map['resolution'] as String? ?? '',
      calibratedBy: map['calibratedBy'] != null
          ? PermissionName.fromMap(map['calibratedBy'])
          : null, // <-- added
      approvedBy: map['approvedBy'] != null
          ? PermissionName.fromMap(map['approvedBy'])
          : null,     // <-- added
    );
  }

  /// Reset all fields to empty - used by providers.
  void clear() {
    certificateNo = '';
    instrument = '';
    make = '';
    model = '';
    serialNo = '';
    customerName = '';
    cmrNo = '';
    dateReceived = '';
    dateCalibrated = '';
    ambientTempMax = '';
    ambientTempMin = '';
    relativeHumidityMax = '';
    relativeHumidityMin = '';
    thermohygrometer = '';
    refMethod = '';
    calibratedAt = '';
    remark = '';
    instrumentConditionReceived = '';
    instrumentConditionReturned = '';
    resolution = '';
  }

  CalibrationBasicData copyWith({
    String? certificateNo,
    String? instrument,
    String? make,
    String? model,
    String? serialNo,
    String? customerName,
    String? cmrNo,
    String? dateReceived,
    String? dateCalibrated,
    String? ambientTempMax,
    String? ambientTempMin,
    String? relativeHumidityMax,
    String? relativeHumidityMin,
    String? thermohygrometer,
    String? refMethod,
    String? calibratedAt,
    String? remark,
    String? instrumentConditionReceived,
    String? instrumentConditionReturned,
    String? resolution,
  }) {
    return CalibrationBasicData(
      certificateNo: certificateNo ?? this.certificateNo,
      instrument: instrument ?? this.instrument,
      make: make ?? this.make,
      model: model ?? this.model,
      serialNo: serialNo ?? this.serialNo,
      customerName: customerName ?? this.customerName,
      cmrNo: cmrNo ?? this.cmrNo,
      dateReceived: dateReceived ?? this.dateReceived,
      dateCalibrated: dateCalibrated ?? this.dateCalibrated,
      ambientTempMax: ambientTempMax ?? this.ambientTempMax,
      ambientTempMin: ambientTempMin ?? this.ambientTempMin,
      relativeHumidityMax: relativeHumidityMax ?? this.relativeHumidityMax,
      relativeHumidityMin: relativeHumidityMin ?? this.relativeHumidityMin,
      thermohygrometer: thermohygrometer ?? this.thermohygrometer,
      refMethod: refMethod ?? this.refMethod,
      calibratedAt: calibratedAt ?? this.calibratedAt,
      remark: remark ?? this.remark,
      instrumentConditionReceived:
      instrumentConditionReceived ?? this.instrumentConditionReceived,
      instrumentConditionReturned:
      instrumentConditionReturned ?? this.instrumentConditionReturned,
      resolution: resolution ?? this.resolution,
    );
  }
}

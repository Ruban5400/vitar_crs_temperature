
enum CalibratedAt { lab, site }

// calibration_basic_data.dart
class CalibrationBasicData {
  String certificateNo = '';
  String instrument = '';
  String make = '';
  String model = '';
  String serialNo = '';
  String customerName = '';
  String cmrNo = '';
  String dateReceived = '';
  String dateCalibrated = '';
  String ambientTempMax = '';
  String ambientTempMin = '';
  String relativeHumidityMax = '';
  String relativeHumidityMin = '';
  String thermohygrometer = '';
  String refMethod = '';
  String calibratedAt = '';
  String remark = '';
  String instrumentConditionReceived = '';
  String instrumentConditionReturned = '';
  String resolution = '';

  // COMPLETE mapping so exportAll() is meaningful
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
  };

  // clear helper used by provider.resetAll()
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
}


class CalibrationPoint {
  String setting = '';
  List<String> refReadings = List.generate(6, (_) => '');
  List<String> testReadings = List.generate(6, (_) => '');
  Map<String, String> rightInfo = {
    'Ref. Ther.': '',
    'Ref. Ind.': '',
    'Ref. Wire': '',
    'Test Ind.': '',
    'Test Wire': '',
    'Bath': '',
    'Immer.': '',
    'Meter Corr.': '',
  };

  // new: computed correction per visible row (same value repeated for 6 rows)
  List<String> meterCorrPerRow = List.generate(6, (_) => '');

  Map<String, dynamic> toMap() => {
    'setting': setting,
    'refReadings': refReadings,
    'testReadings': testReadings,
    'rightInfo': rightInfo,
  };
}

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
  String calibratedAt = ''; // 'Lab' or 'Site'
  String remark = '';
  String instrumentConditionReceived = '';
  String instrumentConditionReturned = '';
  String resolution = '';

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

  @override
  String toString() => toMap().toString();
}

class CalibrationPoint {
  String setting = '';
  final List<String> refReadings = List.generate(6, (_) => '');
  final List<String> testReadings = List.generate(6, (_) => '');
  final Map<String, String> rightInfo = {
    'Ref. Ther.': '',
    'Ref. Ind.': '',
    'Ref. Wire': '',
    'Test Ind.': '',
    'Test Wire': '',
    'Bath': '',
    'Immer.': '',
  };

  Map<String, dynamic> toMap() => {
    'setting': setting,
    'ref': List.from(refReadings),
    'test': List.from(testReadings),
    'right': Map.from(rightInfo),
  };

  @override
  String toString() => toMap().toString();
}
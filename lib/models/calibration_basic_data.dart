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

  Map<String, dynamic> toMap() => {
    'certificateNo': certificateNo,
    'serialNo': serialNo,
  };
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

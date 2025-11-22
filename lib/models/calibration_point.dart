// filename: lib/models/calibration_point.dart
class CalibrationPoint {
  String setting;
  List<String> refReadings;
  List<String> testReadings;
  Map<String, String> rightInfo;
  List<String> meterCorrPerRow;
  List<String> actualRefPerRow;

  CalibrationPoint({
    this.setting = '',
    List<String>? refReadings,
    List<String>? testReadings,
    Map<String, String>? rightInfo,
    List<String>? meterCorrPerRow,
    List<String>? actualRefPerRow,
  })  : refReadings = refReadings ?? List.generate(6, (_) => ''),
        testReadings = testReadings ?? List.generate(6, (_) => ''),
        rightInfo = rightInfo ??
            {
              'Ref. Ther.': '',
              'Ref. Ind.': '',
              'Ref. Wire': '',
              'Test Ind.': '',
              'Test Wire': '',
              'Bath': '',
              'Immer.': '',
            },
        meterCorrPerRow = meterCorrPerRow ?? List.generate(6, (_) => ''),
        actualRefPerRow = actualRefPerRow ?? List.generate(6, (_) => '');

  Map<String, dynamic> toMap() => {
    'setting': setting,
    'refReadings': refReadings,
    'testReadings': testReadings,
    'rightInfo': rightInfo,
    'meterCorrPerRow': meterCorrPerRow,
    'actualRefPerRow': actualRefPerRow,
  };

  factory CalibrationPoint.fromMap(Map<String, dynamic> map) {
    return CalibrationPoint(
      setting: map['setting'] as String? ?? '',
      refReadings: (map['refReadings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          List.generate(6, (_) => ''),
      testReadings: (map['testReadings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          List.generate(6, (_) => ''),
      rightInfo: Map<String, String>.from(map['rightInfo'] ?? {}),
      meterCorrPerRow: (map['meterCorrPerRow'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          List.generate(6, (_) => ''),
      actualRefPerRow: (map['actualRefPerRow'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          List.generate(6, (_) => ''),
    );
  }
}

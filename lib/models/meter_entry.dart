class MeterEntry {
  final int id;
  final double lowerValue;
  final double upperValue;
  final double upperCorrection;
  final double lowerUncertainty;
  final double lowerCorrection;
  final double upperUncertainty;
  final String meterModel;

  MeterEntry({
    required this.id,
    required this.lowerValue,
    required this.upperValue,
    required this.upperCorrection,
    required this.lowerCorrection,
    required this.lowerUncertainty,
    required this.upperUncertainty,
    required this.meterModel,
  });

  factory MeterEntry.fromJson(Map<String, dynamic> json) {
    return MeterEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lowerValue: (json['lower_value'] as num?)?.toDouble() ?? 0.0,
      upperValue: (json['upper_value'] as num?)?.toDouble() ?? 0.0,
      lowerCorrection: (json['lower_correction'] as num?)?.toDouble() ?? 0.0,
      upperCorrection: (json['upper_correction'] as num?)?.toDouble() ?? 0.0,
      lowerUncertainty: (json['lower_uncertainty'] as num?)?.toDouble() ?? 0.0,
      upperUncertainty: (json['upper_uncertainty'] as num?)?.toDouble() ?? 0.0,
      meterModel: json['meter_model'] as String? ?? 'N/A',
    );
  }

  @override
  String toString() {
    return 'MeterEntry(id:$id, lowerValue:$lowerValue, upperValue:$upperValue, lowerCorr:$lowerCorrection, upperCorr:$upperCorrection)';
  }
}

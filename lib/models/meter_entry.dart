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
    print(json);
    return MeterEntry(
      // 💡 FIX: Safely cast the 'id' field, defaulting to 0 if null.
      // The id column name is guaranteed to be 'id'.
      id: json['id'] as int? ?? 0,

      // Ensure all other mappings are using the correct column names
      // and safe null handling as confirmed in the last step:
      lowerValue: (json['lower_value'] as num?)?.toDouble() ?? 0.0,
      upperValue: (json['upper_value'] as num?)?.toDouble() ?? 0.0,
      lowerCorrection: (json['lower_correction'] as num?)?.toDouble() ?? 0.0,
      upperCorrection: (json['upper_correction'] as num?)?.toDouble() ?? 0.0,
      lowerUncertainty: (json['lower_uncertainty'] as num?)?.toDouble() ?? 0.0,
      upperUncertainty: (json['upper_uncertainty'] as num?)?.toDouble() ?? 0.0,
      meterModel: json['meter_model'] as String? ?? 'N/A',
    );
  }
}
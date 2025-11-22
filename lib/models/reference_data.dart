// filename: lib/models/reference_data.dart
/// Initial default statuses for the available references.
const Map<String, bool> initialReferenceStatus = {
  'ST-S1': false,
  'ST-S3': false,
  'ST-S4': true,
  'ST-S5': true,
  'ST-S6': true,
  'ST-S7': false,
  'ST-S8': false,
  'ST-S2': false,
};

/// Structure for a sample's numerical rows.
class SampleData {
  final List<double> row1;
  final List<double> row3;
  final List<double> row4;
  final List<double> row5;

  const SampleData({
    required this.row1,
    required this.row3,
    required this.row4,
    required this.row5,
  });
}

/// The numerical reference data map (keeps original numbers).
final Map<String, SampleData> numericalReferenceData = {
  'ST-S5': const SampleData(
    row1: [99.9952, 99.9952],
    row3: [0.39126, 0.39126],
    row4: [-0.0058992, -0.0058992],
    row5: [-0.0010613, 0],
  ),
  'ST-S6': const SampleData(
    row1: [100.0542, 100.0542],
    row3: [0.39054, 0.39054],
    row4: [-0.0056753, -0.0056753],
    row5: [-0.0045078, 0],
  ),
  'ST-S4': const SampleData(
    row1: [100.0697, 100.0697],
    row3: [0.39085, 0.39085],
    row4: [-0.0057184, -0.0057184],
    row5: [-0.092787, 0],
  ),
};

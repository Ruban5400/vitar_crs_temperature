// The data you need to store
import 'dart:math';

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

// Define a structure for a single Sample's data
class SampleData {
  final List<double> row1;
  final List<double> row3;
  final List<double> row4;
  final List<double> row5;
  // Row 2 is constant (1), so we can omit it or store it if needed.

  SampleData({
    required this.row1,
    required this.row3,
    required this.row4,
    required this.row5,
  });
}

// Map to store all reference data
final Map<String, SampleData> numericalReferenceData = {
  'ST-S5': SampleData(
    row1: [99.9952, 99.9952],
    row3: [0.39126, 0.39126],
    row4: [-0.0058992, -0.0058992],
    row5: [-0.0010613, 0],
  ),
  'ST-S6': SampleData(
    row1: [100.0479, 100.0479],
    row3: [0.39029, 0.39029],
    row4: [-0.005614, -0.005614],
    row5: [-0.0085966, 0],
  ),
  'ST-S4': SampleData(
    row1: [100.0697, 100.0697],
    row3: [0.39085, 0.39085],
    row4: [-0.0057184, -0.0057184],
    row5: [-0.092787, 0],
  ),
};


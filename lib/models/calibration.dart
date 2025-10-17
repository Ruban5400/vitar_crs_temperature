import 'cal_result.dart';

class Calibration {
  final String certNo;
  final String serialNo;
  final String make;
  final String model;
  final DateTime calDate;
  final DateTime dueDate;
  final List<CalResult> results;
  final double maxExpandedU;

  Calibration({
    required this.certNo,
    required this.serialNo,
    required this.make,
    required this.model,
    required this.calDate,
    required this.dueDate,
    required this.results,
    required this.maxExpandedU,
  });
}
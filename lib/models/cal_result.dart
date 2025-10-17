import 'dart:math';

import 'test_point.dart';

class CalResult {
  final TestPoint point;
  final double trueTemp;
  final double correction;
  final double expandedU;

  CalResult({
    required this.point,
    required this.trueTemp,
    required this.correction,
    required this.expandedU,
  });
  double get estU => _roundSF(expandedU);   // ← new
  static double _roundSF(double v){
    if (v == 0) return 0;
    final d = log(v)/ln10;
    final powr = pow(10, (d.floor()).toDouble());
    return (v / powr).ceilToDouble() * powr;
  }
}


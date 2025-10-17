import 'dart:math';
import '../models/test_point.dart';

class Uncertainty {
  static double uStd(TestPoint p, double trueT) {
    final uRepeat = p.testTemps.stdDev / sqrt(6);
    final uRef = 0.02; // dummy
    final uRes = 0.1 / 2 / sqrt(3);
    final uOther = 0.05;
    return sqrt(uRepeat * uRepeat + uRef * uRef + uRes * uRes + uOther * uOther);
  }
}

extension _ListExt on List<double> {
  double get average => reduce((a, b) => a + b) / length;
  double get stdDev {
    final m = average;
    final sum = fold(0.0, (pv, e) => pv + (e - m) * (e - m));
    return sqrt(sum / length);
  }
}
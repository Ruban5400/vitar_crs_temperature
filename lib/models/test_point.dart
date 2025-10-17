import 'dart:math';

class TestPoint {
  int index;
  double setPoint;
  List<double> refOhms; // 6
  List<double> testTemps; // 6

  TestPoint({
    required this.index,
    required this.setPoint,
    List<double>? refOhms,
    List<double>? testTemps,
  })  : refOhms = refOhms ?? List.filled(6, 0),
        testTemps = testTemps ?? List.filled(6, 0);

  double get meanRef => refOhms.reduce((a, b) => a + b) / 6;
  double get meanTest => testTemps.reduce((a, b) => a + b) / 6;
}
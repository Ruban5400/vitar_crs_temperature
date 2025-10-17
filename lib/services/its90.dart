import 'dart:math';

class ITS90 {
  static double temp(double rOhm) {
    // Callendar-van Dusen demo (0-420 °C)
    const r0 = 100.0;
    const a = 3.9083e-3;
    const b = -5.775e-7;
    final t = (rOhm / r0 - 1) / a + b * pow((rOhm / r0 - 1) / a, 2);
    return t;
  }
}


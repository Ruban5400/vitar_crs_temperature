import 'package:flutter/material.dart';
import '../models/test_point.dart';

class PointCard extends StatelessWidget {
  final TestPoint point;
  const PointCard({Key? key, required this.point}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set point ${point.setPoint} °C', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _col('Reference (Ω)', point.refOhms, (i, v) => point.refOhms[i] = v)),
                const SizedBox(width: 8),
                Expanded(child: _col('Test (°C)', point.testTemps, (i, v) => point.testTemps[i] = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _col(String label, List<double> list, Function(int, double) setter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        ...List.generate(6, (i) => SizedBox(
          height: 32,
          child: TextFormField(
            initialValue: list[i].toString(),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12),
            onChanged: (v) => setter(i, double.tryParse(v) ?? 0),
          ),
        )),
      ],
    );
  }
}
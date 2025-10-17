import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cal_provider.dart';
import '../widgets/point_card.dart';
import 'summary_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CalProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Readings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextFormField(initialValue: prov.certNo, decoration: const InputDecoration(labelText: 'Certificate No'), onChanged: (v) => prov.certNo = v),
          TextFormField(initialValue: prov.serialNo, decoration: const InputDecoration(labelText: 'Serial No'), onChanged: (v) => prov.serialNo = v),
          TextFormField(initialValue: prov.make, decoration: const InputDecoration(labelText: 'Make'), onChanged: (v) => prov.make = v),
          TextFormField(initialValue: prov.model, decoration: const InputDecoration(labelText: 'Model'), onChanged: (v) => prov.model = v),
          const SizedBox(height: 10),
          ...prov.points.map((p) => PointCard(point: p)).toList(),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calculate),
              label: const Text('CALCULATE'),
              onPressed: () {
                prov.calculate();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
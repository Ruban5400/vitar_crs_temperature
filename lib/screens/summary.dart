import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final all = provider.exportAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Summary'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Review all entered data:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all()), child: Text(all.toString())),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
              ElevatedButton(
                onPressed: () {
                  // Persist here (local DB / Firebase / PDF). Placeholder for now:
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Saved'),
                      content: const Text('Data is currently stored in-memory. Implement persistence as needed.'),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}
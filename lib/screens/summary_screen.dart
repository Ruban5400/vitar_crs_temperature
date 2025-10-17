import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/cal_provider.dart';
import 'coc_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CalProvider>(context);
    final res = prov.results!;
    return Scaffold(
      appBar: AppBar(title: const Text('Summary'), actions: [
        IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () async => _export(context)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // DataTable(
          //   columns: const [
          //     DataColumn(label: Text('Set (°C)')),
          //     DataColumn(label: Text('Ref (°C)')),
          //     DataColumn(label: Text('Test (°C)')),
          //     DataColumn(label: Text('Corr (°C)')),
          //     DataColumn(label: Text('U (°C)')),
          //   ],
          //   rows: res.map((r) => DataRow(cells: [
          //     DataCell(Text(r.point.setPoint.toStringAsFixed(0))),
          //     DataCell(Text(r.trueTemp.toStringAsFixed(1))),
          //     DataCell(Text(r.point.meanTest.toStringAsFixed(1))),
          //     DataCell(Text(r.correction.toStringAsFixed(1))),
          //     DataCell(Text(r.expandedU.toStringAsFixed(2))),
          //   ])).toList(),
          // ),
          DataTable(
            columns: const [
              DataColumn(label: Text('Set (°C)')),
              DataColumn(label: Text('Ref (°C)')),
              DataColumn(label: Text('Test (°C)')),
              DataColumn(label: Text('Correction (°C)')),
              DataColumn(label: Text('Uncertainty (°C)')),
              DataColumn(label: Text('Est. (°C)')),
            ],
            rows: res.map((r) => DataRow(cells: [
              DataCell(Text(r.point.setPoint.toStringAsFixed(0))),
              DataCell(Text(r.trueTemp.toStringAsFixed(1))),
              DataCell(Text(r.point.meanTest.toStringAsFixed(1))),
              DataCell(Text(r.correction.toStringAsFixed(2))),
              DataCell(Text(r.expandedU.toStringAsFixed(3))),
              DataCell(Text(r.estU.toStringAsFixed(1))),
            ])).toList(),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('GENERATE CERTIFICATE'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CocScreen())),
            ),
          ),
        ],
      ),
    );
  }

  void _export(BuildContext context) async {
    final prov = Provider.of<CalProvider>(context, listen: false);
    final bytes = await prov.generatePdf();
    await Printing.sharePdf(bytes: bytes, filename: '${prov.certNo}.pdf');
  }
}
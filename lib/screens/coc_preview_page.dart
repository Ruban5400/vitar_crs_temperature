// lib/screens/coc_preview_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';
import '../models/meter_entry.dart';

/// COC Preview page — shows all values collected on the first page (CalibrationRecordScreen).
/// PDF generation intentionally left disabled for now.
class COCPreviewPage extends StatelessWidget {
  final List<MeterEntry> meterEntries;
  const COCPreviewPage({super.key, required this.meterEntries});

  double? _meanFromList(List<String> list) {
    final nums = list
        .map((s) => double.tryParse((s ?? '').toString().trim()))
        .where((n) => n != null)
        .map((e) => e!)
        .toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  /// Helper to compute mean of provider.computeThermCorrections result
  double? _meanFromActualRefs(List<String> actualRefs) {
    final nums = actualRefs
        .map((s) => double.tryParse((s ?? '').toString().trim()))
        .where((n) => n != null)
        .map((e) => e!)
        .toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  Widget _buildHeaderBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CERTIFICATE NO. : ${d.certificateNo ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Page : 1 of 2', style: const TextStyle(fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Submitted By: ${d.customerName ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 12, children: [
            Text('CMR No.: ${d.cmrNo ?? ''}'),
            Text('Date Received: ${d.dateReceived ?? ''}'),
            Text('Date Calibrated: ${d.dateCalibrated ?? ''}'),
          ]),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          Text('Instrument Description', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Description: ${d.instrument ?? ''}'),
          Text('Make      : ${d.make ?? ''}'),
          Text('Model     : ${d.model ?? ''}'),
          Text('Serial No.: ${d.serialNo ?? ''}'),
        ]),
      ),
    ]);
  }

  Widget _buildEnvironmentBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Environmental Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Ambient Temp. Max : ${d.ambientTempMax ?? ''}')),
          Expanded(child: Text('Ambient Temp. Min : ${d.ambientTempMin ?? ''}')),
          Expanded(child: Text('Relative Humidity Max : ${d.relativeHumidityMax ?? ''}')),
          Expanded(child: Text('Relative Humidity Min : ${d.relativeHumidityMin ?? ''}')),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Thermohygrometer : ${d.thermohygrometer ?? ''}')),
          Expanded(child: Text('Resolution       : ${d.resolution ?? ''}')),
          Expanded(child: Text('Ref. Method      : ${d.refMethod ?? ''}')),
        ]),
        const SizedBox(height: 6),
        Text('Remark: ${d.remark ?? ''}'),
      ]),
    );
  }

  Widget _buildConditionBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Instrument Condition', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('When Received : ${d.instrumentConditionReceived ?? ''}')),
          Expanded(child: Text('When Returned : ${d.instrumentConditionReturned ?? ''}')),
        ]),
      ]),
    );
  }

  Widget _buildCalPointCard(BuildContext context, CalibrationProvider prov, int i) {
    final cp = prov.calPoints[i];
    final actualRefs = prov.computeThermCorrections(i);
    final meanActual = _meanFromActualRefs(actualRefs);
    return Container(
      width: 310,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Cal. Point : ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Setting : ${cp.setting ?? ''}'),
        ]),
        const SizedBox(height: 6),
        Row(children: const [
          Expanded(child: Center(child: Text('Ref. Reading'))),
          Expanded(child: Center(child: Text('Test Reading'))),
        ]),
        const Divider(),
        Column(
          children: List.generate(6, (r) {
            final ref = cp.refReadings[r].toString();
            final test = cp.testReadings[r].toString();
            final actual = (r < actualRefs.length) ? actualRefs[r] : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(child: Text(ref, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                  Expanded(child: Text(test, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                  Expanded(child: Text(actual, textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ),
        const Divider(),
        Text('Std (Actual Ref) mean: ${meanActual != null ? meanActual.toStringAsFixed(1) : ''}'),
        const SizedBox(height: 4),
        Text('Ref. Ther. : ${cp.rightInfo['Ref. Ther.'] ?? ''}'),
        Text('Ref. Ind.  : ${cp.rightInfo['Ref. Ind.'] ?? ''}'),
        Text('Bath       : ${cp.rightInfo['Bath'] ?? ''}'),
        Text('Immer.     : ${cp.rightInfo['Immer.'] ?? ''}'),
      ]),
    );
  }

  Widget _buildSummaryTable(CalibrationProvider prov) {
    final cps = prov.calPoints;
    return Table(
      border: TableBorder.all(color: Colors.black26),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.all(6), child: Text('Test Point', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('Standard Value (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('DUT Readout (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('Correction', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        for (var i = 0; i < cps.length; i++)
          (() {
            final cp = cps[i];
            final actualRefs = prov.computeThermCorrections(i);
            final meanActual = _meanFromList(actualRefs);
            final meanTest = _meanFromList(cp.testReadings);
            final correction = (meanActual != null && meanTest != null) ? (meanActual - meanTest) : null;
            return TableRow(children: [
              Padding(padding: const EdgeInsets.all(6), child: Text(cp.setting ?? '')),
              Padding(padding: const EdgeInsets.all(6), child: Text(meanActual != null ? meanActual.toStringAsFixed(1) : '')),
              Padding(padding: const EdgeInsets.all(6), child: Text(meanTest != null ? meanTest.toStringAsFixed(1) : '')),
              Padding(padding: const EdgeInsets.all(6), child: Text(correction != null ? correction.toStringAsFixed(1) : '')),
            ]);
          })(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CalibrationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Preview'),
        actions: [
          IconButton(
            tooltip: 'Generate PDF (disabled)',
            icon: const Icon(Icons.download),
            onPressed: () {
              // PDF generation intentionally left for later — show message
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generation not enabled yet.')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildHeaderBlock(prov),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // left column: environment and conditions
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _buildEnvironmentBlock(prov),
                const SizedBox(height: 8),
                _buildConditionBlock(prov),
                const SizedBox(height: 12),
                const Text('Cal Points (detailed)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Cal point cards (wrap)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(prov.calPoints.length, (i) => _buildCalPointCard(context, prov, i)),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CALIBRATED BY :'),
                    SizedBox(height: 10),
                    Text('Signature : ___________________'),
                    Text('Name      : ___________________'),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('VERIFIED BY :'),
                    SizedBox(height: 10),
                    Text('Signature : ___________________'),
                    Text('Name      : ___________________'),
                  ]),
                ]),
              ]),
            ),

            const SizedBox(width: 12),

            // right column: summary table + quick metadata
            Expanded(
              flex: 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Result of Calibration', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSummaryTable(prov),
                const SizedBox(height: 12),
                Text('DUT Resolution : ${prov.data.resolution ?? ''}'),
                const SizedBox(height: 6),
                Text('Range of Calibration : From -25°C to 300°C at 8 points'),
                const SizedBox(height: 12),
                const Text('Note : DUT = Device Under Test', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                const Text('Uncertainty: see lab note', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

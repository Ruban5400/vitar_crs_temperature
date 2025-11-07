// lib/screens/coc_preview_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';
import '../models/meter_entry.dart';

/// Clean, printable-looking Certificate of Calibration preview.
/// - No colors (white background)
/// - Left column: certificate header, submitted-by, instrument/environment/ref method, reference standard, signatures
/// - Right column: summary table (test points, standard value, DUT readout, correction)
class COCPreviewPage extends StatelessWidget {
  final List<MeterEntry> meterEntries;
  const COCPreviewPage({super.key, required this.meterEntries});

  double? _toDouble(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  double? _meanFromList(List<String?> list) {
    final nums = list.map((s) => _toDouble(s)).where((n) => n != null).map((e) => e!).toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  double? _meanFromActualRefs(List<String> actualRefs) {
    return _meanFromList(actualRefs.cast<String?>());
  }

  Widget _headerBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CERTIFICATE NO. : ${d.certificateNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Page : 1 of 2', style: const TextStyle(fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
      Text('Submitted By: ${d.customerName}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 12, runSpacing: 6, children: [
        Text('CMR No.: ${d.cmrNo}'),
        Text('Date Received: ${d.dateReceived}'),
        Text('Date Calibrated: ${d.dateCalibrated}'),
      ]),
      const SizedBox(height: 10),
    ]);
  }

  Widget _instrumentBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Instrument Description', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Description: ${d.instrument}'),
        Text('Make       : ${d.make}'),
        Text('Model      : ${d.model}'),
        Text('Serial No. : ${d.serialNo}'),
      ]),
    );
  }

  Widget _environmentBlock(CalibrationProvider prov) {
    final d = prov.data;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Environmental Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Ambient Temp. Max : ${d.ambientTempMax}')),
          Expanded(child: Text('Ambient Temp. Min : ${d.ambientTempMin}')),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Relative Humidity Max : ${d.relativeHumidityMax}')),
          Expanded(child: Text('Relative Humidity Min : ${d.relativeHumidityMin}')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Thermohygrometer : ${d.thermohygrometer}')),
          Expanded(child: Text('Resolution       : ${d.resolution}')),
        ]),
        const SizedBox(height: 6),
        Text('Ref. Method : ${d.refMethod}'),
        const SizedBox(height: 6),
        Text('Remarks     : ${d.remark}'),
      ]),
    );
  }

  /// Small reference-standard table (left column in your image)
  Widget _referenceStandardBlock() {
    // placeholder content — replace with real values if you have them in provider
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reference Standard', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Table(
          border: TableBorder.all(color: Colors.black12),
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
          children: const [
            TableRow(children: [
              Padding(padding: EdgeInsets.all(6), child: Text('Standard', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('ID No.')),
              Padding(padding: EdgeInsets.all(6), child: Text('Cert. No.')),
            ]),
            TableRow(children: [
              Padding(padding: EdgeInsets.all(6), child: Text('High Precision Calibrator')),
              Padding(padding: EdgeInsets.all(6), child: Text('ST-MC6-1')),
              Padding(padding: EdgeInsets.all(6), child: Text('MNIM-001')),
            ]),
            TableRow(children: [
              Padding(padding: EdgeInsets.all(6), child: Text('Standard Platinum Resistance Thermometer')),
              Padding(padding: EdgeInsets.all(6), child: Text('SPRT-1')),
              Padding(padding: EdgeInsets.all(6), child: Text('MNIM-002')),
            ]),
          ],
        ),
      ]),
    );
  }

  Widget _signaturesBlock() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('CALIBRATED BY :', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Signature : ___________________'),
          Text('Name      : ___________________'),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('APPROVED SIGNATORY :', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Signature : ___________________'),
          Text('Name      : ___________________'),
        ]),
      ]),
    );
  }

  Widget _summaryTable(CalibrationProvider prov) {
    final cps = prov.calPoints;
    return Table(
      border: TableBorder.all(color: Colors.black26),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.all(6), child: Text('Test Point', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('Standard Value (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('DUT Readout (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(6), child: Text('Correction (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        for (var i = 0; i < cps.length; i++)
          (() {
            final cp = cps[i];
            // compute actualRef mean and test mean
            final actualRefs = prov.computeThermCorrections(i);
            final meanActual = _meanFromActualRefs(actualRefs);
            final meanTest = _meanFromList(cp.testReadings);
            final correction = (meanActual != null && meanTest != null) ? (meanActual - meanTest) : null;
            return TableRow(children: [
              Padding(padding: const EdgeInsets.all(6), child: Text(cp.setting)),
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
    final prov = Provider.of<CalibrationProvider>(context, listen: true);

    // Note: keep this page read-only; do not mutate provider state here.
    // If you need computed fields persisted, call provider compute functions
    // before navigating to this page.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Preview'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          color: Colors.white, // plain white background
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Text('CERTIFICATE OF CALIBRATION', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // LEFT column: certificate details (wide)
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _headerBlock(prov),
                  const SizedBox(height: 10),
                  _instrumentBlock(prov),
                  const SizedBox(height: 10),
                  _environmentBlock(prov),
                  const SizedBox(height: 10),
                  const Text('Reference Method', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(prov.data.refMethod ?? ''),
                  const SizedBox(height: 10),
                  _referenceStandardBlock(),
                  _signaturesBlock(),
                ]),
              ),

              const SizedBox(width: 12),

              // RIGHT column: summary table + metadata
              Expanded(
                flex: 1,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Result of Calibration', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('DUT Resolution : ${prov.data.resolution ?? ''}'),
                      const SizedBox(height: 6),
                      const Text('Range of Calibration : From -25°C to 300°C at 8 points'),
                      const SizedBox(height: 6),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _summaryTable(prov),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Note 1: DUT = Device Under Test'),
                      SizedBox(height: 6),
                      Text('Note 2: Correction = Standard Value - DUT Readout'),
                    ]),
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

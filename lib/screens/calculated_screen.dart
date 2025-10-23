// lib/screens/detailed_report_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meter_entry.dart';
import '../providers/calibration_provider.dart';
import 'coc_preview_page.dart';

class DetailedReportPage extends StatefulWidget {
  final List<MeterEntry> meterEntries;
  final int startPageIndex;

  const DetailedReportPage({Key? key, required this.meterEntries, this.startPageIndex = 0}) : super(key: key);

  @override
  State<DetailedReportPage> createState() => _DetailedReportPageState();
}

class _DetailedReportPageState extends State<DetailedReportPage> {
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.startPageIndex;
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHeader(CalibrationProvider prov, int pageNumber, int totalPages) {
    final d = prov.data;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Cert. No. : ${d.certificateNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Serial No. : ${d.serialNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Page ${pageNumber + 1} / $totalPages'),
      ],
    );
  }

  /// Try to get a numeric "Reference Indicated" temperature from cal.rightInfo using several common keys.
  double? _findReferenceIndicatedValue(Map<String, String> rightInfo) {
    const keysToTry = [
      'Ref. Ind.',
      'Ref Ind.',
      'RefInd',
      'RefIndicated',
      'RefIndicatedTemp',
      'IndicatedTemp',
      'ReferenceIndicated',
      'ReferenceTemp',
      'Indicated',
      'Ref. Ind',
      'RefInd',
    ];
    for (final key in keysToTry) {
      if (rightInfo.containsKey(key)) {
        final v = rightInfo[key]!.trim();
        if (v.isEmpty) continue;
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    // If not found in those common keys, also try any key whose value parses as double.
    for (final entry in rightInfo.entries) {
      final parsed = double.tryParse(entry.value.trim());
      if (parsed != null) return parsed;
    }
    return null;
  }


  Widget _buildCalPointBlock(BuildContext context, int calIndex, List<MeterEntry> meterEntries) {
    final prov = Provider.of<CalibrationProvider>(context, listen: false);
    final cal = prov.calPoints[calIndex];

    // fallback mapping for display only (do not overwrite provider values)
    final int base = calIndex;
    MeterEntry? m;
    if (widget.meterEntries.length > base) m = widget.meterEntries[base];

    final List<double> refValues = [];

    // try to get a reference-indicated temperature (used to compute Difference = ReferenceIndicated - TestActual)
    double? referenceIndicatedFromRightInfo;
    // try common keys first
    final candidates = ['Ref. Ind.', 'Ref Ind.', 'RefInd', 'RefIndicated', 'Ref Ind', 'Ref.Ind'];
    for (final k in candidates) {
      if (cal.rightInfo.containsKey(k)) {
        final s = cal.rightInfo[k]!.trim();
        if (s.isNotEmpty) referenceIndicatedFromRightInfo = double.tryParse(s);
      }
    }
    // fallback: any numeric in rightInfo
    if (referenceIndicatedFromRightInfo == null) {
      for (final e in cal.rightInfo.entries) {
        final p = double.tryParse(e.value.trim());
        if (p != null) {
          referenceIndicatedFromRightInfo = p;
          break;
        }
      }
    }

    // DEBUG: uncomment to print testReadings to console when block builds
    // debugPrint('CalPoint $calIndex testReadings: ${cal.testReadings}');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Cal. Point : ${calIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Setting: ${cal.setting}    Bath: ${cal.rightInfo['Bath'] ?? ''}    Immer: ${cal.rightInfo['Immer.'] ?? ''}'),
          ]),
          const SizedBox(height: 8),

          // HEADERS
          Row(children: const [
            Expanded(child: Text('Reference Reading')),
            SizedBox(width: 8),
            Expanded(child: Text('Meter Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Ther. Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Actual Ref')),
            SizedBox(width: 8),
            Expanded(child: Text('Test Reading')),
            SizedBox(width: 8),
            Expanded(child: Text('Meter Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Test Actual')),
            SizedBox(width: 8),
            Expanded(child: Text('Difference')),
            SizedBox(width: 8),
          ]),
          const Divider(),

          // 6 rows
          ...List.generate(6, (r) {
            // Reference (provider preferred)
            final providerRef = (r < cal.refReadings.length) ? cal.refReadings[r] : '';
            String refDisplay = '';
            if (providerRef.trim().isNotEmpty) {
              refDisplay = providerRef.trim();
            } else if (m != null) {
              refDisplay = (r % 2 == 0) ? m.lowerValue.toStringAsFixed(4) : m.upperValue.toStringAsFixed(4);
            }

            // add for average calc
            final refNum = double.tryParse(refDisplay);
            if (refNum != null) refValues.add(refNum);

            // Meter Corr (computed list preferred)
            String meterCorr = '';
            if (cal.meterCorrPerRow.isNotEmpty && cal.meterCorrPerRow[r].isNotEmpty) {
              meterCorr = cal.meterCorrPerRow[r];
            } else if (m != null) {
              meterCorr = (r % 2 == 0 ? m.lowerCorrection : m.upperCorrection).toStringAsFixed(4);
            }

            // Reference Indicated (Ther. Corr.) - compute as ref + meterCorr
            String refIndStr = '';
            final parsedRef = double.tryParse(refDisplay);
            final parsedMeterCorr = double.tryParse(meterCorr);
            if (parsedRef != null && parsedMeterCorr != null) {
              refIndStr = (parsedRef + parsedMeterCorr).toStringAsFixed(4);
            } else {
              refIndStr = ''; // fallback if parsing fails
            }


            // Actual Ref (your new column)
            final List<String> actualRefs = prov.computeThermCorrections(calIndex);
            String actualRefStr = '';
            if (r < actualRefs.length) actualRefStr = actualRefs[r];

            // Test Reading (user-entered) - show raw string if non-numeric
            final rawTest = (r < cal.testReadings.length) ? cal.testReadings[r].trim() : '';
            String testReadingDisplay = rawTest;
            // Calculate Test Actual as numeric if possible
            String testActualStr = '';
            final parsedTest = double.tryParse(rawTest);
            // testCorr is always 0.0000
            const testCorrStr = '0.0000';
            if (parsedTest != null) {
              testActualStr = (parsedTest + 0.0).toStringAsFixed(4); // numeric formatting
            } else if (rawTest.isNotEmpty) {
              // display raw as-is (non-numeric)
              testActualStr = rawTest;
            }

            // Difference = Reference Indicated - Test Actual (if numeric)
            // Difference = Actual Ref - Actual Test (if numeric)
            String differenceStr = '';
            final parsedActualRef = double.tryParse(actualRefStr);
            final parsedTestAct = double.tryParse(testActualStr);
            if (parsedActualRef != null && parsedTestAct != null) {
              differenceStr = (parsedActualRef - parsedTestAct).toStringAsFixed(4);
            }


            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(children: [
                Expanded(child: Text(refDisplay, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(meterCorr, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(child: Text(refIndStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(actualRefStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testReadingDisplay, textAlign: TextAlign.left)), // <- Test Reading visible here
                const SizedBox(width: 8),
                Expanded(child: const Text(testCorrStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testActualStr, textAlign: TextAlign.left)), // <- Test Actual visible here
                const SizedBox(width: 8),
                Expanded(child: Text(differenceStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
              ]),
            );
          }),

          const Divider(),

          // Average row
          Builder(builder: (_) {
            if (refValues.isEmpty) return const SizedBox();
            final avg = refValues.reduce((a, b) => a + b) / refValues.length;
            final computed = cal.meterCorrPerRow.isNotEmpty ? cal.meterCorrPerRow[0] : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(children: [
                Expanded(child: Text('Average: ${avg.toStringAsFixed(8)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(computed.isNotEmpty ? 'Meter Corr: $computed' : '', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                const Expanded(child: Text('')),
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // test reading avg left empty
                const SizedBox(width: 8),
                const Expanded(child: Text('0.0000')),
                const SizedBox(width: 8),
                const Expanded(child: Text('')),
                const SizedBox(width: 8),
                const Expanded(child: Text('')),
                const SizedBox(width: 8),
              ]),
            );
          }),

          const SizedBox(height: 6),
          Row(children: [
            Text('Ref. Ther. Used: ${cal.rightInfo['Ref. Ther.'] ?? ''}'),
            const SizedBox(width: 24),
            Text('Ref. Ind. Used: ${cal.rightInfo['Ref. Ind.'] ?? ''}'),
          ]),
        ]),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CalibrationProvider>(context, listen: false);
    final pages = <Widget>[
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 0, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 0, widget.meterEntries),
            _buildCalPointBlock(ctx, 1, widget.meterEntries),
            _buildCalPointBlock(ctx, 2, widget.meterEntries),
          ]),
        );
      }),
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 1, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 3, widget.meterEntries),
            _buildCalPointBlock(ctx, 4, widget.meterEntries),
            _buildCalPointBlock(ctx, 5, widget.meterEntries),
          ]),
        );
      }),
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 2, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 6, widget.meterEntries),
            _buildCalPointBlock(ctx, 7, widget.meterEntries),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CALIBRATED BY :'),
                SizedBox(height: 8),
                Text('Signature : ___________________'),
                Text('Name      : ___________________'),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('VERIFIED BY :'),
                SizedBox(height: 8),
                Text('Signature : ___________________'),
                Text('Name      : ___________________'),
              ]),
            ]),
          ]),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Calculation Report')),
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (c, i) => pages[i],
          ),
        ),
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Page ${_current + 1} of ${pages.length}'),
            Row(children: [
              IconButton(
                tooltip: 'Previous page',
                icon: const Icon(Icons.chevron_left),
                onPressed: _current > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null,
              ),
              IconButton(
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right),
                onPressed: _current < pages.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null,
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // navigate to preview first, then user can download from there
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => COCPreviewPage(meterEntries: widget.meterEntries),
                    ),
                  );
                },

                child: const Text('Preview COC'),
              )
            ]),
          ]),
        )
      ]),
    );
  }
}

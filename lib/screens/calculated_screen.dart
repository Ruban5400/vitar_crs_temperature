// lib/screens/detailed_report_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meter_entry.dart';
import '../providers/calibration_provider.dart';

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

  // Widget _buildCalPointBlock(BuildContext context, int calIndex, List<MeterEntry> meterEntries) {
  //   final prov = Provider.of<CalibrationProvider>(context, listen: false);
  //   final cal = prov.calPoints[calIndex];
  //
  //   // fallback mapping for display only (do not overwrite provider values)
  //   final int base = calIndex;
  //   MeterEntry? m;
  //   if (widget.meterEntries.length > base) m = widget.meterEntries[base];
  //
  //   final List<double> refValues = [];
  //
  //   // try to get a reference-indicated temperature (used to compute Difference = ReferenceIndicated - TestActual)
  //   final double? referenceIndicatedFromRightInfo = _findReferenceIndicatedValue(cal.rightInfo);
  //
  //   return Card(
  //     elevation: 2,
  //     margin: const EdgeInsets.symmetric(vertical: 8),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  //           Text('Cal. Point : ${calIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
  //           Text('Setting: ${cal.setting}    Bath: ${cal.rightInfo['Bath'] ?? ''}    Immer: ${cal.rightInfo['Immer.'] ?? ''}'),
  //         ]),
  //         const SizedBox(height: 8),
  //
  //         // HEADERS (Reference | Meter Corr | Ther Corr (Actual Ref Indicated) | Test Reading | Test Corr | Test Actual | Difference)
  //         Row(children: const [
  //           Expanded(child: Text('Reference Reading')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Meter Corr.')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Ther. Corr. / Ref Ind.')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Test Reading')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Test Corr.')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Test Actual')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Difference')),
  //           SizedBox(width: 8),
  //         ]),
  //         const Divider(),
  //
  //         // 6 rows - PRESERVE provider refReadings; fallback to meter table only if provider value empty
  //         ...List.generate(6, (r) {
  //           // Reference display (user-entered preferred)
  //           final providerRef = (r < cal.refReadings.length) ? cal.refReadings[r] : '';
  //           String refDisplay = '';
  //           if (providerRef.trim().isNotEmpty) {
  //             refDisplay = providerRef.trim();
  //           } else if (m != null) {
  //             refDisplay = (r % 2 == 0) ? m.lowerValue.toStringAsFixed(4) : m.upperValue.toStringAsFixed(4);
  //           }
  //
  //           // collect numeric for average (but we do not write back to provider)
  //           final refNum = double.tryParse(refDisplay);
  //           if (refNum != null) refValues.add(refNum);
  //
  //           // Meter correction shown for each row (computed per-row value preferred)
  //           String meterCorr = '';
  //           if (cal.meterCorrPerRow.isNotEmpty && cal.meterCorrPerRow[r].isNotEmpty) {
  //             meterCorr = cal.meterCorrPerRow[r];
  //           } else if (m != null) {
  //             meterCorr = (r % 2 == 0 ? m.lowerCorrection : m.upperCorrection).toStringAsFixed(4);
  //           }
  //
  //           // "Ther. Corr." / Reference Indicated value (if you already compute it and store somewhere):
  //           // We try to read from cal.rightInfo using common keys; if not available, leave blank.
  //           // (If you have an explicit conversion to temperature, replace this section with your conversion logic.)
  //           String refIndicatedStr = '';
  //           final possibleRefIndicated = referenceIndicatedFromRightInfo;
  //           if (possibleRefIndicated != null) {
  //             // If the stored reference-indicated is a single value, show it for all rows (as in sample)
  //             refIndicatedStr = possibleRefIndicated.toStringAsFixed(4);
  //           } else {
  //             // If you compute "indicated" from refDisplay + some thermCorr, implement that formula here.
  //             // For now leave blank.
  //             refIndicatedStr = '';
  //           }
  //
  //           // Test reading (user-entered)
  //           final testReadingRaw = (r < cal.testReadings.length) ? cal.testReadings[r].trim() : '';
  //           final testReading = testReadingRaw.isNotEmpty ? testReadingRaw : ''; // display as-is
  //
  //           // Test corr always 0.0000 (per your rule)
  //           const testCorrStr = '0.0000';
  //
  //           // Test Actual = testReading + testCorr (numerical). Since testCorr is 0, this is testReading itself.
  //           String testActualStr = '';
  //           final parsedTest = double.tryParse(testReading);
  //           if (parsedTest != null) {
  //             // add testCorr (0.0) to parsedTest
  //             testActualStr = (parsedTest + 0.0).toStringAsFixed(4);
  //           }
  //
  //           // Difference = Reference Indicated - Test Actual (matching sample: Ref - Test)
  //           String differenceStr = '';
  //           if (refIndicatedStr.isNotEmpty && testActualStr.isNotEmpty) {
  //             final parsedRefInd = double.tryParse(refIndicatedStr);
  //             final parsedTestAct = double.tryParse(testActualStr);
  //             if (parsedRefInd != null && parsedTestAct != null) {
  //               final diff = parsedRefInd - parsedTestAct;
  //               differenceStr = diff.toStringAsFixed(4);
  //             }
  //           }
  //
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 2.0),
  //             child: Row(children: [
  //               Expanded(child: Text(refDisplay, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(meterCorr, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600))),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(refIndicatedStr, textAlign: TextAlign.left)), // Therm. Corr. / Ref Ind.
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(testReading, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: const Text(testCorrStr, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(testActualStr, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(differenceStr, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //             ]),
  //           );
  //         }),
  //
  //         const Divider(),
  //
  //         // Average row (does not override reference readings)
  //         Builder(builder: (_) {
  //           if (refValues.isEmpty) return const SizedBox();
  //           final avg = refValues.reduce((a, b) => a + b) / refValues.length;
  //           final computed = cal.meterCorrPerRow.isNotEmpty ? cal.meterCorrPerRow[0] : '';
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 4.0),
  //             child: Row(children: [
  //               Expanded(child: Text('Average: ${avg.toStringAsFixed(8)}', style: const TextStyle(fontWeight: FontWeight.bold))),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(computed.isNotEmpty ? 'Meter Corr: $computed' : '', style: const TextStyle(fontWeight: FontWeight.bold))),
  //               const SizedBox(width: 8),
  //               const Expanded(child: Text('')), // therm corr / ref indicated for average (left blank)
  //               const SizedBox(width: 8),
  //               const Expanded(child: Text('')), // test reading average (optional)
  //               const SizedBox(width: 8),
  //               const Expanded(child: Text('')), // test corr
  //               const SizedBox(width: 8),
  //               const Expanded(child: Text('')), // test actual avg if desired
  //               const SizedBox(width: 8),
  //               const Expanded(child: Text('')), // difference
  //               const SizedBox(width: 8),
  //             ]),
  //           );
  //         }),
  //
  //         const SizedBox(height: 6),
  //         Row(children: [
  //           Text('Ref. Ther. Used: ${cal.rightInfo['Ref. Ther.'] ?? ''}'),
  //           const SizedBox(width: 24),
  //           Text('Ref. Ind. Used: ${cal.rightInfo['Ref. Ind.'] ?? ''}'),
  //         ]),
  //       ]),
  //     ),
  //   );
  // }

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

            // Reference Indicated (therm corr) - reused same for all rows if found
            final refIndStr = referenceIndicatedFromRightInfo != null ? referenceIndicatedFromRightInfo.toStringAsFixed(4) : '';

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
            String differenceStr = '';
            final parsedRefInd = double.tryParse(refIndStr);
            final parsedTestAct = double.tryParse(testActualStr);
            if (parsedRefInd != null && parsedTestAct != null) {
              differenceStr = (parsedRefInd - parsedTestAct).toStringAsFixed(4);
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
                  showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Saved'), content: const Text('Report prepared (in-memory).'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
                },
                child: const Text('Save/Export'),
              )
            ]),
          ]),
        )
      ]),
    );
  }
}

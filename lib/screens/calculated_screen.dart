// filename: lib/screens/detailed_report_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitar_crs_temperature/models/meter_entry.dart';
import 'package:vitar_crs_temperature/providers/calibration_provider.dart';
import 'coc_preview_page.dart';

class DetailedReportPage extends StatefulWidget {
  final List<MeterEntry> meterEntries;
  final int startPageIndex;

  const DetailedReportPage({
    Key? key,
    required this.meterEntries,
    this.startPageIndex = 0,
  }) : super(key: key);

  @override
  State<DetailedReportPage> createState() => _DetailedReportPageState();
}

class _DetailedReportPageState extends State<DetailedReportPage> {
  late final PageController _pageController;
  late int _current;

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

  Widget _buildCalPointBlock(BuildContext context, int calIndex) {
    final prov = context.read<CalibrationProvider>();
    final cal = prov.calPoints[calIndex];

    // fallback mapping for display only (do not overwrite provider values)
    final int base = calIndex;
    MeterEntry? m;
    if (widget.meterEntries.length > base) m = widget.meterEntries[base];

    // try to get a numeric reference indicated value from rightInfo
    double? referenceIndicatedFromRightInfo;
    const candidates = ['Ref. Ind.', 'Ref Ind.', 'RefInd', 'RefIndicated', 'Ref Ind', 'Ref.Ind'];
    for (final k in candidates) {
      if (cal.rightInfo.containsKey(k)) {
        final s = cal.rightInfo[k]!.trim();
        if (s.isNotEmpty) {
          referenceIndicatedFromRightInfo = double.tryParse(s);
          if (referenceIndicatedFromRightInfo != null) break;
        }
      }
    }
    if (referenceIndicatedFromRightInfo == null) {
      for (final e in cal.rightInfo.entries) {
        final p = double.tryParse(e.value.trim());
        if (p != null) {
          referenceIndicatedFromRightInfo = p;
          break;
        }
      }
    }

    // ONLY compute thermFallback if user has entered any reference readings for this cal point
    final bool hasAnyUserRef = cal.refReadings.any((s) => s.trim().isNotEmpty);
    List<String>? thermFallback;
    if (hasAnyUserRef) {
      thermFallback = prov.computeTherCorrections(calIndex);
    }

    // Collect reference numeric values to compute average at end of block (only user-entered refs)
    final List<double> refValues = <double>[];

    String _formatNullableDouble(double? v, {int frac = 4}) {
      if (v == null) return '';
      return v.toStringAsFixed(frac);
    }

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
          const Row(children: [
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
            // Reference (provider only — NO fallback to meterEntries)
            final providerRef = (r < cal.refReadings.length) ? cal.refReadings[r].trim() : '';
            String refDisplay = '';
            if (providerRef.isNotEmpty) {
              refDisplay = providerRef;
            } else {
              // intentionally leave blank if user didn't enter value
              refDisplay = '';
            }

            final refNum = double.tryParse(refDisplay);
            if (refNum != null) refValues.add(refNum);

            // Meter Corr (only if provider computed it for that row)
            String meterCorr = '';
            if (cal.meterCorrPerRow.isNotEmpty && r < cal.meterCorrPerRow.length && cal.meterCorrPerRow[r].isNotEmpty) {
              meterCorr = cal.meterCorrPerRow[r];
            } else {
              // no user data => leave blank (no fallback to m.lower/upper)
              meterCorr = '';
            }

            // Reference Indicated (Ther. Corr.) = ref + meterCorr if numeric
            String refIndStr = '';
            final parsedRef = double.tryParse(refDisplay);
            final parsedMeterCorr = double.tryParse(meterCorr);
            if (parsedRef != null && parsedMeterCorr != null) {
              refIndStr = (parsedRef + parsedMeterCorr).toStringAsFixed(4);
            } else if (referenceIndicatedFromRightInfo != null) {
              // if user has provided an explicit indicated reference (rightInfo), show it
              refIndStr = referenceIndicatedFromRightInfo.toStringAsFixed(4);
            } else {
              refIndStr = '';
            }

            // Actual Ref (prefer cal.actualRefPerRow stored values; fallback to thermFallback only if thermFallback computed)
            String actualRefStr = '';
            if (cal.actualRefPerRow.isNotEmpty && r < cal.actualRefPerRow.length && cal.actualRefPerRow[r].isNotEmpty) {
              actualRefStr = cal.actualRefPerRow[r];
            } else if (thermFallback != null && r < thermFallback.length && thermFallback[r].isNotEmpty) {
              actualRefStr = thermFallback[r];
            } else {
              actualRefStr = '';
            }

            // Test Reading (user-entered only)
            final rawTest = (r < cal.testReadings.length) ? cal.testReadings[r].trim() : '';
            String testActualStr = '';
            const testCorrStr = '0.0000';
            final parsedTest = double.tryParse(rawTest);
            if (parsedTest != null) {
              testActualStr = parsedTest.toStringAsFixed(4);
            } else if (rawTest.isNotEmpty) {
              testActualStr = rawTest; // show raw if non-numeric
            } else {
              testActualStr = '';
            }

            // Difference = Actual Ref - Test Actual (if both numeric)
            String differenceStr = '';
            final parsedActualRef = double.tryParse(actualRefStr);
            final parsedTestAct = double.tryParse(testActualStr);
            if (parsedActualRef != null && parsedTestAct != null) {
              differenceStr = (parsedActualRef - parsedTestAct).toStringAsFixed(4);
            } else {
              differenceStr = '';
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
                Expanded(child: Text(rawTest, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testCorrStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testActualStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(differenceStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
              ]),
            );
          }),

          const Divider(),

          // Average row — only show if there are user-entered numeric refs
          Builder(builder: (_) {
            if (refValues.isEmpty) return const SizedBox.shrink();
            final avg = refValues.reduce((a, b) => a + b) / refValues.length;
            final computed = (cal.meterCorrPerRow.isNotEmpty && cal.meterCorrPerRow[0].isNotEmpty) ? cal.meterCorrPerRow[0] : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(children: [
                Expanded(child: Text('Average: ${avg.toStringAsFixed(8)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(computed.isNotEmpty ? 'Meter Corr: $computed' : '', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                const Expanded(child: Text('')),
                const SizedBox(width: 8),
                const Expanded(child: Text('')),
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
    final prov = context.read<CalibrationProvider>();

    final pages = <Widget>[
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 0, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 0),
            _buildCalPointBlock(ctx, 1),
            _buildCalPointBlock(ctx, 2),
          ]),
        );
      }),
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 1, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 3),
            _buildCalPointBlock(ctx, 4),
            _buildCalPointBlock(ctx, 5),
          ]),
        );
      }),
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 2, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 6),
            _buildCalPointBlock(ctx, 7),
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
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => COCPreviewPage(meterEntries: widget.meterEntries),
                      ),
                    );
                  }
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

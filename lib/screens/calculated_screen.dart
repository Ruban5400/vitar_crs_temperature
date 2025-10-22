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

  Widget _buildCalPointBlock(BuildContext context, int calIndex, List<MeterEntry> meterEntries) {
    final prov = Provider.of<CalibrationProvider>(context, listen: false);
    final cal = prov.calPoints[calIndex];

    // Try to find a meter entry mapping for fallback display (do not overwrite provider values)
    final int base = calIndex; // simple base; we use meterEntries only as fallback display
    MeterEntry? m;
    if (widget.meterEntries.length > base) m = widget.meterEntries[base];

    final List<double> refValues = [];

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
          Row(children: const [
            Expanded(child: Text('Reference Reading')),
            SizedBox(width: 8),
            Expanded(child: Text('Meter Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Ther Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Test Before Adj')),
            SizedBox(width: 8),
          ]),
          const Divider(),

          // 6 rows - PRESERVE provider refReadings; only fall back to meterEntries if provider value empty
          ...List.generate(6, (r) {
            final providerRef = (r < cal.refReadings.length) ? cal.refReadings[r] : '';
            String refDisplay = '';
            if (providerRef.trim().isNotEmpty) {
              refDisplay = providerRef;
            } else if (m != null) {
              // fallback mapping (non-destructive)
              refDisplay = (r % 2 == 0) ? m.lowerValue.toStringAsFixed(4) : m.upperValue.toStringAsFixed(4);
            }

            final refNum = double.tryParse(refDisplay);
            if (refNum != null) refValues.add(refNum);

            final testVal = (r < cal.testReadings.length) ? cal.testReadings[r] : '';

            // determine meterCorr: prefer computed per-row value from CalPoint, else fallback to per-row meter table corrections
            String meterCorr = '';
            if (cal.meterCorrPerRow.isNotEmpty && cal.meterCorrPerRow[r].isNotEmpty) {
              meterCorr = cal.meterCorrPerRow[r];
            } else if (m != null) {
              meterCorr = (r % 2 == 0 ? m.lowerCorrection : m.upperCorrection).toStringAsFixed(4);
            }

            final actualStr = (refDisplay.isNotEmpty && meterCorr.isNotEmpty)
                ? ((double.tryParse(refDisplay) ?? 0.0) + (double.tryParse(meterCorr) ?? 0.0)).toStringAsFixed(4)
                : '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(children: [
                Expanded(child: Text(refDisplay, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(meterCorr, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(child: Text(actualStr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testVal, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
              ]),
            );
          }),

          const Divider(),

          // Average row (does not override reference readings)
          Builder(builder: (_) {
            if (refValues.isEmpty) return const SizedBox();
            final avg = refValues.reduce((a, b) => a + b) / refValues.length;
            // show avg and also the computed meterCorr if present
            final computed = cal.meterCorrPerRow.isNotEmpty ? cal.meterCorrPerRow[0] : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(children: [
                Expanded(child: Text('Average: ${avg.toStringAsFixed(8)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(computed.isNotEmpty ? 'Meter Corr: $computed' : '', style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // actual
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // test
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

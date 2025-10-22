import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meter_entry.dart';
import '../providers/calibration_provider.dart';

class DetailedReportPage extends StatefulWidget {
  final List<MeterEntry> meterEntries;
  final int startPageIndex; // optional to start at a specific page

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

  /// Build the per-cal-point block. It will read Reference Readings from meterEntries
  /// by using a simple mapping: calPoint index -> meter rows slice.
  /// If your meterEntries map differently adjust the mapping logic as needed.
  // Widget _buildCalPointBlock(BuildContext context, int calIndex, List<MeterEntry> meterEntries) {
  //   final prov = Provider.of<CalibrationProvider>(context, listen: false);
  //   final cal = prov.calPoints[calIndex];
  //
  //   // For demo we map reference readings to these values:
  //   // If meterEntries length matches exactly 12*? or so you may need custom mapping.
  //   // Here we simply try to use meterEntries[calIndex*? ..] fallback to cal.refReadings if missing.
  //   // Adjust as per your table layout.
  //   final int base = calIndex * 1; // simple direct mapping: one meterEntry per calPoint
  //   MeterEntry? m;
  //   if (widget.meterEntries.length > base) m = widget.meterEntries[base];
  //
  //   // build the small table: Reference | Corr | Actual | Test columns (Test columns come from cal.testReadings)
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
  //         // Row headers
  //         Row(children: const [
  //           Expanded(child: Text('Reference Reading')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Meter Corr.')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Actual')),
  //           SizedBox(width: 8),
  //           Expanded(child: Text('Test Before Adj')),
  //           SizedBox(width: 8),
  //         ]),
  //         const Divider(),
  //         // We'll show up to 6 rows: prefer provider cal.refReadings if meter entry unavailable,
  //         ...List.generate(6, (r) {
  //           final refFromCal = (r < cal.refReadings.length) ? cal.refReadings[r] : '';
  //           String refDisplay = refFromCal;
  //           // If meterEntry exists we can map some values (example mapping below)
  //           if (m != null) {
  //             // example: show meter lowerValue and/or upperValue as reference depending on row
  //             // this is placeholder mapping; replace with your real mapping rules
  //             if (r % 2 == 0) {
  //               refDisplay = m.lowerValue.toStringAsFixed(4);
  //             } else {
  //               refDisplay = m.upperValue.toStringAsFixed(4);
  //             }
  //           }
  //           final testVal = (r < cal.testReadings.length) ? cal.testReadings[r] : '';
  //           final meterCorr = m != null ? (r % 2 == 0 ? m.lowerCorrection : m.upperCorrection).toStringAsFixed(4) : '';
  //           final actual = refDisplay.isNotEmpty && meterCorr.isNotEmpty
  //               ? (double.tryParse(refDisplay) ?? 0.0) + (double.tryParse(meterCorr) ?? 0.0)
  //               : '';
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 2.0),
  //             child: Row(children: [
  //               Expanded(child: Text(refDisplay, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(meterCorr, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(actual is String ? actual : (actual as double).toStringAsFixed(4), textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //               Expanded(child: Text(testVal, textAlign: TextAlign.left)),
  //               const SizedBox(width: 8),
  //             ]),
  //           );
  //         }),
  //         const SizedBox(height: 6),
  //         // footer: Ref. Ther used etc (use cal.rightInfo)
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

    final int base = calIndex * 1;
    MeterEntry? m;
    if (widget.meterEntries.length > base) m = widget.meterEntries[base];

    // We'll collect reference readings as doubles for averaging
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

          // Row headers
          Row(children: const [
            Expanded(child: Text('Reference Reading')),
            SizedBox(width: 8),
            Expanded(child: Text('Meter Corr.')),
            SizedBox(width: 8),
            Expanded(child: Text('Actual')),
            SizedBox(width: 8),
            Expanded(child: Text('Test Before Adj')),
            SizedBox(width: 8),
          ]),
          const Divider(),

          // The 6 data rows
          ...List.generate(6, (r) {
            final refFromCal = (r < cal.refReadings.length) ? cal.refReadings[r] : '';
            String refDisplay = refFromCal;
            if (m != null) {
              if (r % 2 == 0) {
                refDisplay = m.lowerValue.toStringAsFixed(4);
              } else {
                refDisplay = m.upperValue.toStringAsFixed(4);
              }
            }

            final refNum = double.tryParse(refDisplay);
            if (refNum != null) refValues.add(refNum);

            final testVal = (r < cal.testReadings.length) ? cal.testReadings[r] : '';
            final meterCorr = m != null ? (r % 2 == 0 ? m.lowerCorrection : m.upperCorrection).toStringAsFixed(4) : '';
            final actual = refDisplay.isNotEmpty && meterCorr.isNotEmpty
                ? (double.tryParse(refDisplay) ?? 0.0) + (double.tryParse(meterCorr) ?? 0.0)
                : '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(children: [
                Expanded(child: Text(refDisplay, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(meterCorr, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(actual is String
                        ? actual
                        : (actual as double).toStringAsFixed(4),
                        textAlign: TextAlign.left)),
                const SizedBox(width: 8),
                Expanded(child: Text(testVal, textAlign: TextAlign.left)),
                const SizedBox(width: 8),
              ]),
            );
          }),

          const Divider(),

          // NEW: Average row
          Builder(builder: (_) {
            if (refValues.isEmpty) return const SizedBox();
            final avg = refValues.reduce((a, b) => a + b) / refValues.length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(children: [
                Expanded(
                    child: Text('Average: ${avg.toStringAsFixed(8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // empty Meter Corr.
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // empty Actual
                const SizedBox(width: 8),
                const Expanded(child: Text('')), // empty Test
                const SizedBox(width: 8),
              ]),
            );
          }),

          const SizedBox(height: 6),

          // footer
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
    // We'll make 3 pages: page0 contains header + cal points 1-3,
    // page1 contains cal points 4-6, page2 contains cal points 7-8 + signatures
    final pages = <Widget>[
      // Page 1 (cal points 1..3)
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
      // Page 2 (cal points 4..6)
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
      // Page 3 (cal points 7..8 and signatures)
      Builder(builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(prov, 2, 3),
            const SizedBox(height: 12),
            _buildCalPointBlock(ctx, 6, widget.meterEntries),
            _buildCalPointBlock(ctx, 7, widget.meterEntries),
            const SizedBox(height: 24),
            // signature boxes
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('CALIBRATED BY :'),
                SizedBox(height: 8),
                Text('Signature : ___________________'),
                Text('Name      : ___________________'),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
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
      appBar: AppBar(
        title: const Text('Detailed Calculation Report'),
      ),
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
                  // save/export action (placeholder)
                  showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Saved'), content: const Text('Report prepared (in-memory).'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
                },
                child: const Text('Save/Export'),
              )
            ])
          ]),
        )
      ]),
    );
  }
}
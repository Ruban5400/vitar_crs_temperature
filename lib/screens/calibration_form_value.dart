import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitar_crs_temperature/screens/summary.dart';

import '../providers/calibration_provider.dart';
import '../providers/meter_provider.dart';
import 'calculated_screen.dart';

class CalibrationFormPage extends StatelessWidget {
  const CalibrationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration Form (Cal Points)'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Serial header (binds to provider.data.serialNo)
              Consumer<CalibrationProvider>(
                builder: (context, prov, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Serial No.  :  ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: prov.data.serialNo,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
                            onChanged: (v) => prov.updateField('SerialNo', v),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // grid of 8 cal point cards (2 columns)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(8, (i) {
                      return SizedBox(
                        width: itemWidth,
                        child: CalPointCard(index: i),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: SignatureBox(title: 'Calibrated by :')),
                  SizedBox(width: 12),
                  Expanded(child: SignatureBox(title: 'Verified by :')),
                ],
              ),
              const SizedBox(height: 12),

              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailedReportPage()));
              //   },
              //   child: const Padding(padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0), child: Text('Continue to Summary')),
              // )
              // directly passing values without calculation
              // ElevatedButton(
              //   onPressed: () async {
              //     // show loader while fetching
              //     showDialog(
              //       context: context,
              //       builder: (_) => const Center(child: CircularProgressIndicator()),
              //       barrierDismissible: false,
              //     );
              //
              //     try {
              //       // Example: fetch via provider/service - adjust to your code
              //       final rows = await Provider.of<MeterProvider>(context, listen: false).fetchAll();
              //       // close loader
              //       Navigator.of(context).pop();
              //       // navigate and pass the rows
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(builder: (_) => DetailedReportPage(meterEntries: rows)),
              //       );
              //     } catch (e) {
              //       Navigator.of(context).pop();
              //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load meter rows: $e')));
              //     }
              //   },
              //   child: const Text('Continue to Calculation'),
              // )
              // cal page with 'reference val and mean of them'
              ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<CalibrationProvider>(
                    context,
                    listen: false,
                  );

                  // 1) compute meter corrections from the 6 ref readings per cal point
                  provider.computeAndStoreMeterCorrections();

                  // 2) (optional) If you also want to update Supabase records (see next section),
                  //    you can call your service here.

                  // 3) if you have a MeterProvider or Supabase fetch, get the table rows to pass to report
                  final rows = Provider.of<MeterProvider>(
                    context,
                    listen: false,
                  ).rows; // or fetchAll()
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailedReportPage(meterEntries: rows),
                    ),
                  );
                },
                child: const Text('Continue to Calculation'),
              ),

              //
              //
              // ElevatedButton(
              //   onPressed: () async {
              //     final meterProv = Provider.of<MeterProvider>(
              //       context,
              //       listen: false,
              //     ); // or your service
              //     final calProv = Provider.of<CalibrationProvider>(
              //       context,
              //       listen: false,
              //     );
              //
              //     // show loader
              //     showDialog(
              //       context: context,
              //       barrierDismissible: false,
              //       builder: (_) =>
              //           const Center(child: CircularProgressIndicator()),
              //     );
              //
              //     try {
              //       // ensure meter table is loaded
              //       final table = await meterProv
              //           .fetchAll(); // returns List<MeterEntry>
              //
              //       // compute and store meter corrections into provider.calPoints[].rightInfo['Meter Corr.']
              //       calProv.computeAndStoreMeterCorrectionsFromTable(table);
              //
              //       Navigator.of(context).pop(); // remove loader
              //
              //       // now navigate and pass table if you still need it in the report (you can pick either)
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) => DetailedReportPage(meterEntries: table),
              //         ),
              //       );
              //     } catch (e) {
              //       Navigator.of(context).pop();
              //       ScaffoldMessenger.of(
              //         context,
              //       ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              //     }
              //   },
              //   child: const Text('Continue to Calculation'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalPointCard extends StatelessWidget {
  final int index;
  const CalPointCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context);
    final data = provider.calPoints[index];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cal. Point : ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Setting',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    TextFormField(
                      initialValue: data.setting,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) =>
                          provider.updateCalPointSetting(index, v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left: ref/test table
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Ref.\\nReading',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Test\\nReading',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 8, thickness: 1),
                      ...List.generate(6, (r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              // ref
                              Expanded(
                                child: TextFormField(
                                  initialValue: data.refReadings[r],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) =>
                                      provider.updateRefReading(index, r, v),
                                ),
                              ),
                              // test
                              Expanded(
                                child: TextFormField(
                                  initialValue: data.testReadings[r],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) =>
                                      provider.updateTestReading(index, r, v),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),
              // right: reference info column
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in data.rightInfo.keys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: Text(key)),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                initialValue: data.rightInfo[key],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) => provider
                                    .updateCalPointRightInfo(index, key, v),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SignatureBox extends StatelessWidget {
  final String title;
  const SignatureBox({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 6),
        Container(
          height: 24,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 1.2)),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Name  :'),
        const SizedBox(height: 6),
        Container(
          height: 24,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 1.2)),
          ),
        ),
      ],
    );
  }
}

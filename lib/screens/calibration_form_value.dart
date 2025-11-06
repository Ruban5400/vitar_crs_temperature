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

              ElevatedButton(
                onPressed: () async {
                  final calProv = Provider.of<CalibrationProvider>(context, listen: false);
                  final meterProv = Provider.of<MeterProvider>(context, listen: false);

                  for (var i = 0; i < calProv.calPoints.length; i++) {
                    debugPrint('--- CalPoint #${i + 1} refReadings: ${calProv.calPoints[i].refReadings}');
                    debugPrint('--- CalPoint #${i + 1} testReadings: ${calProv.calPoints[i].testReadings}');
                  }

                  final calibrationProvider = CalibrationProvider();

                  // ✅ Use the actual "setting" value stored for the cal point
                  final settingValue = calProv.calPoints[0].setting;
                  calibrationProvider.updateCalPointSetting(0, settingValue);

                  List<List<double>> table = calibrationProvider.generateTableForCalPoint(0);

                  for (var row in table) {
                    print('5400 =-=-=>> ${row.map((e) => e.toStringAsFixed(4)).join('\t')}');
                  }

                  // loader
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // 1) compute averages in rightInfo['Meter Corr.']
                    calProv.computeAndStoreMeterCorrections();

                    // 2) ensure meter table is loaded (from Supabase or sample)
                    final rows = await meterProv.fetchAll();

                    // 3) compute interpolated meter corrections and write into meterCorrPerRow
                    calProv.calculateMeterCorrections(rows);

                    Navigator.of(context).pop(); // remove loader

                    // 4) navigate to report
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailedReportPage(meterEntries: rows),
                      ),
                    );
                  } catch (e, st) {
                    Navigator.of(context).pop();
                    debugPrint('Error preparing calculations: $e\n$st');
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Failed to prepare calculations: $e')));
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Text('Continue to Calculation'),
                ),
              )

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

  // Defaults based on your attached image (approx. values copied from the screenshot)
  static const List<String> _defaultSettings = [
    '-25', // 1
    '0',   // 2
    '50',  // 3
    '100', // 4
    '150', // 5
    '200', // 6
    '250', // 7
    '300', // 8
  ];

  static const List<List<String>> _defaultRef = [
    ['90.192', '90.193', '90.194', '90.192', '90.193', '90.192'], // 1
    ['100.003', '100.002', '100.001', '100.002', '100.004', '100.002'], // 2
    ['119.399', '119.397', '119.398', '119.397', '119.398', '119.397'], // 3
    ['138.505', '138.506', '138.508', '138.506', '138.507', '138.506'], // 4
    ['157.326', '157.325', '157.328', '157.324', '157.325', '157.325'], // 5
    ['175.856', '175.857', '175.859', '175.856', '175.858', '175.856'], // 6
    ['194.095', '194.098', '194.097', '194.098', '194.096', '194.098'], // 7
    ['212.052', '212.051', '212.054', '212.052', '212.054', '212.052'], // 8
  ];

  static const List<List<String>> _defaultTest = [
    ['-25.1', '-25.2', '-25.2', '-25.1', '-25.2', '-25.1'], // 1
    ['0.1', '0.2', '0.1', '0.2', '0.1', '0.1'], // 2
    ['50.2', '50.1', '50.2', '50.1', '50.2', '50.1'], // 3
    ['100.3', '100.4', '100.3', '100.3', '100.4', '100.4'], // 4
    ['150.3', '150.4', '150.4', '150.3', '150.3', '150.3'], // 5 (approx)
    ['200.5', '200.4', '200.4', '200.5', '200.4', '200.5'], // 6
    ['250.2', '250.2', '250.2', '250.3', '250.2', '250.3'], // 7 (approx)
    ['300.3', '300.4', '300.0', '300.3', '300.3', '300.4'], // 8 (approx)
  ];

  static final List<Map<String, String>> _defaultRightInfo = [
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB9',
      'Immer.': ' : 140 mm',
    }, // 1
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB9',
      'Immer.': ' : 140 mm',
    }, // 2
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB9',
      'Immer.': ' : 140 mm',
    }, // 3
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB9',
      'Immer.': ' : 140 mm',
    }, // 4
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB1',
      'Immer.': ' : 140 mm',
    }, // 5
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB1',
      'Immer.': ' : 140 mm',
    }, // 6
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB1',
      'Immer.': ' : 140 mm',
    }, // 7
    {
      'Ref. Ther.': 'ST-S6',
      'Ref. Ind.': 'ST-MC6-1',
      'Ref. Wire': '-',
      'Bath': 'ST-DB1',
      'Immer.': ' : 140 mm',
    }, // 8
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context);
    final data = provider.calPoints[index];

    // populate defaults only once (if provider fields are empty)
    // Setting is placed if empty
    if ((data.setting == null || data.setting.trim().isEmpty) && _defaultSettings.length > index) {
      provider.updateCalPointSetting(index, _defaultSettings[index]);
    }

    // If refReadings empty, populate defaults
    bool needRefPopulate = true;
    for (var v in data.refReadings) {
      if (v.trim().isNotEmpty) {
        needRefPopulate = false;
        break;
      }
    }
    if (needRefPopulate && _defaultRef.length > index) {
      for (int r = 0; r < 6; r++) {
        provider.updateRefReading(index, r, _defaultRef[index][r]);
      }
    }

    // If testReadings empty, populate defaults
    bool needTestPopulate = true;
    for (var v in data.testReadings) {
      if (v.trim().isNotEmpty) {
        needTestPopulate = false;
        break;
      }
    }
    if (needTestPopulate && _defaultTest.length > index) {
      for (int r = 0; r < 6; r++) {
        provider.updateTestReading(index, r, _defaultTest[index][r]);
      }
    }

    // Populate rightInfo keys if empty
    final defaults = _defaultRightInfo[index];
    for (final key in defaults.keys) {
      final current = data.rightInfo[key] ?? '';
      if (current.trim().isEmpty) {
        provider.updateCalPointRightInfo(index, key, defaults[key]!);
      }
    }

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
                width: 75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Setting',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white70,
                      ),
                      child: TextFormField(
                        initialValue: data.setting,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => provider.updateCalPointSetting(index, v),
                      ),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white70,
                                  ),
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
                                    onChanged: (v) => provider.updateRefReading(index, r, v),
                                  ),
                                ),
                              ),
                              // test
                              SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white70,
                                  ),
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
                                    onChanged: (v) => provider.updateTestReading(index, r, v),
                                  ),
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white70,
                                ),
                                child: TextFormField(
                                  initialValue: data.rightInfo[key],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) => provider.updateCalPointRightInfo(index, key, v),
                                ),
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

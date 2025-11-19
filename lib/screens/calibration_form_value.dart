import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';
import '../providers/meter_provider.dart';
import '../widgets/cal_point_card.dart';
import 'calculated_screen.dart';

class CalibrationFormPage extends StatelessWidget {
  const CalibrationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calibration Form (Cal Points)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 1000,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                      // button to continue
                      ElevatedButton(
                        onPressed: () async {
                          final calProv = Provider.of<CalibrationProvider>(
                            context,
                            listen: false,
                          );
                          final meterProv = Provider.of<MeterProvider>(
                            context,
                            listen: false,
                          );

                          for (var i = 0; i < calProv.calPoints.length; i++) {
                            debugPrint(
                              '--- CalPoint #${i + 1} refReadings: ${calProv.calPoints[i].refReadings}',
                            );
                            debugPrint(
                              '--- CalPoint #${i + 1} testReadings: ${calProv.calPoints[i].testReadings}',
                            );
                          }

                          final calibrationProvider = CalibrationProvider();

                          // ✅ Use the actual "setting" value stored for the cal point
                          final settingValue = calProv.calPoints[0].setting;
                          calibrationProvider.updateCalPointSetting(0, settingValue);

                          List<List<double>> table = calibrationProvider
                              .generateTableForCalPoint(0);

                          for (var row in table) {
                            print(
                              '5400 =-=-=>> ${row.map((e) => e.toStringAsFixed(4)).join('\t')}',
                            );
                          }

                          // loader
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                const Center(child: CircularProgressIndicator()),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to prepare calculations: $e'),
                              ),
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Text('Continue to Calculation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

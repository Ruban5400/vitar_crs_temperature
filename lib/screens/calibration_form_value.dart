// filename: lib/screens/calibration_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitar_crs_temperature/providers/calibration_provider.dart';
import 'package:vitar_crs_temperature/providers/meter_provider.dart';
import 'package:vitar_crs_temperature/widgets/cal_point_card.dart';
import '../models/permission_names.dart';
import 'calculated_screen.dart';

class CalibrationFormPage extends StatelessWidget {
  const CalibrationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    // listen: false because we use Consumers/Providers inside where needed
    final provider = Provider.of<CalibrationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calibration Form (Cal Points)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
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
                              border: Border.all(
                                color: Colors.black,
                                width: 1.2,
                              ),
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
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
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
                      // Add these before the ElevatedButton
                      Consumer<CalibrationProvider>(
                        builder: (context, prov, _) {
                          // get options safely
                          final calibratedByOptions = prov.namesOptions['calibrated_by'] ?? [];
                          final approvedByOptions = prov.namesOptions['approved_signatory'] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // Calibrated By
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 1.2),
                                ),
                                child: DropdownButtonFormField<PermissionName>(
                                  value: prov.data.calibratedBy,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  hint: const Text('Select Calibrated By'),
                                  items: calibratedByOptions.map((name) {
                                    return DropdownMenuItem(
                                      value: name,
                                      child: Text(name.name), // adjust property if needed
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    prov.updateField('CalibratedBy', value as String);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Approved By
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 1.2),
                                ),
                                child: DropdownButtonFormField<PermissionName>(
                                  value: prov.data.approvedBy,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  hint: const Text('Select Approved By'),
                                  items: approvedByOptions.map((name) {
                                    return DropdownMenuItem(
                                      value: name,
                                      child: Text(name.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    prov.updateField('ApprovedBy', value as String);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
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

                          // compute master-based Actual Ref for each cal-point (initial)
                          for (int i = 0; i < calProv.calPoints.length; i++) {
                            calProv.computeActualRefsForCalPoint(i);
                          }

                          // Example of generating a table — use existing calProv, not a new provider.
                          // final settingValue = calProv.calPoints[0].setting;
                          // final table = calProv.generateTableForCalPoint(0);

                          // show loader
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            // 1) compute averages (populates nothing in provider except returns values)
                            calProv.computeAndStoreMeterCorrections();
                            final selectedModel =
                            calProv.calPoints.first.rightInfo['Ref. Ind.'];
                            // 2) load meter table (rows) from MeterProvider (which uses MeterService -> Supabase)
                            final rows = await meterProv.fetchAll(selectedModel);

                            // 3) compute interpolated meter corrections into meterCorrPerRow
                            calProv.calculateMeterCorrections(rows);

                            // 4) compute actual refs now that meterCorrPerRow is updated
                            for (int i = 0; i < calProv.calPoints.length; i++) {
                              calProv.computeActualRefsForCalPoint(i);
                            }
                            // close loader safely
                            if (context.mounted) Navigator.of(context).pop();
                            // navigate to report page with rows
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailedReportPage(meterEntries: rows),
                                ),
                              );
                            }
                          } catch (e, st) {
                            // ensure loader is closed even on error
                            if (context.mounted) Navigator.of(context).pop();
                            debugPrint('Error preparing calculations: $e\n$st');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to prepare calculations: $e'),
                                ),
                              );
                            }
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

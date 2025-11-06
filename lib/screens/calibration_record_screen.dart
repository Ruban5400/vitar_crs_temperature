// lib/screens/calibration_record_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';
import '../widgets/editable_data_field.dart';
import '../widgets/form_row_item.dart';
import 'calibration_form_value.dart';

class CalibrationRecordScreen extends StatelessWidget {
  const CalibrationRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration Record Sheet (Temperature 1)'),
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset Data', onPressed: provider.resetAll),
          // Consumer<CalibrationProvider>(
          //   builder: (context, prov, child) => TextButton.icon(
          //     icon: const Icon(Icons.save, color: Colors.white),
          //     label: const Text('VIEW MODEL DATA', style: TextStyle(color: Colors.white)),
          //     onPressed: () {
          //       showDialog(
          //         context: context,
          //         builder: (c) => AlertDialog(
          //           title: const Text('Current Model State'),
          //           content: SelectableText(prov.exportAll().toString()),
          //           actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))],
          //         ),
          //       );
          //     },
          //   ),
          // )
        ],
      ),
      body: Center(
        child: Container(
          width: 880,
          padding: const EdgeInsets.all(16.0),
          child: Consumer<CalibrationProvider>(builder: (context, provider, child) {
            final d = provider.data;
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text(
                      'Calibration Record Sheet (Temperature 1)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 16),

                    FormRowItem(label: 'Certificate No.', valueWidget: EditableDataField(fieldName: 'CertificateNo', defaultValue: 'STT 25 08 - 0001 -1')),
                    FormRowItem(label: 'Instrument', valueWidget: EditableDataField(fieldName: 'Instrument', defaultValue: 'Digital Thermometer c/w Type K Thermocouple')),
                    FormRowItem(label: 'Make', valueWidget: EditableDataField(fieldName: 'Make', defaultValue: 'VITAR')),
                    FormRowItem(label: 'Model', valueWidget: EditableDataField(fieldName: 'Model', defaultValue: 'ADV500')),
                    FormRowItem(label: 'Serial No.', valueWidget: EditableDataField(fieldName: 'SerialNo', defaultValue: 'T18 - 0001 -1')),
                    const Divider(height: 20, color: Colors.teal),

                    FormRowItem(label: 'Customer Name', valueWidget: EditableDataField(fieldName: 'CustomerName', defaultValue: '1 METER TEH')),
                    FormRowItem(label: 'CMR No.', valueWidget: EditableDataField(fieldName: 'CMRNo', defaultValue: '251152')),
                    FormRowItem(label: 'Date Received', valueWidget: EditableDataField(fieldName: 'DateReceived', defaultValue: '25/8/2025')),
                    FormRowItem(label: 'Date Calibrated', valueWidget: EditableDataField(fieldName: 'DateCalibrated', defaultValue: '26/8/2025')),
                    const Divider(height: 20, color: Colors.teal),

                    _buildEnvironmentRow(context),
                    _buildConditionRow(context),
                    FormRowItem(label: 'Thermohygro meter', valueWidget: EditableDataField(fieldName: 'Thermohygrometer', defaultValue: 'ST-TH17')),
                    _buildResolutionRow(context),
                    FormRowItem(label: 'Ref. Method', valueWidget: EditableDataField(fieldName: 'RefMethod', defaultValue: 'CP-E')),

                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CalibrationFormPage()));
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        label: const Text('CONTINUE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEnvironmentRow(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final data = provider.data;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey.shade300, width: 0.5)),
            child: const Text('Ambient Temp.', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: Row(children: [const Text('Max: ', style: TextStyle(fontSize: 13)), Expanded(child: EditableDataField(fieldName: 'AmbientTempMax', defaultValue: '20.5'))])),
          Expanded(flex: 1, child: Row(children: [const Text('Min: ', style: TextStyle(fontSize: 13)), Expanded(child: EditableDataField(fieldName: 'AmbientTempMin', defaultValue: '20.1'))])),
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey.shade300, width: 0.5)),
            child: const Text('Relative Humidity', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: Row(children: [const Text('Max: ', style: TextStyle(fontSize: 13)), Expanded(child: EditableDataField(fieldName: 'RHMax', defaultValue: '51'))])),
          Expanded(flex: 1, child: Row(children: [const Text('Min: ', style: TextStyle(fontSize: 13)), Expanded(child: EditableDataField(fieldName: 'RHMin', defaultValue: '50'))])),
        ]),
      ),
    );
  }

  Widget _buildConditionRow(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final data = provider.data;
    return FormRowItem(
      label: 'Calibrated at / Date/Condition',
      valueWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Calibrated at:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(children: [
                Radio<String>(value: 'Lab', groupValue: data.calibratedAt, onChanged: (v) => provider.updateField('CalibratedAt', v ?? '')),
                const Text('Lab', style: TextStyle(fontSize: 13)),
                Radio<String>(value: 'Site', groupValue: data.calibratedAt, onChanged: (v) => provider.updateField('CalibratedAt', v ?? '')),
                const Text('Site', style: TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const Text('Remark:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(child: Padding(padding: const EdgeInsets.only(left: 8.0), child: EditableDataField(fieldName: 'Remark', defaultValue: 'No remarks'))),
        ]),
        const Divider(),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Instrument Condition When Received:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RadioListTile<String>(
                title: const Text('Physically good', style: TextStyle(fontSize: 13)),
                value: 'Physically good',
                groupValue: data.instrumentConditionReceived,
                onChanged: (v) => provider.updateCondition('Received', v ?? ''),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('Needs repair', style: TextStyle(fontSize: 13)),
                value: 'Needs repair',
                groupValue: data.instrumentConditionReceived,
                onChanged: (v) => provider.updateCondition('Received', v ?? ''),
                dense: true,
              ),
            ]),
          ),
        ]),
        const Divider(),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Instrument Condition When Returned:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RadioListTile<String>(
                title: const Text('Calibrated and tested serviceable', style: TextStyle(fontSize: 13)),
                value: 'Calibrated and tested serviceable',
                groupValue: data.instrumentConditionReturned,
                onChanged: (v) => provider.updateCondition('Returned', v ?? ''),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('Not fit for calibration', style: TextStyle(fontSize: 13)),
                value: 'Not fit for calibration',
                groupValue: data.instrumentConditionReturned,
                onChanged: (v) => provider.updateCondition('Returned', v ?? ''),
                dense: true,
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildResolutionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey.shade300, width: 0.5)),
            child: const Text('Resolution', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
              child: Row(children: [const Text('Resolution: ', style: TextStyle(fontSize: 13)), Expanded(child: EditableDataField(fieldName: 'Resolution', defaultValue: '0.1'))]),
            ),
          ),
        ]),
      ),
    );
  }
}

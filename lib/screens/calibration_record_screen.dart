import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calibration_provider.dart';
import '../services/address_service.dart';
import '../widgets/editable_data_field.dart';
import '../widgets/form_row_item.dart';
import '../widgets/searchable_address_dropdown.dart';
import 'calibration_form_value.dart';

class CalibrationRecordScreen extends StatefulWidget {
  const CalibrationRecordScreen({super.key});

  @override
  State<CalibrationRecordScreen> createState() => _CalibrationRecordScreenState();
}

class _CalibrationRecordScreenState extends State<CalibrationRecordScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<CalibrationProvider>(context, listen: false);
      final addressService = AddressService();
      final list = await addressService.fetchAddressData();
      provider.setAddresses(list);

    });
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calibration Record Sheet (Temperature 1)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Data',
            onPressed: provider.resetAll, // safe: this is a callback only
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 880,
          padding: const EdgeInsets.all(16.0),
          child: Consumer<CalibrationProvider>(
            builder: (context, provider, child) {
              final d = provider.data;
              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormRowItem(
                          label: 'Certificate No.',
                          valueWidget: EditableDataField(
                            fieldName: 'CertificateNo',
                          ),
                        ),
                        FormRowItem(
                          label: 'Instrument',
                          valueWidget: EditableDataField(
                            fieldName: 'Instrument',
                          ),
                        ),
                        FormRowItem(
                          label: 'Make',
                          valueWidget: EditableDataField(fieldName: 'Make'),
                        ),
                        FormRowItem(
                          label: 'Model',
                          valueWidget: EditableDataField(fieldName: 'Model'),
                        ),
                        FormRowItem(
                          label: 'Serial No.',
                          valueWidget: EditableDataField(fieldName: 'SerialNo'),
                        ),
                        const Divider(height: 20, color: Colors.teal),

                        FormRowItem(
                          label: 'Customer Name',
                          valueWidget: Consumer<CalibrationProvider>(
                            builder: (context, provider, child) {
                              final addresses = provider.addresses;
                              final current = provider.data.customerName;
                              return SearchableAddressDropdown(
                                addresses: addresses,
                                selectedName: current,
                                onSelected: (name) {
                                  provider.updateField('CustomerName', name);
                                },
                              );
                            },
                          ),
                        ),
                        FormRowItem(
                          label: 'CMR No.',
                          valueWidget: EditableDataField(fieldName: 'CMRNo'),
                        ),
                        FormRowItem(
                          label: 'Date Received',
                          valueWidget: _buildDatePickerField(context, 'DateReceived'),
                        ),
                        FormRowItem(
                          label: 'Date Calibrated',
                          valueWidget: _buildDatePickerField(context, 'DateCalibrated'),
                        ),
                        const Divider(height: 20, color: Colors.teal),

                        _buildEnvironmentRow(context),
                        _buildConditionRow(context),
                        const Divider(height: 20, color: Colors.teal),
                        FormRowItem(
                          label: 'Remarks',
                          valueWidget: EditableDataField(fieldName: 'Remark'),
                        ),
                        FormRowItem(
                          label: 'Thermohygro meter',
                          valueWidget: EditableDataField(
                            fieldName: 'Thermohygrometer',
                          ),
                        ),
                        FormRowItem(
                          label: 'Resolution',
                          valueWidget: EditableDataField(
                            fieldName: 'Resolution',
                          ),
                        ),
                        FormRowItem(
                          label: 'Ref. Method',
                          valueWidget: EditableDataField(
                            fieldName: 'RefMethod',
                          ),
                        ),

                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CalibrationFormPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                            label: const Text('CONTINUE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentRow(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    'Ambient Temp.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      const Text('Max: ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: EditableDataField(fieldName: 'AmbientTempMax'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      const Text('Min: ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: EditableDataField(fieldName: 'AmbientTempMin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    'Relative Humidity',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      const Text('Max: ', style: TextStyle(fontSize: 13)),
                      Expanded(child: EditableDataField(fieldName: 'RHMax')),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      const Text('Min: ', style: TextStyle(fontSize: 13)),
                      Expanded(child: EditableDataField(fieldName: 'RHMin')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionRow(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final data = provider.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 170,
              child: Text(
                'Calibrated at:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 5),
            Row(
              children: [
                Radio<String>(
                  value: 'Lab',
                  groupValue: data.calibratedAt,
                  onChanged: (v) =>
                      provider.updateField('CalibratedAt', v ?? ''),
                ),
                const Text('Lab', style: TextStyle(fontSize: 13)),
                SizedBox(width: 5),
                Radio<String>(
                  value: 'Site',
                  groupValue: data.calibratedAt,
                  onChanged: (v) =>
                      provider.updateField('CalibratedAt', v ?? ''),
                ),
                const Text('Site', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instrument Condition When Received:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Physically good',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: 'Physically good',
                    groupValue: data.instrumentConditionReceived,
                    onChanged: (v) =>
                        provider.updateCondition('Received', v ?? ''),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Needs repair',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: 'Needs repair',
                    groupValue: data.instrumentConditionReceived,
                    onChanged: (v) =>
                        provider.updateCondition('Received', v ?? ''),
                    dense: true,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instrument Condition When Returned:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Calibrated and tested serviceable',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: 'Calibrated and tested serviceable',
                    groupValue: data.instrumentConditionReturned,
                    onChanged: (v) =>
                        provider.updateCondition('Returned', v ?? ''),
                    dense: true,
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Not fit for calibration',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: 'Not fit for calibration',
                    groupValue: data.instrumentConditionReturned,
                    onChanged: (v) =>
                        provider.updateCondition('Returned', v ?? ''),
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerField(BuildContext context, String fieldName) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final currentValue = provider.getFieldValue(fieldName);

    return InkWell(
      onTap: () async {
        final initialDate = DateTime.tryParse(currentValue ?? '') ?? DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.teal, // header color
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
          provider.updateField(fieldName, formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentValue?.isNotEmpty == true ? currentValue! : 'Select Date',
              style: TextStyle(
                fontSize: 14,
                color: currentValue?.isNotEmpty == true
                    ? Colors.black
                    : Colors.grey.shade600,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
          ],
        ),
      ),
    );
  }

}

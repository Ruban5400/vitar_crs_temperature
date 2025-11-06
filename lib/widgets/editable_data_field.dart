import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calibration_provider.dart';

class EditableDataField extends StatefulWidget {
  final String fieldName;
  final String? defaultValue; // new optional default

  const EditableDataField({
    Key? key,
    required this.fieldName,
    this.defaultValue,
  }) : super(key: key);

  @override
  _EditableDataFieldState createState() => _EditableDataFieldState();
}

class _EditableDataFieldState extends State<EditableDataField> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // We'll initialize controller in didChangeDependencies so provider is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final prov = Provider.of<CalibrationProvider>(context, listen: false);

    // get current value from provider for this field (if any)
    String current = _readProviderValue(prov, widget.fieldName) ?? '';

    if (current.isEmpty && (widget.defaultValue != null && widget.defaultValue!.isNotEmpty)) {
      // if provider empty, set provider to defaultValue so it persists as fixed value
      prov.updateField(widget.fieldName, widget.defaultValue!);
      current = widget.defaultValue!;
    }

    _controller.text = current;
    _initialized = true;
  }

  String? _readProviderValue(CalibrationProvider prov, String fieldName) {
    final d = prov.data;
    switch (fieldName) {
      case 'CertificateNo':
        return d.certificateNo;
      case 'Instrument':
        return d.instrument;
      case 'Make':
        return d.make;
      case 'Model':
        return d.model;
      case 'SerialNo':
        return d.serialNo;
      case 'CustomerName':
        return d.customerName;
      case 'CMRNo':
        return d.cmrNo;
      case 'DateReceived':
        return d.dateReceived;
      case 'DateCalibrated':
        return d.dateCalibrated;
      case 'AmbientTempMax':
        return d.ambientTempMax;
      case 'AmbientTempMin':
        return d.ambientTempMin;
      case 'RHMax':
        return d.relativeHumidityMax;
      case 'RHMin':
        return d.relativeHumidityMin;
      case 'Thermohygrometer':
        return d.thermohygrometer;
      case 'RefMethod':
        return d.refMethod;
      case 'CalibratedAt':
        return d.calibratedAt;
      case 'Remark':
        return d.remark;
      case 'Resolution':
        return d.resolution;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final prov = Provider.of<CalibrationProvider>(context, listen: false);
    prov.updateField(widget.fieldName, val);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        // show the defaultValue as a hint only when controller is empty:
        hintText: _controller.text.isEmpty ? widget.defaultValue : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calibration_provider.dart';

class EditableDataField extends StatefulWidget {
  final String fieldName;
  final String initialValue;
  final bool readOnly;
  const EditableDataField({super.key, required this.fieldName, this.initialValue = '', this.readOnly = false});

  @override
  State<EditableDataField> createState() => _EditableDataFieldState();
}

class _EditableDataFieldState extends State<EditableDataField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // keep in sync with provider value
    final provider = Provider.of<CalibrationProvider>(context, listen: false);
    final current = _readValue(provider);
    if (current != _controller.text) _controller.text = current;
  }

  String _readValue(CalibrationProvider provider) {
    final d = provider.data;
    switch (widget.fieldName) {
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
        return '';
    }
  }

  void _onChanged(String v) {
    if (!widget.readOnly) Provider.of<CalibrationProvider>(context, listen: false).updateField(widget.fieldName, v);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalibrationProvider>(builder: (context, provider, _) {
      final providerVal = _readValue(provider);
      if (_controller.text != providerVal) _controller.text = providerVal;
      return TextFormField(
        controller: _controller,
        readOnly: widget.readOnly,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.8)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal, width: 1.6)),
        ),
        onChanged: _onChanged,
      );
    });
  }
}

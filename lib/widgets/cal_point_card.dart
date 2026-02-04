// lib/widgets/cal_point_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitar_crs_temperature/providers/calibration_provider.dart';

class CalPointCard extends StatefulWidget {
  final int index;
  const CalPointCard({super.key, required this.index});

  @override
  State<CalPointCard> createState() => _CalPointCardState();
}

class _CalPointCardState extends State<CalPointCard> {
  late CalibrationProvider _provider;

  // Controllers for top-level "setting" and 6 ref/test rows
  late final TextEditingController _settingController;
  late final List<TextEditingController> _refControllers;
  late final List<TextEditingController> _testControllers;

  // Keep a flag to know if we already subscribed to provider
  bool _subscribedToProvider = false;

  @override
  void initState() {
    super.initState();
    _settingController = TextEditingController();
    _refControllers = List.generate(6, (_) => TextEditingController());
    _testControllers = List.generate(6, (_) => TextEditingController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<CalibrationProvider>(context, listen: false);
    // Initialize controller content from provider values (cheap, no writes)
    _syncControllersFromProvider();

    // Add provider listener to keep controllers in sync when provider changes elsewhere
    if (!_subscribedToProvider) {
      _provider.addListener(_syncControllersFromProvider);
      _subscribedToProvider = true;
    }
  }

  void _syncControllersFromProvider() {
    if (!mounted) return;
    final data = _provider.calPoints[widget.index];

    final setting = data.setting;
    if (_settingController.text != setting) _settingController.text = setting;

    for (int i = 0; i < 6; i++) {
      final v = (i < data.refReadings.length) ? data.refReadings[i] : '';
      if (_refControllers[i].text != v) _refControllers[i].text = v;
    }
    for (int i = 0; i < 6; i++) {
      final v = (i < data.testReadings.length) ? data.testReadings[i] : '';
      if (_testControllers[i].text != v) _testControllers[i].text = v;
    }
  }

  @override
  void dispose() {
    if (_subscribedToProvider) {
      try {
        _provider.removeListener(_syncControllersFromProvider);
      } catch (_) {}
      _subscribedToProvider = false;
    }

    _settingController.dispose();
    for (final c in _refControllers) c.dispose();
    for (final c in _testControllers) c.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using Provider.of with listen:true so structural changes in provider rebuild UI
    final provider = Provider.of<CalibrationProvider>(context);
    final data = provider.calPoints[widget.index];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header row + setting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cal. Point : ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Setting', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white70,
                      ),
                      child: TextFormField(
                        controller: _settingController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6), border: InputBorder.none),
                        onChanged: (v) {
                          provider.updateCalPointSetting(widget.index, v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // main body: left (ref/test) and right (rightInfo dropdowns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left: ref/test columns (text input controllers)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Expanded(child: Center(child: Text('Ref.\nReading', textAlign: TextAlign.center))),
                          Expanded(child: Center(child: Text('Test\nReading', textAlign: TextAlign.center))),
                        ],
                      ),
                      const Divider(height: 8, thickness: 1),
                      ...List.generate(6, (r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              // Ref
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4), color: Colors.white70),
                                  child: TextFormField(
                                    controller: _refControllers[r],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6), border: InputBorder.none),
                                    onChanged: (v) => provider.updateRefReading(widget.index, r, v),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Test
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4), color: Colors.white70),
                                  child: TextFormField(
                                    controller: _testControllers[r],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6), border: InputBorder.none),
                                    onChanged: (v) => provider.updateTestReading(widget.index, r, v),
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

              // right: reference info column (dynamic keys from provider) rendered as dropdowns
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in data.rightInfo.keys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: Text(key)),
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4), color: Colors.white70),
                                child: _RightInfoDropdown(
                                  index: widget.index,
                                  keyName: key,
                                  currentValue: data.rightInfo[key] ?? '',
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

/// Small widget to render a dropdown for a single right-info key.
/// If user selects "Other...", it opens a dialog to input a custom value.
class _RightInfoDropdown extends StatelessWidget {
  final int index;
  final String keyName;
  final String currentValue;

  const _RightInfoDropdown({
    required this.index,
    required this.keyName,
    required this.currentValue,
  });

  // fallback options (kept for safety)
  List<String> _fallbackOptionsForKey(String key) {
    switch (key) {
      case 'Ref. Ther.':
        return ['ST-S1', 'ST-S2', 'ST-S3', 'ST-S4', 'ST-S5', 'ST-S6', 'Other...'];
      case 'Ref. Ind.':
      case 'Test Ind.':
        return ['-', 'ST-MC-1', 'ST-MC-2', 'ST-MC-3', 'ST-MC-4', 'ST-MC-5', 'ST-MC-7', 'ST-MC-8', 'ST-MC-9', 'ST-MC-10', 'ST-MC-14', 'ST-MC-16', 'ST-MC6-1', 'ST-MC6-2', 'Other...'];
      case 'Ref. Wire':
      case 'Test Wire':
        return ['-', 'Wire A', 'Wire B', 'Other...'];
      case 'Bath':
        return ['ST-DB9', 'ST-DB1', 'Other...'];
      case 'Immer.':
        return ['140 mm', 'Other...'];
      default:
        return ['', 'Other...'];
    }
  }

  /// Get options: prefer provider.masterOptions[keyName], otherwise fallback.
  List<String> _optionsForKey(BuildContext context, String key) {
    try {
      final prov = Provider.of<CalibrationProvider>(context, listen: false);
      final fromMaster = prov.masterOptions[key];
      if (fromMaster != null && fromMaster.isNotEmpty) {
        // Ensure we return a fresh list copy
        return List<String>.from(fromMaster);
      }
    } catch (_) {
      // ignore - will use fallback
    }
    return _fallbackOptionsForKey(key);
  }

  Future<void> _askCustomValue(BuildContext context, String initial, Function(String) onSave) async {
    final ctrl = TextEditingController(text: initial);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter custom value'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Custom value'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );

    if (res != null && res.trim().isNotEmpty) {
      onSave(res.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalibrationProvider>(context, listen: false);

    // 1) Prefer DB-driven list using the visible UI key (your masterOptions keys already use these labels)
    final List<String> items = _optionsForKey(context, keyName);

    // 2) Ensure 'Other...' present (some DB sets already include it)
    if (!items.contains('Other...')) items.add('Other...');

    // 3) If currentValue is custom and not present in items, insert it at the top so dropdown can show it.
    if (currentValue.isNotEmpty && !items.contains(currentValue)) {
      items.insert(0, currentValue);
    }

    // 4) Prepare display labels (show '(empty)' for empty string entry)
    final displayList = items.map((it) => it.isEmpty ? '(empty)' : it).toList();

    // 5) Value selection: when currentValue is empty string, set value to '' if available, else null
    final String? valueForDropdown = currentValue.isNotEmpty ? currentValue : (items.contains('') ? '' : null);

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: valueForDropdown,
      isDense: true,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8)),
      items: List.generate(items.length, (i) {
        final opt = items[i];
        final label = displayList[i];
        return DropdownMenuItem<String>(
          value: opt,
          child: Text(label),
        );
      }),
      onChanged: (selected) async {
        if (selected == null) return;
        if (selected == 'Other...') {
          await _askCustomValue(context, currentValue, (custom) async {
            provider.updateCalPointRightInfo(index, keyName, custom);

            // recompute dependent values
            provider.calculateMeterCorrections();
            provider.computeActualRefsForCalPoint(index);
          });
        } else {
          provider.updateCalPointRightInfo(index, keyName, selected);

          // recompute dependent values
          provider.calculateMeterCorrections();
          provider.computeActualRefsForCalPoint(index);
        }
      },
    );
  }
}



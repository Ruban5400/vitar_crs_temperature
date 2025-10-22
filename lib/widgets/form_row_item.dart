import 'package:flutter/material.dart';

class FormRowItem extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  const FormRowItem({super.key, required this.label, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}
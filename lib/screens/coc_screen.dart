import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/cal_provider.dart';

class CocScreen extends StatelessWidget {
  const CocScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<CalProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate of Calibration'), actions: [
        IconButton(icon: const Icon(Icons.share), onPressed: () async {
          final bytes = await prov.generatePdf();
          await Printing.sharePdf(bytes: bytes, filename: '${prov.certNo}.pdf');
        }),
      ]),
      body: PdfPreview(build: (format) => prov.generatePdf()),
    );
  }
}
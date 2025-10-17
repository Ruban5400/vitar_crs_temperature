import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/calibration.dart';

abstract class PdfGenerator {
  static Future<Uint8List> build(Calibration cal) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    );

    pdf.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      build: (ctx) => [
        _header(cal, font, bold),
        _table(cal, font, bold),
        _uncertainty(cal, font),
        _sign(font),
      ],
    ));

    pdf.addPage(pw.Page(
      pageTheme: pageTheme,
      build: (ctx) => _rawPage(cal, font, bold),
    ));

    return pdf.save();
  }

  static pw.Widget _header(Calibration cal, pw.Font f, pw.Font b) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('CERTIFICATE OF CALIBRATION',
            style: pw.TextStyle(font: b, fontSize: 18)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: null,
          cellStyle: pw.TextStyle(font: f, fontSize: 10),
          data: [
            ['Certificate No.', cal.certNo],
            ['Serial No.', cal.serialNo],
            ['Description', 'Digital Thermometer c/w Type K Thermocouple'],
            ['Make', cal.make],
            ['Model', cal.model],
            ['Date Calibrated', DateFormat('dd MMMM yyyy').format(cal.calDate)],
            ['Due Date', DateFormat('dd MMMM yyyy').format(cal.dueDate)],
          ],
        ),
        pw.SizedBox(height: 10),
      ]);

  static pw.Widget _table(Calibration cal, pw.Font f, pw.Font b) {
    // final headers = ['Test Point (°C)', 'Standard Value (°C)', 'DUT Readout (°C)', 'Correction (°C)'];
    // final data = cal.results.map((r) => [
    //   r.point.setPoint.toStringAsFixed(0),
    //   r.trueTemp.toStringAsFixed(1),
    //   r.point.meanTest.toStringAsFixed(1),
    //   r.correction.toStringAsFixed(1),
    // ]).toList();

    final headers = [
      'Test Point (°C)',
      'Standard Value (°C)',
      'DUT Readout (°C)',
      'Correction (°C)',
      'Uncertainty (°C)',
      'Est. (°C)',
    ];
    final data = cal.results.map((r) => [
      r.point.setPoint.toStringAsFixed(0),
      r.trueTemp.toStringAsFixed(1),
      r.point.meanTest.toStringAsFixed(1),
      r.correction.toStringAsFixed(2),
      r.expandedU.toStringAsFixed(3),
      r.estU.toStringAsFixed(1),
    ]).toList();
    return pw.Table.fromTextArray(
        headers: headers, data: data, cellStyle: pw.TextStyle(font: f, fontSize: 10));
  }

  static pw.Widget _uncertainty(Calibration cal, pw.Font f) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 10),
    child: pw.Text(
      'The expanded uncertainty is ± ${cal.maxExpandedU.toStringAsFixed(1)} °C (k = 2, ≈ 95 %).',
      style: pw.TextStyle(font: f, fontSize: 10),
    ),
  );

  static pw.Widget _sign(pw.Font f) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 40),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(children: [
          pw.Text('Calibrated by', style: pw.TextStyle(font: f, fontSize: 10)),
          pw.SizedBox(height: 40),
          pw.Text('Sharveen A/L Palachantar', style: pw.TextStyle(font: f, fontSize: 10)),
        ]),
        pw.Column(children: [
          pw.Text('Approved Signatory', style: pw.TextStyle(font: f, fontSize: 10)),
          pw.SizedBox(height: 40),
          pw.Text('Wan Muhamad Zulhanafiah Bin Wan Yusof', style: pw.TextStyle(font: f, fontSize: 10)),
        ]),
      ],
    ),
  );

  static pw.Widget _rawPage(Calibration cal, pw.Font f, pw.Font b) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Raw Data', style: pw.TextStyle(font: b, fontSize: 14)),
        pw.SizedBox(height: 10),
        ...cal.results.expand((r) => [
          pw.Text('Set Point ${r.point.setPoint} °C', style: pw.TextStyle(font: b, fontSize: 11)),
          pw.Table.fromTextArray(
            context: null,
            cellStyle: pw.TextStyle(font: f, fontSize: 9),
            data: [
              for (int i = 0; i < 6; i++)
                ['Reading ${i + 1}', '${r.point.refOhms[i].toStringAsFixed(3)} Ω', '${r.point.testTemps[i].toStringAsFixed(1)} °C']
            ],
          ),
          pw.SizedBox(height: 10),
        ])
      ]);
}
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/test_point.dart';
import '../models/cal_result.dart';
import '../models/calibration.dart';
import '../services/its90.dart';
import '../services/uncertainty.dart';
import '../services/pdf_generator.dart';

class CalProvider with ChangeNotifier {
  String certNo = 'STT 25 08 - 0001 - 1';
  String serialNo = 'T18 - 0001 - 1';
  String make = 'VITAR';
  String model = 'ADV500';
  DateTime calDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 365));

  List<TestPoint> points = [
    TestPoint(index: 1, setPoint: -25),
    TestPoint(index: 2, setPoint: 0),
    TestPoint(index: 3, setPoint: 50),
    TestPoint(index: 4, setPoint: 100),
    TestPoint(index: 5, setPoint: 150),
    TestPoint(index: 6, setPoint: 200),
    TestPoint(index: 7, setPoint: 250),
    TestPoint(index: 8, setPoint: 300),
  ];

  List<CalResult>? _results;
  List<CalResult>? get results => _results;
  double get maxU => _results?.map((e) => e.expandedU).reduce(math.max) ?? 0.0;

  void calculate() {
    _results = points.map((p) {
      final trueT = ITS90.temp(p.meanRef);
      final corr = trueT - p.meanTest;
      final u = Uncertainty.uStd(p, trueT);
      return CalResult(
        point: p,
        trueTemp: trueT,
        correction: corr,
        expandedU: u * 2,
      );
    }).toList();
    notifyListeners();
  }

  Future<Uint8List> generatePdf() async =>
      PdfGenerator.build(Calibration(
        certNo: certNo,
        serialNo: serialNo,
        make: make,
        model: model,
        calDate: calDate,
        dueDate: dueDate,
        results: _results!,
        maxExpandedU: maxU,
      ));
}
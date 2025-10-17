import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cal_provider.dart';
import 'screens/entry_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => CalProvider(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VITAR Calibration',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const EntryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
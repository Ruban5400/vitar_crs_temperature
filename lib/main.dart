import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitar_crs_temperature/providers/calibration_provider.dart';
import 'package:vitar_crs_temperature/providers/meter_provider.dart';
import 'package:vitar_crs_temperature/screens/calibration_record_screen.dart';
import 'package:vitar_crs_temperature/services/meter_service.dart';

import 'models/meter_entry.dart';

void main() async {
  const supabaseUrl =
      'http://supabasekong-uggsw0oswso0o4w4wkogos0g.72.60.206.230.sslip.io';
  const supabaseAnonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc2MDUwODQ4MCwiZXhwIjo0OTE2MTgyMDgwLCJyb2xlIjoiYW5vbiJ9.wrF1MVhHEBLuU_7UYG1E3eYQtGGqKV6I4XIOFQUWViw';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalibrationProvider()),
        ChangeNotifierProvider(create: (_) => MeterProvider()),
        // add other providers here
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Calibration Flow',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const CalibrationRecordScreen(),
        // home: const MeterDataPage(),
      ),
    );
  }
}

class MeterDataPage extends StatelessWidget {
  const MeterDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meter Calibration Data')),
      body: FutureBuilder<List<MeterEntry>>(
        future: MeterService().fetchMeterData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('No meter data found.'));
          }

          // Display the data in a ListView or DataTable
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final entry = data[index];
              return ListTile(
                title: Text(
                  'Range: ${entry.lowerValue} to ${entry.upperValue}',
                ),
                subtitle: Text('Correction: ${entry.upperCorrection}'),
                trailing: Text('Uncertainty: ±${entry.upperUncertainty}'),
              );
            },
          );
        },
      ),
    );
  }
}

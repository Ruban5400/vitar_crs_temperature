// filename: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitar_crs_temperature/providers/calibration_provider.dart';
import 'package:vitar_crs_temperature/providers/meter_provider.dart';
import 'package:vitar_crs_temperature/screens/calibration_record_screen.dart';
import 'package:vitar_crs_temperature/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // keep your keys here or move to a secure env file
  const supabaseUrl = 'https://supabase.ezeal.in/';
  const supabaseAnonKey = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc2MDUwODQ4MCwiZXhwIjo0OTE2MTgyMDgwLCJyb2xlIjoiYW5vbiJ9.wrF1MVhHEBLuU_7UYG1E3eYQtGGqKV6I4XIOFQUWViw';

  // initialize Supabase and make the client available through SupabaseService
  await SupabaseService.init(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // business-logic providers
        ChangeNotifierProvider(create: (_) => CalibrationProvider()),
        ChangeNotifierProvider(create: (_) => MeterProvider()),

        // expose the SupabaseService if any provider/widgets need direct access
        Provider.value(value: SupabaseService.instance),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Calibration Flow',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const CalibrationRecordScreen(),
        // You can add named routes here as your app grows
        // routes: {
        //   '/calibration': (_) => const CalibrationRecordScreen(),
        // },
      ),
    );
  }
}

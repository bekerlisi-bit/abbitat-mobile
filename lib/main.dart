import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://rersthzeihnxyyjaueda.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlcnN0aHplaWhueHl5amF1ZWRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTI5NTQsImV4cCI6MjA4NTY4ODk1NH0.IBnOOPQx80ZKHSz3j85ZRjzc4ySQHh5o2pepy_KQzL0',
    ),
  );

  runApp(const AbbitatApp());
}

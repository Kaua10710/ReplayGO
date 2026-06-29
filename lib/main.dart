import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

// Credenciais externalizáveis via --dart-define
// (ex.: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...).
// O defaultValue mantém o app rodando sem configuração extra no MVP.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ctuyyvadrecjzdglrfdt.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0dXl5dmFkcmVjanpkZ2xyZmR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDEzNzMsImV4cCI6MjA5ODExNzM3M30.fshxrx5mq19XaeFbEZfWorD9QdMUbswNzOBVvSlI-C0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
  runApp(const ReplayGoApp());
}

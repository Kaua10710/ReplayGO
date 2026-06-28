import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

const _supabaseUrl = 'https://ctuyyvadrecjzdglrfdt.supabase.co';
const _supabasePublishableKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0dXl5dmFkcmVjanpkZ2xyZmR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDEzNzMsImV4cCI6MjA5ODExNzM3M30.fshxrx5mq19XaeFbEZfWorD9QdMUbswNzOBVvSlI-C0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
  runApp(const ReplayGoApp());
}

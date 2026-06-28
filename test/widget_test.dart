// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:replaygo/app.dart';

const _supabaseUrl = 'https://ctuyyvadrecjzdglrfdt.supabase.co';
const _supabasePublishableKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0dXl5dmFkcmVjanpkZ2xyZmR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDEzNzMsImV4cCI6MjA5ODExNzM3M30.fshxrx5mq19XaeFbEZfWorD9QdMUbswNzOBVvSlI-C0';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  });

  testWidgets('App renders root widget', (tester) async {
    await tester.pumpWidget(const ReplayGoApp());
    await tester.pumpAndSettle();

    expect(find.byType(ReplayGoApp), findsOneWidget);
  });
}

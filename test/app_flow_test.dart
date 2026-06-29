import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:replaygo/app.dart';

// Teste de fluxo (widget-level) executável no CI sem device/Supabase de teste:
// valida o boot do app e a navegação automática Splash -> Login.
// O E2E autenticado (login -> admin/CRUD -> home) fica em integration_test/.

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

  testWidgets('boot exibe a Splash', (tester) async {
    await tester.pumpWidget(const ReplayGoApp());
    await tester.pump();
    // CTA da splash (antes do timer de navegação).
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Splash navega automaticamente para o Login', (tester) async {
    await tester.pumpWidget(const ReplayGoApp());
    await tester.pump();
    // Dispara o Timer de 3s da splash.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    // Elemento exclusivo da tela de login.
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });
}

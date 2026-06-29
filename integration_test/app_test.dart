import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:replaygo/app.dart';

// Testes de integração end-to-end.
//
// Como rodar (precisa de um device/emulador ou Chrome):
//   flutter test integration_test/app_test.dart -d chrome
//
// O fluxo autenticado (login -> painel admin -> CRUD -> home) exige um projeto
// Supabase de teste com o schema aplicado (supabase/schema.sql) e os usuários
// de teste (admin@replaygo.com etc.). Esses casos ficam marcados com `skip`
// até que as credenciais de teste sejam configuradas via --dart-define.

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ctuyyvadrecjzdglrfdt.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0dXl5dmFkcmVjanpkZ2xyZmR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDEzNzMsImV4cCI6MjA5ODExNzM3M30.fshxrx5mq19XaeFbEZfWorD9QdMUbswNzOBVvSlI-C0',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  });

  testWidgets('boot -> splash -> login', (tester) async {
    await tester.pumpWidget(const ReplayGoApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets(
    'login admin -> Admin Panel -> cadastra cidade -> aparece na home',
    (tester) async {
      // E2E completo. Requer Supabase de teste com schema + usuário admin.
      // 1. Navegar até o login, preencher admin@replaygo.com / senha de teste.
      // 2. Submeter e validar o redirecionamento para o Admin Panel.
      // 3. Abrir "Cadastrar Cidades", criar uma cidade e validar o snackbar.
      // 4. Logar como usuário e validar a nova seção na home.
    },
    skip: true,
  );
}

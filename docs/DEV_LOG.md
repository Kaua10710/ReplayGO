# ReplayGO — Dev Log

Registro cronológico das principais iterações de desenvolvimento. Mais recente no topo.

---

## Iteração — Ações reais nas telas + testes (#3, #4, #5, #6)

**Objetivo:** eliminar botões sem ação (`onPressed: () {}`) ligando-os ao backend, confirmar o Owner Dashboard e ampliar os testes. (Itens #1 deploy do schema e #2 player de vídeo ficaram fora desta rodada.)

### #3 — Painel admin (Painel Geral › bottom sheet)
- `lib/screens/admin/admin_panel_screen.dart`
- **Suspender/Reativar:** alterna `ArenaStatus` via `AdminController.updateArena(status:)` (auto-refresh + snackbar). Rótulo/ícone/cor mudam conforme o status atual.
- **Ver replays:** `context.push` para `ArenaPublicScreen` da arena.
- **Detalhes:** `AlertDialog` com cidade/UF, status, ao vivo, nº de replays e quadras.

### #4 — Botões placeholder
- **Replay Player** (`replay_player_screen.dart`): virou `StatefulWidget`. Compartilhar (header) → `showReplayShareSheet`; "Salvar no perfil" → `upsert` em `saved_replays` com `UserProvider.id`; "Salvar na galeria" → mensagem honesta (depende do player real, #2).
- **Splash** (`splash_screen.dart`): "Criar conta" → `RegisterScreen`; "Explorar como visitante" → `LoginScreen`. O timer de auto-navegação é cancelado ao tocar.
- **Login** (`login_screen.dart` + `auth_service.dart`): "Esqueci minha senha" → `AuthService.resetPassword` (`resetPasswordForEmail`), com validação do e-mail e snackbar.
- **Profile** (`profile_screen.dart`): ícone de configurações → bottom sheet com "Sair da conta" (`signOut`); "Ver todos" → `DraggableScrollableSheet` listando os replays salvos (tap abre o player).
- **Arena Pública** (`arena_public_screen.dart`): "Ver tudo" alterna `_showAllReplays` (ignora o filtro de quadra); rótulo vira "Filtrar por quadra".

### #5 — Testes
- `test/app_flow_test.dart`: fluxo widget-level executável no CI (boot da splash + navegação automática para o login).
- `integration_test/app_test.dart` + dep `integration_test`: scaffold E2E. Caso boot→login roda; o fluxo autenticado (login → CRUD admin → home) está documentado com `skip: true` até haver um Supabase de teste.

### #6 — Owner Dashboard
- Já estava implementado com persistência real (`_updateArenaStatus`, `_updateCourtLiveStatus`, copiar link, toggle ao vivo, compartilhar). Apenas confirmado/validado — sem alterações.

### Validação
- `flutter analyze` → **No issues found!**
- `flutter test` → **20/20 passando** (admin_controller 11, city_grouping 6, widget 1, app_flow 2).

---

## Iteração — Automação do admin + Supabase

- `AdminController` (ChangeNotifier) sobre `AdminService` (interface `AdminDataSource`); painel admin migrado de `MockService` para o controller; `MockService` removido.
- Home passou a consumir `cities` + `arenas` do Supabase; agrupamento extraído para `lib/utils/city_grouping.dart`.
- `supabase/schema.sql`: coluna `uf` em `arenas` + tabela `cities` (RLS/trigger/seed, idempotente).
- Credenciais Supabase via `--dart-define` (fallback no `main.dart`).
- CI `.github/workflows/flutter.yml` (analyze + test). Testes unitários de `AdminController` e `city_grouping`.

# ReplayGO — MVP Frontend (Flutter)

ReplayGO é um aplicativo mobile voltado para replays instantâneos em quadras de areia. Este repositório contém a estrutura do MVP (Fase 1), incluindo tema, rotas, integração com Supabase para autenticação e dados reais, além da navegação entre papéis (cliente, proprietário, admin) via GoRouter.

## 📱 Visão Geral
- **Framework:** Flutter (Material)
- **Gerenciamento de estado:** Provider
- **Navegação:** GoRouter
- **Reprodutor de vídeo (placeholder):** better_player + video_player (apenas dependências)
- **Armazenamento local (futuro):** shared_preferences (já configurado no pubspec)
- **Cliente HTTP (futuro):** Dio
- **Supabase:** Autenticação, perfis, cidades, arenas, replays e favoritos (única fonte de dados)

## 🎨 Design Tokens
- **Primária:** `#FF6B00`
- **Secundária/CTA:** `#CC1E1E`
- **Texto:** `#111111`
- **Fundo claro:** `#FAF7F2`
- **Fundo escuro:** `#1A0A00`
- **Tipografia:** Montserrat (via `google_fonts`)
- **Raios:** 16px em cards e 50px em botões primários

Tudo isso está centralizado no tema em `lib/core/theme/app_theme.dart` e nas constantes em `lib/core/constants/app_colors.dart`.

## 🧱 Estrutura de Pastas
```
lib/
├── main.dart                # Entry point
├── app.dart                 # Configura Provider + GoRouter
├── core/
│   ├── constants/
│   │   └── app_colors.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── routes/
│       └── app_router.dart   # Declara rotas e shell
├── models/                  # User, Arena, Court, Replay, Camera
├── services/
│   └── mock_service.dart    # Dados mockados do MVP
├── screens/                 # 9 telas do MVP (inclui fluxo de registro)
└── widgets/                 # Componentes reutilizáveis
```

## 📄 Telas Implementadas
Todas usam conteúdo mockado e placeholders para vídeos.

1. **Splash (`/`)** — Tema escuro com gradiente, botões de entrada e auto navegação para login.
2. **Login (`/login`)** — Autenticação via Supabase, identifica o papel salvo no perfil e direciona para a área correta.
3. **Registro (`/register`)** — Formulário público para criar contas de cliente, com envio de metadados e upsert em `profiles`.
4. **Home Shell (`/home`)** — Bottom nav com abas Home/Buscar/Replays/Perfil. Conteúdo para usuário final.
5. **Arena Pública (`/arena`)** — Player placeholder, seleção de quadra, grade de replays 2xN.
6. **Replay Player (`/replay`)** — Tela dark com controles e botões de salvar.
7. **Perfil (`/profile`)** — Estatísticas, cards de replays e histórico de atividade.
8. **Owner Dashboard (`/owner`)** — Cartão de streaming, métricas e lista de replays recentes.
9. **Admin Panel (`/admin`)** — Estatísticas gerais, busca, gerenciamento de arenas e criação de proprietários.

## 🧩 Widgets Compartilhados
- `ReplayGoBottomNavBar`
- `LiveBadge`
- `ArenaListTile`
- `ReplayCard`
- `StatsCard`
- `RoleSelector`

## 🗃️ Fontes de Dados
- **Supabase (única fonte)**
  - Perfis de usuários carregados via `UserProvider`
  - Cidades, arenas, quadras e replays consumidos diretamente das tabelas
  - Replays salvos gravados em `saved_replays`
  - Painel admin opera 100% via `AdminService`, orquestrado pelo `AdminController`
    (`ChangeNotifier` com cache + CRUD assíncrono e auto-refresh). O `MockService`
    foi removido.

## 🔐 Autenticação & Perfis (Supabase)
- Implementado com `supabase_flutter` e monitorado em `app.dart` para carregar o perfil autenticado.
- `AuthService` centraliza `signUpClient`, `signUpOwner`, login, logout e leitura de papel.
- `UserProvider` guarda o `ProfileModel`, expõe estados de loading/erro e inicializa a navegação pós-login.
- Perfis são carregados diretamente da tabela `profiles`; replays salvos e métricas usam as tabelas correspondentes.
- Proprietários e admins seguem cadastrados via painel admin (em migração para Supabase).

### 🔧 Configuração rápida do Supabase
1. **Aplique o schema:** rode `supabase/schema.sql` no SQL Editor do seu projeto.
   Ele é idempotente e já inclui a coluna `uf` em `arenas` e a tabela `cities`
   (com RLS e seed), necessárias para o painel admin automatizado.
2. **Credenciais:** use os valores padrão em `lib/main.dart` ou externalize via
   `--dart-define`:
   ```bash
   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```
3. Execute `flutter pub get`.
4. Rode o app (`flutter run`) e valide o fluxo de registro/login.

### 🤖 Integração Contínua
- Workflow `.github/workflows/flutter.yml` roda `flutter analyze` e `flutter test`
  em cada push/PR (branches `main` e `Japones`).

## 🚧 Andamento do MVP
- ✅ Navegação GoRouter configurada com 8 telas interligadas.
- ✅ Tema, tipografia, cores e componentes compartilhados padronizados.
- ✅ Autenticação e carregamento de perfil integrados ao Supabase.
- ✅ Telas de Perfil, Home, Owner Dashboard e Arena Pública consumindo dados reais.
- ✅ Painel admin 100% no Supabase (dashboard com métricas reais + CRUD de cidades/arenas via `AdminController`).
- ✅ Home consome cidades e arenas do Supabase (carrosséis por cidade, incluindo cidades sem arenas).
- ⚠️ Players de vídeo ainda são placeholders (dependências já no `pubspec`).
- ⚠️ Integrações externas adicionais (Dio/shared_preferences) aguardando backend.
- ✅ Botões avançados (compartilhar, controle fino de arenas) liberados nas telas de replays e painel do proprietário.

## 🧪 Fluxo de Testes Locais
1. Garanta que o Flutter SDK está atualizado (`flutter --version`).
2. Rode os testes padrões do Flutter:
   ```bash
   flutter test
   ```
3. Faça um dry-run para detectar lints obrigatórios:
   ```bash
   flutter analyze
   ```
4. Execute o app:
   ```bash
   flutter run -d chrome   # ou selecione outro dispositivo disponível
   ```
5. Use credenciais mockadas ou crie usuários reais (cliente pelo `/register`, proprietário via painel admin) para navegar pelos papéis.

## ✅ Checklist de Validação Manual
Antes de liberar uma entrega, execute estes testes rápidos:

- [ ] Login como **admin@replaygo.com / Test@1234** e confirme o redirecionamento para o **Admin Panel**.
- [ ] Login como **arena@replaygo.com / Test@1234** e confirme o redirecionamento para o **Owner Dashboard**.
- [ ] Login como cliente pelo `/register` ou usando conta existente e confirme o acesso ao **Home Shell**.
- [ ] Na **Arena Pública**, realize ações de salvar e compartilhar replay (verifique snackbars de sucesso/falha).
- [ ] No **Owner Dashboard**, abra “Controles avançados”, altere status da arena e visibilidade das quadras, e valide o feedback exibido.
- [ ] Execute uma navegação completa: Home → Arena Pública → Replay Player → Perfil e retorne ao dashboard apropriado.

## 🧭 Organização de Branches e Git
- `main`: branch estável com o MVP navegável (use para releases e demonstrações).
- `Kaua`: branch de trabalho antigo. Prefira continuar em `main` ou crie feature branches (`feature/nome-feature`).
- Antes de commitar: `git status` (checar arquivos) → `git diff` (validar alterações) → `flutter analyze`.
- Artefatos gerados (`.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`) estão ignorados; rode `flutter pub get` após clonar ou trocar de branch.
- Mensagens de commit: siga o formato `tipo: resumo curto` (ex.: `docs: atualiza README com andamento do projeto`).

> Dica: se precisar limpar o cache entre builds, execute `flutter clean` seguido de `flutter pub get`.

## �🚀 Como Rodar
1. **Pré-requisitos:** Flutter SDK instalado e no PATH (`flutter --version` deve funcionar).
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute em um emulador/dispositivo:
   ```bash
   flutter run
   ```

> ℹ️ Atualmente os players de vídeo são placeholders. As dependências `better_player` e `video_player` já estão no `pubspec` para uso futuro.

## 🔄 Fluxo de Navegação
```
Splash → Login
Login → (Usuário) Home Shell
       → (Proprietário) Owner Dashboard
       → (Admin) Admin Panel

Home Shell → Arena Pública → Replay Player → Perfil
```

## ✅ Últimas Atualizações
- Migração do `UserProvider` para lidar com `ProfileModel` completo, incluindo estados de erro.
- `app.dart` escuta mudanças de sessão Supabase e redireciona conforme o papel do usuário.
- Perfil, Owner Dashboard e Arena Pública agora exibem arenas/replays reais com estados de loading/erro.
- Criação do `AdminService` para centralizar operações do painel administrativo usando Supabase.
- Novo utilitário `normalizeReplayRow` para padronizar joins de arenas/quadras/replays.

## ✅ Estado Atual
- ✅ Base do app, UI/UX, rotas e integração Supabase (usuário/owner) em produção.
- ✅ Fluxo de salvar replays direcionado à tabela `saved_replays`.
- ✅ Painel admin 100% no Supabase via `AdminService`/`AdminController`; `MockService` removido.
- ✅ Home consome cidades + arenas do Supabase (carrosséis por cidade, inclusive sem arenas).
- ✅ Tabela `cities` + coluna `uf` em `arenas` no schema; credenciais via `--dart-define`.
- ✅ CI (`flutter analyze` + `flutter test`) no GitHub Actions.
- ✅ Testes: `AdminController` (CRUD/loading/erro), agrupamento por cidade (`utils/city_grouping`) e fluxo de boot (`app_flow_test`).
- ✅ Ações do Painel Geral do admin: **Suspender/Reativar** (status via `AdminController`), **Ver replays** (abre a arena) e **Detalhes** (diálogo).
- ✅ Botões antes sem ação implementados: Replay Player (compartilhar + salvar no perfil), Splash (Criar conta / Visitante), Login (Esqueci minha senha via `AuthService.resetPassword`), Profile (Sair / Ver todos), Arena ("Ver tudo" alterna o filtro de quadra).
- ✅ Owner Dashboard com persistência real (status da arena, visibilidade de quadras, copiar link, compartilhar) — confirmado.
- ✅ Scaffold de `integration_test/` para E2E (boot→login executável; fluxo autenticado documentado/`skip`).

## 🗺️ Próximos Passos
1. **Deploy do schema (ops):** aplicar `supabase/schema.sql` no projeto Supabase (cria `cities` + coluna `uf`) e validar o **Checklist de Validação Manual** acima.
2. **Player de vídeo real:** substituir `_VideoPlayerPlaceholder` (arena pública) e o player do Replay Player por `better_player`/`video_player`; isso também habilita o "Salvar na galeria".
3. **E2E autenticado:** habilitar o caso `skip` em `integration_test/app_test.dart` (login → CRUD admin → home) contra um Supabase de teste com o schema aplicado.

> 📓 O passo a passo de cada iteração fica documentado em [`docs/DEV_LOG.md`](docs/DEV_LOG.md).

## 📚 Histórico de Alterações Principais
- Criação do `pubspec.yaml` com dependências solicitadas + `google_fonts`.
- Entrypoint (`main.dart`) e container do app (`app.dart`) com tema e GoRouter.
- Definição de temas, cores e cards reutilizáveis.
- Modelos (`models/`) e `MockService` com dataset completo fornecido no briefing.
- Implementação das 8 telas do MVP e widgets auxiliares conforme layout orientado.

---
Qualquer ajuste futuro (ex.: conectar APIs, ligar botões reais, lidar com vídeo) deve respeitar essa base. Se precisar de instruções adicionais, só avisar! 

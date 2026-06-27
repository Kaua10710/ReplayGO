# ReplayGO — MVP Frontend (Flutter)

ReplayGO é um aplicativo mobile voltado para replays instantâneos em quadras de areia. Este repositório contém a estrutura do MVP (Fase 1), incluindo temas, rotas, dados mockados e 8 telas conectadas via GoRouter.

## 📱 Visão Geral
- **Framework:** Flutter (Material)
- **Gerenciamento de estado:** Provider
- **Navegação:** GoRouter
- **Reprodutor de vídeo (placeholder):** better_player + video_player (apenas dependências)
- **Armazenamento local (futuro):** shared_preferences (já configurado no pubspec)
- **Cliente HTTP (futuro):** Dio
- **Mock service:** Dados hardcoded em `MockService`

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
├── screens/                 # 8 telas do MVP
└── widgets/                 # Componentes reutilizáveis
```

## 📄 Telas Implementadas
Todas usam conteúdo mockado e placeholders para vídeos.

1. **Splash (`/`)** — Tema escuro com gradiente, botões de entrada e auto navegação para login.
2. **Login (`/login`)** — Fundo claro, seletor de papel (usuário, proprietário, admin) e navegação condicional.
3. **Home Shell (`/home`)** — Bottom nav com abas Home/Buscar/Replays/Perfil. Conteúdo para usuário final.
4. **Arena Pública (`/arena`)** — Player placeholder, seleção de quadra, grade de replays 2xN.
5. **Replay Player (`/replay`)** — Tela dark com controles e botões de salvar.
6. **Perfil (`/profile`)** — Estatísticas, cards de replays e histórico de atividade.
7. **Owner Dashboard (`/owner`)** — Cartão de streaming, métricas e lista de replays recentes.
8. **Admin Panel (`/admin`)** — Estatísticas gerais, busca e lista de arenas com bottom sheet de ações.

## 🧩 Widgets Compartilhados
- `ReplayGoBottomNavBar`
- `LiveBadge`
- `ArenaListTile`
- `ReplayCard`
- `StatsCard`
- `RoleSelector`

## 🗃️ Dados Mockados
Definidos em `lib/services/mock_service.dart` com:
- Usuário (Lucas Carvalho), proprietário (Arena Beira Mar), admin (AD)
- Lista de arenas com status LIVE/ATIVO/INATIVO
- Replays da Arena Beira Mar com visibilidade PÚBLICO/EXPIRADO
- Lista de câmeras para o owner dashboard

`MockService` fornece métodos de acesso usados pelas telas via `Provider`.

## 🚀 Como Rodar
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

## ✅ Estado Atual & Próximos Passos
- ✅ Estrutura do app, UI/UX, rotas e dados mock prontos.
- ⏳ Aguardando integração real de vídeo, APIs via Dio e persistência local.
- ⏳ Botões de ação (salvar, compartilhar, criar conta, etc.) aguardam implementação real.

## 📚 Histórico de Alterações Principais
- Criação do `pubspec.yaml` com dependências solicitadas + `google_fonts`.
- Entrypoint (`main.dart`) e container do app (`app.dart`) com tema e GoRouter.
- Definição de temas, cores e cards reutilizáveis.
- Modelos (`models/`) e `MockService` com dataset completo fornecido no briefing.
- Implementação das 8 telas do MVP e widgets auxiliares conforme layout orientado.

---
Qualquer ajuste futuro (ex.: conectar APIs, ligar botões reais, lidar com vídeo) deve respeitar essa base. Se precisar de instruções adicionais, só avisar! 

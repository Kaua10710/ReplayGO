import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive.dart';
import '../../models/arena_model.dart';
import '../../models/city_model.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/mock_service.dart';
import '../../widgets/arena_list_tile.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  static const String routeName = 'admin-panel';
  static const String routePath = '/admin';

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

// =============================================================================
// Contas
// =============================================================================
class _ManageAccountsView extends StatefulWidget {
  const _ManageAccountsView();

  @override
  State<_ManageAccountsView> createState() => _ManageAccountsViewState();
}

class _ManageAccountsViewState extends State<_ManageAccountsView> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController(text: 'Owner@1234');
  bool _isSubmitting = false;
  String? _error;
  List<ProfileModel> _owners = const [];

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadOwners() async {
    final authService = context.read<AuthService>();
    try {
      final owners = await authService.fetchProfilesByRole(UserRole.owner);
      if (mounted) {
        setState(() => _owners = owners);
      }
    } catch (_) {
      // Silencia erros para não quebrar a tela; administração pode estar offline.
    }
  }

  Future<void> _handleCreateOwner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = context.read<AuthService>();
    final name = _ownerNameController.text.trim();
    final email = _ownerEmailController.text.trim();
    final password = _ownerPasswordController.text;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await authService.signUpOwner(
        email: email,
        password: password,
        name: name,
      );
      if (!mounted) return;

      _ownerNameController.clear();
      _ownerEmailController.clear();
      _ownerPasswordController.text = 'Owner@1234';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convite enviado para $email. Oriente o proprietário a verificar o email.'),
        ),
      );

      await _loadOwners();
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível criar a conta. Verifique os dados e tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Criar acesso de estabelecimento',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilize este formulário para convidar novas arenas. Um email será enviado com instruções de acesso.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da arena / responsável',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do estabelecimento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de contato',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o email do responsável.';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Senha inicial',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _ownerPasswordController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Senha copiada para a área de transferência.')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Informe uma senha com pelo menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondary),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleCreateOwner,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(_isSubmitting ? 'Enviando convite...' : 'Criar acesso de proprietário'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Proprietários ativos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_owners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'Nenhum proprietário cadastrado ainda.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
              ),
            )
          else
            Column(
              children: _owners
                  .map(
                    (owner) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            child: Text(owner.name.isNotEmpty ? owner.name[0].toUpperCase() : 'P'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owner.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  owner.email,
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            owner.createdAt.toLocal().toIso8601String().substring(0, 10),
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedGray),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection(this.label, this.icon, this.view);
  final String label;
  final IconData icon;
  final Widget view;
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  static const _sections = <_AdminSection>[
    _AdminSection('Painel Geral', Icons.dashboard_outlined, _GeneralPanelView()),
    _AdminSection('Contas', Icons.person_add_alt_1_outlined, _ManageAccountsView()),
    _AdminSection('Cadastrar Cidades', Icons.add_location_alt_outlined, _RegisterCityView()),
    _AdminSection('Cadastrar Arenas', Icons.add_business_outlined, _RegisterArenaView()),
    _AdminSection('Configurações', Icons.settings_outlined, _SettingsView()),
  ];

  void _select(int index, {bool fromDrawer = false}) {
    setState(() => _selectedIndex = index);
    if (fromDrawer) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.hasWideLayout;
    final title = _sections[_selectedIndex].label;

    final body = IndexedStack(
      index: _selectedIndex,
      children: _sections.map((s) => s.view).toList(),
    );

    if (wide) {
      // Layout web/desktop: sidebar fixa à esquerda.
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Row(
            children: [
              _AdminNav(
                permanent: true,
                selectedIndex: _selectedIndex,
                sections: _sections,
                onSelect: (i) => _select(i),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ResponsiveCenter(
                        maxWidth: 1100,
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Layout mobile: AppBar + Drawer.
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: _AdminNav(
          permanent: false,
          selectedIndex: _selectedIndex,
          sections: _sections,
          onSelect: (i) => _select(i, fromDrawer: true),
        ),
      ),
      body: body,
    );
  }
}

class _AdminNav extends StatelessWidget {
  const _AdminNav({
    required this.permanent,
    required this.selectedIndex,
    required this.sections,
    required this.onSelect,
  });

  final bool permanent;
  final int selectedIndex;
  final List<_AdminSection> sections;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'AD',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ReplayGO',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Administração',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < sections.length; i++)
            _NavItem(
              icon: sections[i].icon,
              label: sections[i].label,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );

    if (!permanent) return content;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0x11000000))),
      ),
      child: content,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.text;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}

// =============================================================================
// Painel Geral
// =============================================================================
class _GeneralPanelView extends StatelessWidget {
  const _GeneralPanelView();

  void _showActions(BuildContext context, ArenaModel arena) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                arena.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Suspender'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Ver replays'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: const Text('Detalhes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<MockService>();
    final arenas = service.arenas;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                const _AdminStatCard(
                  icon: Icons.group_outlined,
                  value: '2.847',
                  label: 'Usuários',
                ),
                const _AdminStatCard(
                  icon: Icons.play_circle_outline,
                  value: '18.2k',
                  label: 'Replays',
                ),
                _AdminStatCard(
                  icon: Icons.location_city_outlined,
                  value: '${service.cities.length}',
                  label: 'Cidades',
                ),
                _AdminStatCard(
                  icon: Icons.sports_volleyball_outlined,
                  value: '${arenas.length}',
                  label: 'Arenas',
                ),
              ];
              final perRow = constraints.maxWidth >= 720 ? 4 : 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map((c) => SizedBox(
                          width: (constraints.maxWidth - (perRow - 1) * 12) / perRow,
                          child: c,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar estabelecimento...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estabelecimentos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${arenas.length} registrados',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: arenas.map((arena) {
              return ArenaListTile(
                arena: arena,
                onMorePressed: () => _showActions(context, arena),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cadastrar Cidades
// =============================================================================
class _RegisterCityView extends StatefulWidget {
  const _RegisterCityView();

  @override
  State<_RegisterCityView> createState() => _RegisterCityViewState();
}

class _RegisterCityViewState extends State<_RegisterCityView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ufController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ufController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<MockService>();
    final name = _nameController.text.trim();
    final uf = _ufController.text.trim();

    if (service.cityExists(name, uf)) {
      showAdminSnack(context, 'Essa cidade já está cadastrada.', isError: true);
      return;
    }
    final city = service.addCity(name, uf);
    _nameController.clear();
    _ufController.clear();
    FocusScope.of(context).unfocus();
    showAdminSnack(context, '${city.name} - ${city.uf} cadastrada com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = context.watch<MockService>().cities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nova cidade',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'A cidade cadastrada aparece automaticamente na tela inicial do usuário.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: adminFieldDecoration('Nome da cidade', Icons.location_city_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome da cidade' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ufController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z]'))],
                  decoration: adminFieldDecoration('UF (ex.: GO)', Icons.map_outlined),
                  validator: (v) =>
                      (v == null || v.trim().length != 2) ? 'Informe a UF (2 letras)' : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar cidade'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Cidades cadastradas (${cities.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...cities.map(
            (city) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  child: Text(city.uf, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                title: Text(city.name),
                subtitle: Text(city.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cadastrar Arenas
// =============================================================================
class _RegisterArenaView extends StatelessWidget {
  const _RegisterArenaView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<MockService>();
    final cities = service.cities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nova arena',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'A arena é vinculada a uma cidade e aparece no carrossel correspondente da home.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          ),
          const SizedBox(height: 20),
          if (cities.isEmpty)
            const _EmptyHint(
              icon: Icons.location_off_outlined,
              text: 'Cadastre uma cidade antes de adicionar arenas.',
            )
          else
            ArenaForm(
              cities: cities,
              submitLabel: 'Cadastrar arena',
              onSubmit: (data) {
                service.addArena(
                  name: data.name,
                  city: data.city,
                  uf: data.uf,
                  isLive: data.isLive,
                  replayCount: data.replayCount,
                  status: data.status,
                );
                showAdminSnack(context, '${data.name} cadastrada com sucesso!');
              },
              resetAfterSubmit: true,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Configurações (CRUD de arenas e cidades)
// =============================================================================
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedGray,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Arenas', icon: Icon(Icons.sports_volleyball_outlined)),
              Tab(text: 'Cidades', icon: Icon(Icons.location_city_outlined)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ArenasCrudTab(),
                _CitiesCrudTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenasCrudTab extends StatelessWidget {
  const _ArenasCrudTab();

  Future<void> _edit(BuildContext context, ArenaModel arena) async {
    final service = context.read<MockService>();
    await showDialog<void>(
      context: context,
      builder: (_) => _ArenaEditDialog(arena: arena, cities: service.cities),
    );
  }

  Future<void> _delete(BuildContext context, ArenaModel arena) async {
    final ok = await confirmDelete(context, 'Excluir a arena "${arena.name}"?');
    if (ok && context.mounted) {
      context.read<MockService>().removeArena(arena.id);
      showAdminSnack(context, 'Arena removida.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final arenas = context.watch<MockService>().arenas;
    if (arenas.isEmpty) {
      return const _EmptyHint(icon: Icons.inbox_outlined, text: 'Nenhuma arena cadastrada.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: arenas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final arena = arenas[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.sports_volleyball_outlined),
            ),
            title: Text(arena.name),
            subtitle: Text('${arena.city} - ${arena.uf} · ${arena.replayCount} replays'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, arena),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.secondary),
                  onPressed: () => _delete(context, arena),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CitiesCrudTab extends StatelessWidget {
  const _CitiesCrudTab();

  Future<void> _edit(BuildContext context, CityModel city) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CityEditDialog(city: city),
    );
  }

  Future<void> _delete(BuildContext context, CityModel city) async {
    final ok = await confirmDelete(
      context,
      'Excluir "${city.label}"? As arenas dessa cidade deixam de aparecer no carrossel.',
    );
    if (ok && context.mounted) {
      context.read<MockService>().removeCity(city.id);
      showAdminSnack(context, 'Cidade removida.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<MockService>().cities;
    if (cities.isEmpty) {
      return const _EmptyHint(icon: Icons.inbox_outlined, text: 'Nenhuma cidade cadastrada.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: cities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final city = cities[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              child: Text(city.uf, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            title: Text(city.name),
            subtitle: Text(city.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, city),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.secondary),
                  onPressed: () => _delete(context, city),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArenaEditDialog extends StatelessWidget {
  const _ArenaEditDialog({required this.arena, required this.cities});

  final ArenaModel arena;
  final List<CityModel> cities;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar arena',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              ArenaForm(
                cities: cities,
                initial: arena,
                submitLabel: 'Salvar alterações',
                onSubmit: (data) {
                  context.read<MockService>().updateArena(
                        arena.id,
                        name: data.name,
                        city: data.city,
                        uf: data.uf,
                        isLive: data.isLive,
                        replayCount: data.replayCount,
                        status: data.status,
                      );
                  Navigator.of(context).pop();
                  showAdminSnack(context, 'Arena atualizada.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityEditDialog extends StatefulWidget {
  const _CityEditDialog({required this.city});
  final CityModel city;

  @override
  State<_CityEditDialog> createState() => _CityEditDialogState();
}

class _CityEditDialogState extends State<_CityEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.city.name);
  late final TextEditingController _uf = TextEditingController(text: widget.city.uf);

  @override
  void dispose() {
    _name.dispose();
    _uf.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MockService>().updateCity(
          widget.city.id,
          name: _name.text,
          uf: _uf.text,
        );
    Navigator.of(context).pop();
    showAdminSnack(context, 'Cidade atualizada.');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar cidade',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: adminFieldDecoration('Nome da cidade', Icons.location_city_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _uf,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z]'))],
                  decoration: adminFieldDecoration('UF', Icons.map_outlined),
                  validator: (v) =>
                      (v == null || v.trim().length != 2) ? 'UF inválida' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _save, child: const Text('Salvar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Formulário reutilizável de arena (cadastro + edição)
// =============================================================================
class ArenaFormData {
  const ArenaFormData({
    required this.name,
    required this.city,
    required this.uf,
    required this.isLive,
    required this.replayCount,
    required this.status,
  });

  final String name;
  final String city;
  final String uf;
  final bool isLive;
  final int replayCount;
  final ArenaStatus status;
}

class ArenaForm extends StatefulWidget {
  const ArenaForm({
    super.key,
    required this.cities,
    required this.onSubmit,
    required this.submitLabel,
    this.initial,
    this.resetAfterSubmit = false,
  });

  final List<CityModel> cities;
  final ValueChanged<ArenaFormData> onSubmit;
  final String submitLabel;
  final ArenaModel? initial;
  final bool resetAfterSubmit;

  @override
  State<ArenaForm> createState() => _ArenaFormState();
}

class _ArenaFormState extends State<ArenaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _replays;
  CityModel? _city;
  late bool _isLive;
  late ArenaStatus _status;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _name = TextEditingController(text: a?.name ?? '');
    _replays = TextEditingController(text: a != null ? '${a.replayCount}' : '0');
    _isLive = a?.isLive ?? false;
    _status = a?.status ?? ArenaStatus.active;
    if (a != null) {
      _city = widget.cities.firstWhere(
        (c) => c.name.toLowerCase() == a.city.toLowerCase(),
        orElse: () => widget.cities.first,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _replays.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      showAdminSnack(context, 'Selecione uma cidade.', isError: true);
      return;
    }
    widget.onSubmit(ArenaFormData(
      name: _name.text.trim(),
      city: _city!.name,
      uf: _city!.uf,
      isLive: _isLive,
      replayCount: int.tryParse(_replays.text.trim()) ?? 0,
      status: _status,
    ));
    if (widget.resetAfterSubmit) {
      _name.clear();
      _replays.text = '0';
      setState(() {
        _isLive = false;
        _status = ArenaStatus.active;
        _city = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: adminFieldDecoration('Nome da arena', Icons.sports_volleyball_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome da arena' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CityModel>(
            initialValue: _city,
            isExpanded: true,
            decoration: adminFieldDecoration('Cidade', Icons.location_city_outlined),
            items: widget.cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (c) => setState(() => _city = c),
            validator: (v) => v == null ? 'Selecione a cidade' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _replays,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: adminFieldDecoration('Nº de replays', Icons.videocam_outlined),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ArenaStatus>(
            initialValue: _status,
            decoration: adminFieldDecoration('Status', Icons.flag_outlined),
            items: const [
              DropdownMenuItem(value: ArenaStatus.active, child: Text('Ativo')),
              DropdownMenuItem(value: ArenaStatus.inactive, child: Text('Inativo')),
            ],
            onChanged: (s) => setState(() => _status = s ?? ArenaStatus.active),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transmitindo ao vivo'),
            value: _isLive,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _isLive = v),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers compartilhados
// =============================================================================
InputDecoration adminFieldDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

void showAdminSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.secondary : AppColors.primary,
      ),
    );
}

Future<bool> confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar exclusão'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.mutedGray),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedGray),
          ),
        ],
      ),
    );
  }
}

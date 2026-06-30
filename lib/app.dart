import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'models/profile_model.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/admin_controller.dart';
import 'providers/user_provider.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';

class ReplayGoApp extends StatefulWidget {
  const ReplayGoApp({super.key});

  @override
  State<ReplayGoApp> createState() => _ReplayGoAppState();
}

class _ReplayGoAppState extends State<ReplayGoApp> {
  late final AppRouter _appRouter;
  final AuthService _authService = AuthService();
  final UserProvider _userProvider = UserProvider();
  final AdminService _adminService = AdminService();
  late final AdminController _adminController = AdminController(_adminService);

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    _authService.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn) {
        try {
          await _userProvider.loadProfile();
        } catch (_) {
          // intentionally ignored; UserProvider maintains error state.
        }
        _redirect(session);
      } else if (event == AuthChangeEvent.signedOut) {
        _userProvider.clearProfile();
        _appRouter.router.go(SplashScreen.routePath);
      }
    });

    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      _userProvider.loadProfile().whenComplete(() {
        if (mounted) {
          _redirect(currentSession);
        }
      });
    }
  }

  Future<void> _redirect(Session? session) async {
    if (session == null) {
      _appRouter.router.go(SplashScreen.routePath);
      return;
    }

    final role = await _authService.getCurrentUserRole();
    if (!mounted) return;

    switch (role) {
      case UserRole.owner:
        _appRouter.router.go(OwnerDashboardScreen.routePath);
        break;
      case UserRole.admin:
        _appRouter.router.go(AdminPanelScreen.routePath);
        break;
      case UserRole.user:
        _appRouter.router.go(HomeShell.routePath);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminController>.value(value: _adminController),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        Provider<AuthService>.value(value: _authService),
        Provider<AdminService>.value(value: _adminService),
      ],
      child: MaterialApp.router(
        title: 'ReplayGO',
        debugShowCheckedModeBanner: false,
        theme: buildReplayGoTheme(),
        routerConfig: _appRouter.router,
      ),
    );
  }
}

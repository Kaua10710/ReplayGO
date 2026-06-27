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
import 'services/auth_service.dart';
import 'services/mock_service.dart';

class ReplayGoApp extends StatefulWidget {
  const ReplayGoApp({super.key});

  @override
  State<ReplayGoApp> createState() => _ReplayGoAppState();
}

class _ReplayGoAppState extends State<ReplayGoApp> {
  late final AppRouter _appRouter;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(MockService());
    _authService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn) {
        _redirect(session);
      } else if (event == AuthChangeEvent.signedOut) {
        _appRouter.router.go(SplashScreen.routePath);
      }
    });
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
      default:
        _appRouter.router.go(SplashScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MockService>.value(value: _appRouter.service),
        Provider<AuthService>.value(value: _authService),
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

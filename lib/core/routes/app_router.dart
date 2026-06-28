import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../screens/admin/admin_panel_screen.dart';
import '../../screens/arena/arena_public_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/owner/owner_dashboard_screen.dart';
import '../../screens/player/replay_player_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class AppRouter {
  AppRouter()
      : router = GoRouter(
          initialLocation: SplashScreen.routePath,
          navigatorKey: _rootNavigatorKey,
          routes: _routes,
        );
  final GoRouter router;

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final _routes = <GoRoute>[
    GoRoute(
      path: SplashScreen.routePath,
      name: SplashScreen.routeName,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: LoginScreen.routePath,
      name: LoginScreen.routeName,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RegisterScreen.routePath,
      name: RegisterScreen.routeName,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: HomeShell.routePath,
      name: HomeShell.routeName,
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: ArenaPublicScreen.routePath,
      name: ArenaPublicScreen.routeName,
      builder: (context, state) {
        final extra = state.extra;
        return ArenaPublicScreen(routeData: extra);
      },
    ),
    GoRoute(
      path: ReplayPlayerScreen.routePath,
      name: ReplayPlayerScreen.routeName,
      builder: (context, state) {
        final extra = state.extra;
        return ReplayPlayerScreen(routeData: extra);
      },
    ),
    GoRoute(
      path: ProfileScreen.routePath,
      name: ProfileScreen.routeName,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: OwnerDashboardScreen.routePath,
      name: OwnerDashboardScreen.routeName,
      builder: (context, state) => const OwnerDashboardScreen(),
    ),
    GoRoute(
      path: AdminPanelScreen.routePath,
      name: AdminPanelScreen.routeName,
      builder: (context, state) => const AdminPanelScreen(),
    ),
  ];
}

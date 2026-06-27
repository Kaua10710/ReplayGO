import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/mock_service.dart';

class ReplayGoApp extends StatefulWidget {
  const ReplayGoApp({super.key});

  @override
  State<ReplayGoApp> createState() => _ReplayGoAppState();
}

class _ReplayGoAppState extends State<ReplayGoApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(MockService());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MockService>.value(value: _appRouter.service),
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

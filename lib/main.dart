import 'package:flutter/material.dart';

import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/debug/debug_helper.dart';

void main() {
  // Setup global error handling
  DebugHelper.setupGlobalErrorHandling();

  // Log app startup info
  AppConfig.logAppInfo();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.showDebugBanner,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}

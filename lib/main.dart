import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'core/constants/api_keys.dart';
import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/debug/debug_helper.dart';
import 'core/services/logging/app_logger.dart';
import 'core/theme/design_system.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling
  DebugHelper.setupGlobalErrorHandling();

  // Log app startup info
  AppConfig.logAppInfo();

  // Initialize Naver Map
  // await FlutterNaverMap().init(
  //   clientId: ApiKeys.naverMapClientId,
  //   onAuthFailed: (ex) {
  //     switch (ex) {
  //       case NQuotaExceededException(:final message):
  //         AppLogger.error("네이버 맵 사용량 초과", error: "message: $message");
  //         break;
  //       case NUnauthorizedClientException() ||
  //            NClientUnspecifiedException() ||
  //            NAnotherAuthFailedException():
  //         AppLogger.error("네이버 맵 인증 실패", error: ex);
  //         break;
  //     }
  //   }
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.showDebugBanner,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}

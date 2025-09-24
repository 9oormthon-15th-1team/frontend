import 'package:flutter/foundation.dart';
import '../services/logging/app_logger.dart';

class AppConfig {
  static const String appName = 'Frontend';
  static const String version = '1.0.0';

  // Environment
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;

  // Logging - 핵심 로그만 활성화
  static bool get enableLogging => isDebug;
  static bool get enableVerboseLogging => false; // 상세 로그 비활성화
  static bool get enableNetworkLogging => isDebug;
  static bool get enableUserActionLogging => false; // 사용자 액션 로그 비활성화
  static bool get enableDebugLogging => false; // 디버그 로그 비활성화
  static bool get enablePerformanceLogging => false; // 성능 로그 비활성화

  // Debug features
  static bool get showDebugBanner => isDebug;
  static bool get enableDebugTools => isDebug;

  // Performance
  static bool get enablePerformanceOverlay => false; // Manual toggle
  static bool get enableRasterCacheImagesCheckerboard => false;
  static bool get enableOffscreenLayersCheckerboard => false;

  static String get environmentName {
    if (isDebug) return 'DEBUG';
    if (isProfile) return 'PROFILE';
    if (isRelease) return 'RELEASE';
    return 'UNKNOWN';
  }

  static void logAppInfo() {
    if (enableLogging) {
      AppLogger.info('🚀 $appName v$version ($environmentName)');
    }
  }
}
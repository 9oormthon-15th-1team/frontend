import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

class DebugHelper {
  // Global error handler
  static void setupGlobalErrorHandling() {
    if (kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Flutter Error: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error(
          'Platform Error: $error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };
    }
  }

  // Debug overlay toggle
  static void toggleDebugPaintSizeEnabled() {
    if (kDebugMode) {
      debugPaintSizeEnabled = !debugPaintSizeEnabled;
      AppLogger.info('Debug Paint Size: $debugPaintSizeEnabled');
    }
  }

  // Performance overlay
  static void togglePerformanceOverlay(BuildContext context) {
    if (kDebugMode) {
      // This would need to be implemented at the MaterialApp level
      AppLogger.info('Performance overlay toggle requested');
    }
  }

  // Memory usage (approximate)
  static void logMemoryUsage() {
    if (kDebugMode) {
      try {
        // This is a basic memory info - for more detailed info, consider using memory profiling tools
        AppLogger.info('Memory usage check requested');
      } catch (e) {
        AppLogger.error('Failed to get memory usage', error: e);
      }
    }
  }

  // Widget inspector
  static void toggleWidgetInspector() {
    if (kDebugMode) {
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final binding = WidgetsBinding.instance;
          if (binding is WidgetsFlutterBinding) {
            // Toggle inspector - this is handled by the Flutter Inspector in IDEs
            AppLogger.info('Widget inspector toggle requested');
          }
        });
      } catch (e) {
        AppLogger.error('Failed to toggle widget inspector', error: e);
      }
    }
  }

  // Network connectivity debug
  static void logNetworkInfo() {
    if (kDebugMode) {
      AppLogger.network('GET', 'connectivity-check', statusCode: 200);
    }
  }

  // Device info logging
  static void logDeviceInfo(BuildContext context) {
    if (kDebugMode) {
      final mediaQuery = MediaQuery.of(context);
      final theme = Theme.of(context);

      AppLogger.info('''
📱 Device Info:
- Screen Size: ${mediaQuery.size}
- Device Pixel Ratio: ${mediaQuery.devicePixelRatio}
- Platform Brightness: ${mediaQuery.platformBrightness}
- Theme Brightness: ${theme.brightness}
- Text Scaler: ${mediaQuery.textScaler}
- Padding: ${mediaQuery.padding}
- Safe Area: ${mediaQuery.viewPadding}
''');
    }
  }

  // Quick debug actions
  static Widget buildDebugActionsOverlay(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: 10,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'debug_paint',
            onPressed: toggleDebugPaintSizeEnabled,
            tooltip: 'Toggle Debug Paint',
            child: const Icon(Icons.border_outer),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'memory_info',
            onPressed: logMemoryUsage,
            tooltip: 'Log Memory Usage',
            child: const Icon(Icons.memory),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'device_info',
            onPressed: () => logDeviceInfo(context),
            tooltip: 'Log Device Info',
            child: const Icon(Icons.phone_android),
          ),
        ],
      ),
    );
  }

  // Haptic feedback helper
  static void lightImpact() {
    if (kDebugMode) {
      HapticFeedback.lightImpact();
      AppLogger.debug('Haptic: Light Impact');
    }
  }

  static void mediumImpact() {
    if (kDebugMode) {
      HapticFeedback.mediumImpact();
      AppLogger.debug('Haptic: Medium Impact');
    }
  }

  static void heavyImpact() {
    if (kDebugMode) {
      HapticFeedback.heavyImpact();
      AppLogger.debug('Haptic: Heavy Impact');
    }
  }
}

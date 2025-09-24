import 'package:logger/logger.dart';
import '../../constants/app_config.dart';

// Custom simple printer without decorative lines
class SimplePrinter extends LogPrinter {
  static const Map<Level, AnsiColor?> levelColors = {
    Level.debug: AnsiColor.fg(12),
    Level.info: AnsiColor.fg(12),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.fatal: AnsiColor.fg(199),
  };

  static const Map<Level, String> levelEmojis = {
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💀',
  };

  @override
  List<String> log(LogEvent event) {
    final color = levelColors[event.level];
    final emoji = levelEmojis[event.level];
    final message = event.message;

    // Simple format: [TIME] EMOJI MESSAGE
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final formattedMessage = '[$time] $emoji $message';

    return color != null ? [color(formattedMessage)] : [formattedMessage];
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;

  AppLogger._internal() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(),
      output: ConsoleOutput(),
    );
  }

  // Debug log (only if enabled)
  static void debug(dynamic message, {Object? error, StackTrace? stackTrace}) {
    if (AppConfig.enableDebugLogging) {
      _instance._logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  // Info log
  static void info(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _instance._logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning log
  static void warning(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _instance._logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Error log
  static void error(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _instance._logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal log
  static void fatal(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _instance._logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Network request log (simplified)
  static void network(String method, String url, {Map<String, dynamic>? headers, dynamic body, int? statusCode}) {
    if (AppConfig.enableNetworkLogging) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      _instance._logger.i('🌐 $method $url$status');
    }
  }

  // User action log (only important actions)
  static void userAction(String action, {Map<String, dynamic>? data}) {
    if (AppConfig.enableUserActionLogging) {
      _instance._logger.i('👤 $action');
    }
  }

  // Navigation log (always shown for debugging routes)
  static void navigation(String action, String route, {String? previous}) {
    final prev = previous != null ? ' from $previous' : '';
    _instance._logger.i('🧭 $action: $route$prev');
  }

  // Performance log (only if enabled)
  static void performance(String operation, Duration duration) {
    if (AppConfig.enablePerformanceLogging) {
      _instance._logger.i('⚡ $operation: ${duration.inMilliseconds}ms');
    }
  }
}
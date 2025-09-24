// Example usage of AppLogger for different scenarios

import '../logging/app_logger.dart';

class ExampleUsage {
  static void demonstrateLogging() {
    // Basic logging
    AppLogger.debug('This is a debug message');
    AppLogger.info('App initialized successfully');
    AppLogger.warning('This is a warning message');
    AppLogger.error('An error occurred');

    // Logging with error and stack trace
    try {
      throw Exception('Sample exception');
    } catch (error, stackTrace) {
      AppLogger.error('Exception caught', error: error, stackTrace: stackTrace);
    }

    // Network logging
    AppLogger.network(
      'POST',
      'https://api.example.com/users',
      headers: {'Authorization': 'Bearer token'},
      body: {'name': 'John Doe', 'email': 'john@example.com'},
      statusCode: 201,
    );

    // User action logging
    AppLogger.userAction('Button Tap', data: {
      'screen': 'home',
      'button_id': 'login_button',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Performance logging
    final stopwatch = Stopwatch()..start();
    // Simulate some work
    Future.delayed(const Duration(milliseconds: 100), () {
      stopwatch.stop();
      AppLogger.performance('Database Query', stopwatch.elapsed);
    });
  }

  // Example of logging in different app states
  static void logAppStateChange(String state) {
    AppLogger.info('App state changed to: $state');
  }

  static void logApiCall(String endpoint, Map<String, dynamic> response) {
    AppLogger.network('GET', endpoint, statusCode: 200);
    AppLogger.debug('API Response: $response');
  }

  static void logUserInteraction(String action, String element) {
    AppLogger.userAction(action, data: {'element': element});
  }
}
import 'dart:developer' as developer;

/// Logger centralizado da aplicação
class AppLogger {
  static void info(String message) {
    developer.log(message, name: 'partiu.info');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'partiu.error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message) {
    developer.log(message, name: 'partiu.warning');
  }

  static void debug(String message) {
    developer.log(message, name: 'partiu.debug');
  }

  static void success(String message) {
    developer.log(message, name: 'partiu.success');
  }
}

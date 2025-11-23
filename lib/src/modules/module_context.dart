import 'package:neutronx/neutronx.dart';

/// Context provided to modules during registration
///
/// This context gives modules access to the application's DI container,
/// a router for registering routes, and configuration.
class ModuleContext {
  /// The application's dependency injection container
  final NeutronContainer container;

  /// Router for this module to register its routes
  final Router router;

  /// Application configuration
  final Map<String, dynamic> config;

  /// Logger function
  final void Function(String message) logger;

  ModuleContext({
    required this.container,
    required this.router,
    required this.config,
    void Function(String)? logger,
  }) : logger = logger ?? print;

  /// Convenience method to get configuration values
  T? getConfig<T>(String key, [T? defaultValue]) {
    return config[key] as T? ?? defaultValue;
  }

  /// Convenience method to log messages
  void log(String message) {
    logger(message);
  }
}

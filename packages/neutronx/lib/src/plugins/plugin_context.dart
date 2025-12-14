import 'package:neutronx/neutronx.dart';

/// Context provided to plugins during registration
///
/// This context gives plugins access to:
/// - The application's DI container
/// - The root router
/// - Configuration
/// - Logger
class PluginContext {
  /// The application's dependency injection container
  final NeutronContainer container;

  /// The root router of the application
  final Router router;

  /// Application configuration (can be a Map or custom config object)
  final Map<String, dynamic> config;

  /// Logger function for plugin output
  final void Function(String message) logger;

  PluginContext({
    required this.container,
    required this.router,
    required this.config,
    void Function(String)? logger,
  }) : logger = logger ?? print;

  /// Convenience method to get configuration values
  T? getConfig<T>(String key, [T? defaultValue]) {
    return config[key] as T? ?? defaultValue;
  }
  
  /// Check if a config entry exists
  bool hasConfig(String key) => config.containsKey(key);

  /// Require a config key; throw if missing
  T ensureConfig<T>(String key) {
    if (!config.containsKey(key)) {
      throw Exception("Missing required config key: $key");
    }
    return config[key] as T;
  }

  /// Convenience method to log messages with plugin context
  void log(String message) {
    logger(message);
  }
}

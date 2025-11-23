import 'package:neutronx/neutronx.dart';

/// Abstract base class for NeutronX plugins
///
/// Plugins are building blocks that add features to the framework without
/// modifying the core. They can:
/// - Register services in the DI container
/// - Add routes to the router
/// - Configure middleware
/// - Access application configuration
///
/// Example:
/// ```dart
/// class PostgresPlugin extends NeutronPlugin {
///   @override
///   String get name => 'postgres';
///
///   @override
///   Future<void> register(PluginContext ctx) async {
///     final dbUrl = ctx.getConfig<String>('database_url');
///     final client = await PostgresClient.connect(dbUrl);
///
///     ctx.container.registerSingleton<DbClient>(client);
///     ctx.log('PostgreSQL plugin registered');
///   }
/// }
/// ```
abstract class NeutronPlugin {
  /// The name of the plugin (used for logging and debugging)
  String get name;

  /// Called during application startup to register the plugin
  ///
  /// Plugins can use the [ctx] to:
  /// - Register services: `ctx.container.registerSingleton<T>(...)`
  /// - Add routes: `ctx.router.get('/path', handler)`
  /// - Access config: `ctx.getConfig<String>('key')`
  /// - Log messages: `ctx.log('message')`
  Future<void> register(PluginContext ctx);
}

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

///   late PostgresClient client;

///   @override
///   Future<void> onLoad(PluginContext ctx) async {
///     ctx.ensureConfig<String>('database_url');
///     ctx.log('Postgres config validated');
///   }

///   @override
///   Future<void> register(PluginContext ctx) async {
///     final url = ctx.getConfig<String>('database_url')!;
///     client = await PostgresClient.connect(url);

///     ctx.container.registerSingleton<PostgresClient>(client);
///     ctx.log('Postgres client registered');
///   }

///   @override
///   Future<void> onReady(PluginContext ctx) async {
///     ctx.log('Postgres plugin is ready (connection verified)');
///   }

///   @override
///   Future<void> onShutdown(PluginContext ctx) async {
///     await client.close();
///     ctx.log('Postgres connection closed');
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
  Future<void> onReady(PluginContext ctx);

  /// Called after all plugins have been registered
  ///
  /// Use this for:
  /// - Starting background jobs
  /// - Warming up caches
  /// - Connecting to delayed external services
  Future<void> onInit(PluginContext ctx) async {}

  /// Called when the application is shutting down
  ///
  /// Use this for:
  /// - Closing DB connections
  /// - Stopping background workers
  /// - Flushing logs
  Future<void> onDispose(PluginContext ctx) async {}
}

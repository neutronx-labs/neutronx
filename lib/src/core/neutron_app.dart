import 'dart:io';
import 'package:neutronx/neutronx.dart';
import '../modules/neutron_module.dart';
import '../modules/module_context.dart';

/// NeutronApp is the core runtime orchestrator for NeutronX applications
///
/// It is responsible for:
/// - Managing the root router
/// - Assembling the middleware pipeline
/// - Binding the HTTP server
/// - Converting dart:io HttpRequest → Request → Response → HttpResponse
///
/// Example:
/// ```dart
/// void main() async {
///   final app = NeutronApp();
///   final router = Router();
///
///   router.get('/', (req) async {
///     return Response.json({'message': 'Hello from NeutronX!'});
///   });
///
///   app.use(router);
///   app.useMiddleware([
///     loggingMiddleware(),
///     corsMiddleware(),
///   ]);
///
///   await app.listen(port: 3000);
///   print('Server running on http://localhost:3000');
/// }
/// ```
class NeutronApp {
  Router? _router;
  final List<Middleware> _middleware = [];
  HttpServer? _server;
  final NeutronContainer _container = NeutronContainer();
  final List<NeutronPlugin> _plugins = [];
  final List<NeutronModule> _modules = [];
  final Map<String, dynamic> _config = {};

  /// Returns the DI container for this application
  NeutronContainer get container => _container;

  /// Returns the application configuration
  Map<String, dynamic> get config => _config;

  /// Sets the root router for the application
  void use(Router router) {
    _router = router;
  }

  /// Adds middleware to the application pipeline
  ///
  /// Middleware are executed in the order they are added, with the first
  /// middleware being the outermost layer of the onion model.
  void useMiddleware(List<Middleware> middleware) {
    _middleware.addAll(middleware);
  }

  /// Sets application configuration
  void setConfig(Map<String, dynamic> config) {
    _config.addAll(config);
  }

  /// Registers a plugin with the application
  ///
  /// Plugins are registered during the [listen] phase, before the server starts.
  void registerPlugin(NeutronPlugin plugin) {
    _plugins.add(plugin);
  }

  /// Registers multiple plugins at once
  void registerPlugins(List<NeutronPlugin> plugins) {
    _plugins.addAll(plugins);
  }

  /// Registers a module with the application
  ///
  /// Modules encapsulate features with their dependencies and routes.
  /// They are registered during the [listen] phase, before the server starts.
  ///
  /// Example:
  /// ```dart
  /// app.registerModule(UsersModule());
  /// ```
  void registerModule(NeutronModule module) {
    _modules.add(module);
  }

  /// Registers multiple modules at once
  ///
  /// Example:
  /// ```dart
  /// app.registerModules([
  ///   UsersModule(),
  ///   ProductsModule(),
  ///   OrdersModule(),
  /// ]);
  /// ```
  void registerModules(List<NeutronModule> modules) {
    _modules.addAll(modules);
  }

  /// Builds the final handler by wrapping the router with all middleware
  Handler _buildHandler() {
    if (_router == null) {
      throw StateError('No router configured. Call use(router) first.');
    }

    // Start with the router's handler
    Handler finalHandler = _router!.handler;

    // Wrap with middleware in reverse order (onion model)
    // The first middleware in the list becomes the outermost layer
    for (var i = _middleware.length - 1; i >= 0; i--) {
      finalHandler = _middleware[i](finalHandler);
    }

    return finalHandler;
  }

  /// Starts the HTTP server and listens for incoming requests
  ///
  /// [host] - The host address to bind to (default: 'localhost')
  /// [port] - The port to listen on (default: 8080)
  /// [shared] - Whether to share the port across isolates (default: false)
  ///
  /// Returns the bound [HttpServer] instance.
  Future<HttpServer> listen({
    String host = 'localhost',
    int port = 8080,
    bool shared = false,
  }) async {
    // Register modules before plugins
    await _registerModules();

    // Register plugins before starting the server
    await _registerPlugins();

    // Build the final handler
    final handler = _buildHandler();

    // Bind the HTTP server
    _server = await HttpServer.bind(host, port, shared: shared);

    // Handle incoming requests
    _server!.listen((HttpRequest httpRequest) async {
      try {
        // Convert HttpRequest to our Request abstraction
        final request = await Request.fromHttpRequest(httpRequest);

        // Process through the handler pipeline
        final response = await handler(request);

        // Write response back to the HttpResponse
        await response.writeTo(httpRequest.response);
      } catch (e, stackTrace) {
        // Catch any unhandled errors and return 500
        try {
          final errorResponse = Response.internalServerError(
            'Unhandled error: $e',
          );
          await errorResponse.writeTo(httpRequest.response);
        } catch (_) {
          // If we can't even write the error response, close the connection
          httpRequest.response.statusCode = 500;
          await httpRequest.response.close();
        }

        // Log the error
        print('ERROR: $e');
        print('Stack trace: $stackTrace');
      }
    });

    return _server!;
  }

  /// Registers all modules with the application
  Future<void> _registerModules() async {
    if (_modules.isEmpty) {
      return;
    }

    if (_router == null) {
      throw StateError('No router configured. Call use(router) first.');
    }

    // Process module imports first (topological sort)
    final processedModules = <String>{};
    final modulesToProcess = [..._modules];

    Future<void> processModule(NeutronModule module) async {
      // Skip if already processed
      if (processedModules.contains(module.name)) {
        return;
      }

      // Process imports first
      for (final importedModule in module.imports) {
        await processModule(importedModule);
      }

      // Create a router for this module
      final moduleRouter = Router();
      final moduleContext = ModuleContext(
        container: _container,
        router: moduleRouter,
        config: _config,
      );

      try {
        // Lifecycle: onInit
        await module.onInit();

        // Register the module
        await module.register(moduleContext);

        // Mount the module's router
        _router!.mount('/${module.name}', moduleRouter);

        // Lifecycle: onReady
        await module.onReady();

        processedModules.add(module.name);
        print('Module registered: ${module.name}');
      } catch (e, stackTrace) {
        print('Failed to register module ${module.name}: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }

    // Process all modules
    for (final module in modulesToProcess) {
      await processModule(module);
    }
  }

  /// Registers all plugins with the application
  Future<void> _registerPlugins() async {
    if (_plugins.isEmpty) {
      return;
    }

    if (_router == null) {
      throw StateError('No router configured. Call use(router) first.');
    }

    final pluginContext = PluginContext(
      container: _container,
      router: _router!,
      config: _config,
    );

    for (final plugin in _plugins) {
      try {
        await plugin.register(pluginContext);
        print('Plugin registered: ${plugin.name}');
      } catch (e, stackTrace) {
        print('Failed to register plugin ${plugin.name}: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  /// Closes the HTTP server
  Future<void> close({bool force = false}) async {
    await _server?.close(force: force);
    _server = null;
  }

  /// Returns the bound address and port (if the server is running)
  InternetAddress? get address => _server?.address;
  int? get port => _server?.port;

  @override
  String toString() {
    if (_server != null) {
      return 'NeutronApp(running on ${address?.address}:$port)';
    }
    return 'NeutronApp(not started)';
  }
}

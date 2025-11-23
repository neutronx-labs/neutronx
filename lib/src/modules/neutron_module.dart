import 'module_context.dart';

/// Abstract base class for NeutronX modules
///
/// Modules encapsulate a feature's dependencies (repositories, services)
/// and routes in a self-contained unit. This follows the NestJS-style
/// modular architecture pattern.
///
/// Example:
/// ```dart
/// class UsersModule extends NeutronModule {
///   @override
///   String get name => 'users';
///
///   @override
///   Future<void> register(ModuleContext ctx) async {
///     // Register dependencies
///     ctx.container.registerLazySingleton<UsersRepository>(
///       (c) => UsersRepository(),
///     );
///     ctx.container.registerLazySingleton<UsersService>(
///       (c) => UsersService(c.get<UsersRepository>()),
///     );
///
///     // Register routes
///     final service = ctx.container.get<UsersService>();
///     ctx.router.get('/users', (req) async {
///       return Response.json(service.getAllUsers());
///     });
///   }
///
///   @override
///   List<Type> get exports => [UsersService]; // Share with other modules
/// }
/// ```
abstract class NeutronModule {
  /// The name of the module (used for routing and logging)
  ///
  /// This will be used as the route prefix when mounted.
  /// For example, a module named "users" will be mounted at "/users"
  String get name;

  /// Called during application startup to register the module
  ///
  /// Modules should:
  /// 1. Register their dependencies in ctx.container
  /// 2. Register their routes in ctx.router
  /// 3. Perform any initialization logic
  Future<void> register(ModuleContext ctx);

  /// Types that this module exports for use by other modules
  ///
  /// By default, modules don't export any services. Override this to
  /// make services available to other modules.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Type> get exports => [UsersService, UsersRepository];
  /// ```
  List<Type> get exports => [];

  /// Other modules that this module depends on
  ///
  /// These modules will be registered before this module.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<NeutronModule> get imports => [AuthModule(), DatabaseModule()];
  /// ```
  List<NeutronModule> get imports => [];

  /// Optional lifecycle hook called before the module is registered
  Future<void> onInit() async {}

  /// Optional lifecycle hook called after the module is registered
  Future<void> onReady() async {}

  /// Optional lifecycle hook called when the application is shutting down
  Future<void> onDestroy() async {}

  @override
  String toString() => 'NeutronModule($name)';
}

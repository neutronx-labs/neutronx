import 'package:neutronx/neutronx.dart';
import '../repositories/users_repository.dart';
import '../services/users_service.dart';

/// Users module - Encapsulates all user-related functionality
///
/// This module demonstrates the NestJS-style modular architecture where
/// a module owns its dependencies (repository, service) and routes.
class UsersModule extends NeutronModule {
  @override
  String get name => 'users';

  @override
  Future<void> register(ModuleContext ctx) async {
    ctx.log('Registering Users module dependencies...');

    // Register dependencies
    _registerDependencies(ctx.container);

    // Register routes
    await _registerRoutes(ctx.router, ctx.container);
  }

  /// Register all dependencies for this module
  void _registerDependencies(NeutronContainer container) {
    // Register repository
    container.registerLazySingleton<UsersRepository>(
      (c) => UsersRepository(),
    );

    // Register service (depends on repository)
    container.registerLazySingleton<UsersService>(
      (c) => UsersService(c.get<UsersRepository>()),
    );
  }

  /// Register all routes for this module
  Future<void> _registerRoutes(Router router, NeutronContainer container) async {
    // Resolve service once (not per request - performance optimization)
    final usersService = container.get<UsersService>();

    // GET /users - List all users
    router.get('/', (req) async {
      final users = usersService.getAllUsers();
      return Response.json(users.map((u) => u.toJson()).toList());
    });

    // GET /users/:id - Get a specific user
    router.get('/:id', (req) async {
      final id = req.params['id']!;
      final user = usersService.getUserById(id);

      if (user == null) {
        return Response.notFound('User not found');
      }

      return Response.json(user.toJson());
    });

    // POST /users - Create a new user
    router.post('/', (req) async {
      try {
        final body = await req.json() as Map<String, dynamic>;
        final name = body['name'] as String?;
        final email = body['email'] as String?;

        if (name == null || email == null) {
          return Response.badRequest('Name and email are required');
        }

        final user = usersService.createUser(name, email);
        return Response.json(user.toJson(), statusCode: 201);
      } on ArgumentError catch (e) {
        return Response.badRequest(e.message);
      }
    });

    // PUT /users/:id - Update a user
    router.put('/:id', (req) async {
      final id = req.params['id']!;
      final body = await req.json() as Map<String, dynamic>;

      final user = usersService.updateUser(
        id,
        name: body['name'] as String?,
        email: body['email'] as String?,
      );

      if (user == null) {
        return Response.notFound('User not found');
      }

      return Response.json(user.toJson());
    });

    // DELETE /users/:id - Delete a user
    router.delete('/:id', (req) async {
      final id = req.params['id']!;
      final deleted = usersService.deleteUser(id);

      if (!deleted) {
        return Response.notFound('User not found');
      }

      return Response.empty();
    });
  }

  /// Export services that other modules can use
  @override
  List<Type> get exports => [UsersService];

  @override
  Future<void> onInit() async {
    print('UsersModule: Initializing...');
  }

  @override
  Future<void> onReady() async {
    print('UsersModule: Ready to serve requests');
  }
}

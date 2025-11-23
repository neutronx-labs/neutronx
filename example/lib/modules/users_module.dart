import 'package:neutronx/neutronx.dart';
import '../services/users_service.dart';

/// Users module - creates a router with all user-related routes
///
/// This demonstrates the modular architecture where each feature
/// has its own router that can be mounted into the main app.
class UsersModule {
  final UsersService _usersService;

  UsersModule(this._usersService);

  Router createRouter() {
    final router = Router();

    // GET /users - List all users
    router.get('/users', (req) async {
      final users = _usersService.getAllUsers();
      return Response.json(users.map((u) => u.toJson()).toList());
    });

    // GET /users/:id - Get a specific user
    router.get('/users/:id', (req) async {
      final id = req.params['id']!;
      final user = _usersService.getUserById(id);

      if (user == null) {
        return Response.notFound('User not found');
      }

      return Response.json(user.toJson());
    });

    // POST /users - Create a new user
    router.post('/users', (req) async {
      try {
        final body = await req.json() as Map<String, dynamic>;
        final name = body['name'] as String?;
        final email = body['email'] as String?;

        if (name == null || email == null) {
          return Response.badRequest('Name and email are required');
        }

        final user = _usersService.createUser(name, email);
        return Response.json(user.toJson(), statusCode: 201);
      } on ArgumentError catch (e) {
        return Response.badRequest(e.message);
      }
    });

    // PUT /users/:id - Update a user
    router.put('/users/:id', (req) async {
      final id = req.params['id']!;
      final body = await req.json() as Map<String, dynamic>;

      final user = _usersService.updateUser(
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
    router.delete('/users/:id', (req) async {
      final id = req.params['id']!;
      final deleted = _usersService.deleteUser(id);

      if (!deleted) {
        return Response.notFound('User not found');
      }

      return Response.empty();
    });

    return router;
  }
}

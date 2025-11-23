import 'package:neutronx/neutronx.dart';
import 'lib/modules/users_module_v2.dart';

/// Example application using the NEW module-based architecture
///
/// This demonstrates the NestJS-style approach where modules are
/// self-contained units that encapsulate:
/// - Dependencies (repositories, services)
/// - Routes
/// - Lifecycle hooks
///
/// Compare this to main.dart which uses the service-based approach.
void main() async {
  // Create the NeutronX application
  final app = NeutronApp();

  // Create the main router (for non-module routes)
  final router = Router();

  // Root route
  router.get('/', (req) async {
    return Response.json({
      'message': 'Welcome to NeutronX Modular Example API',
      'version': '0.1.0',
      'architecture': 'Module-based (NestJS-style)',
      'endpoints': {
        'users': '/users',
        'health': '/health',
      },
    });
  });

  // Health check endpoint
  router.get('/health', (req) async {
    return Response.json({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Set the main router
  app.use(router);

  // Register modules - Each module is self-contained!
  print('Registering modules...');
  app.registerModules([
    UsersModule(), // Handles /users/* routes with its own DI
    // ProductsModule(),  // Would handle /products/* routes
    // OrdersModule(),    // Would handle /orders/* routes
  ]);

  // Configure global middleware stack
  print('Configuring middleware...');
  app.useMiddleware([
    loggingMiddleware(),
    corsMiddleware(
      origin: '*',
      methods: 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      headers: 'Content-Type, Authorization',
    ),
    errorHandlerMiddleware(showStackTrace: true),
  ]);

  // Start the server
  print('Starting server...');
  final server = await app.listen(port: 3000);

  print('');
  print('🚀 NeutronX Modular Example Server is running!');
  print('');
  print('   Address: http://${server.address.address}:${server.port}');
  print('');
  print('📦 Registered Modules:');
  print('   ✅ UsersModule → /users/*');
  print('');
  print('📋 Available endpoints:');
  print('   GET    /                    - Welcome message');
  print('   GET    /health              - Health check');
  print('   GET    /users/              - List all users');
  print('   GET    /users/:id           - Get user by ID');
  print('   POST   /users/              - Create new user');
  print('   PUT    /users/:id           - Update user');
  print('   DELETE /users/:id           - Delete user');
  print('');
  print('🧪 Try it out:');
  print('   curl http://localhost:3000/');
  print('   curl http://localhost:3000/users/');
  print('   curl http://localhost:3000/users/1');
  print('');
  print('💡 Notice: Clean main.dart with just module registrations!');
  print('');
}

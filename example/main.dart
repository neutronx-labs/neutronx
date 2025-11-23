import 'package:neutronx/neutronx.dart';
import 'lib/repositories/users_repository.dart';
import 'lib/services/users_service.dart';
import 'lib/modules/users_module.dart';

void main() async {
  // Create the NeutronX application
  final app = NeutronApp();

  // Setup Dependency Injection
  print('Setting up dependency injection...');
  app.container.registerLazySingleton<UsersRepository>(
    (c) => UsersRepository(),
  );
  app.container.registerLazySingleton<UsersService>(
    (c) => UsersService(c.get<UsersRepository>()),
  );

  // Create the main router
  final router = Router();

  // Root route
  router.get('/', (req) async {
    return Response.json({
      'message': 'Welcome to NeutronX Example API',
      'version': '0.1.0',
      'endpoints': {
        'users': '/api/users',
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

  // Create and mount the users module
  print('Mounting users module...');
  final usersService = app.container.get<UsersService>();
  final usersModule = UsersModule(usersService);
  final apiRouter = Router();
  apiRouter.mount('', usersModule.createRouter());
  router.mount('/api', apiRouter);

  // Configure middleware stack
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

  // Set the router
  app.use(router);

  // Start the server
  print('Starting server...');
  final server = await app.listen(port: 3000);

  print('');
  print('🚀 NeutronX Example Server is running!');
  print('');
  print('   Address: http://${server.address.address}:${server.port}');
  print('');
  print('📋 Available endpoints:');
  print('   GET    /                    - Welcome message');
  print('   GET    /health              - Health check');
  print('   GET    /api/users           - List all users');
  print('   GET    /api/users/:id       - Get user by ID');
  print('   POST   /api/users           - Create new user');
  print('   PUT    /api/users/:id       - Update user');
  print('   DELETE /api/users/:id       - Delete user');
  print('');
  print('🧪 Try it out:');
  print('   curl http://localhost:3000/');
  print('   curl http://localhost:3000/api/users');
  print('   curl http://localhost:3000/api/users/1');
  print('');
}

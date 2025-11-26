import 'dart:io';
import 'package:neutronx/neutronx.dart';
import 'package:tmp_project/tmp_project.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();

  // Welcome route
  router.get('/', (req) async {
    return Response.json({
      'message': 'Welcome to TmpProject!',
      'version': '0.1.0',
      'docs': '/api/docs',
    });
  });

  // Health check
  router.get('/health', (req) async {
    return Response.json({
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // Simple websocket echo
  router.ws('/ws/echo', (session) async {
    session.socket.listen(
      (data) => session.socket.add('echo: $data'),
      onError: (error, stack) => session.closeWithError(error, stack),
      onDone: () => session.close(),
    );
  });

  // Bare controllers registry (optional)
  registerControllers(router);

  // Use router
  app.use(router);

  // Add middleware
  app.useMiddleware([
    requestIdMiddleware(),
    loggingMiddleware(),
    corsMiddleware(),
    securityHeadersMiddleware(),
    metricsMiddleware(onEvent: (event) {
      stdout.writeln(
        '[metrics] ${event.method} ${event.path} '
        '-> ${event.statusCode} (${event.duration.inMilliseconds}ms)',
      );
    }),
    errorHandlerMiddleware(),
  ]);

  // Feature modules
  app.registerModules(buildModules());

  // Start server
  final server = await app.listen(port: 3000);
  print('🚀 Server running on http://localhost:${server.port}');
}

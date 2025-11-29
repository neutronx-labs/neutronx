/// NeutronX - A Flutter-first Dart backend framework
///
/// This is the main entry point for the NeutronX framework.
/// It exports all public APIs needed to build backend applications.
library neutronx;

// Core HTTP Runtime
export 'src/core/request.dart';
export 'src/core/response.dart';

// Middleware System
export 'src/middleware/middleware.dart';
export 'src/middleware/handler.dart';
export 'src/middleware/examples.dart';

// Router
export 'src/router/router.dart';

// Dependency Injection
export 'src/di/neutron_container.dart';
export 'src/di/circular_dependency_error.dart';

// Plugin System
export 'src/plugins/neutron_plugin.dart';
export 'src/plugins/plugin_context.dart';

// Module System
export 'src/modules/neutron_module.dart';
export 'src/modules/module_context.dart';

// Runtime Orchestrator
export 'src/core/neutron_app.dart';

// WebSocket support
export 'src/websocket/websocket.dart';

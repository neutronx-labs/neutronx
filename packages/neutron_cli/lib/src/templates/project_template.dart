import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

/// Templates for new project generation
class ProjectTemplate {
  final String projectName;

  ProjectTemplate(this.projectName);

  String get _neutronxDependency {
    final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
    if (neutronxRoot != null && neutronxRoot.isNotEmpty) {
      final sdkPath = p.normalize(p.join(neutronxRoot, 'packages', 'neutronx'));
      return '''neutronx:
    path: $sdkPath''';
    }

    return '''neutronx: ^0.1.0  # Update this when published
  # For now, use:
  # neutronx:
  #   path: /path/to/neutronx/packages/neutronx''';
  }

  String get pubspecYaml {
    return '''
name: $projectName
description: A NeutronX backend application
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  $_neutronxDependency

dev_dependencies:
  lints: ^6.0.0
  test: ^1.28.0
''';
  }

  String get analysisOptions => '''
include: package:lints/recommended.yaml

analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore
''';

  String get gitignore => '''
# Dart
.dart_tool/
.packages
pubspec.lock
build/
*.log

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
''';

  String get readme => '''
# $projectName

A NeutronX backend application.

## Getting Started

### Installation

```bash
dart pub get
```

### Running in Development

```bash
neutron dev
# add compile-time defines or disable watching:
# neutron dev -DAPI_URL=https://api.dev --watch=false
# or
dart run bin/server.dart
```

### Building for Production

```bash
neutron build
# pass defines/arch:
# neutron build -DAPI_URL=https://api.prod --target-arch=arm64
# or
dart compile exe bin/server.dart -o build/server
```

### Running Tests

```bash
dart test
```

## Project Structure

```
$projectName/
├── bin/
│   └── server.dart       # Application entry point
├── lib/
│   ├── ${projectName}.dart
│   └── src/
│       ├── modules/      # Feature modules (self-contained)
│       │   ├── modules.dart        # Module registry (auto-adds generated modules)
│       │   └── home/               # Example module
│       │       ├── controllers/
│       │       ├── home_module.dart
│       │       ├── services/
│       │       └── repositories/
│       ├── controllers/  # Bare controllers (optional)
│       │   └── controllers.dart    # Manual controller registry
│       └── middleware/   # Custom middleware
└── test/                 # Tests
```

## Documentation

- [NeutronX Documentation](https://github.com/neutronx-labs/neutronx.git)
''';

  String mainLibrary({String? packageName}) {
    final pkg = packageName ?? projectName;
    final rc = ReCase(pkg);
    return '''
/// ${rc.pascalCase} backend application
library $pkg;

export 'src/modules/modules.dart';
export 'src/controllers/controllers.dart';
''';
  }

  String get controllersIndex => '''
import 'package:neutronx/neutronx.dart';

// [CONTROLLER_IMPORTS]

void registerControllers(Router router) {
  // Bare controllers are mounted under their controller name, e.g. /xyz
  // [CONTROLLER_REGISTRATIONS]
}
''';

  String get modulesIndex => '''
import 'package:neutronx/neutronx.dart';

import 'home/home_module.dart';
// [MODULE_IMPORTS]

export 'home/home_module.dart';
// [MODULE_EXPORTS]

List<NeutronModule> buildModules() => [
  HomeModule(),
  // [MODULE_REGISTRATIONS]
];
''';

  String get homeModule => '''
import 'package:neutronx/neutronx.dart';
import 'controllers/home_controller.dart';
import 'services/home_service.dart';
import 'repositories/home_repository.dart';
// [CONTROLLER_IMPORTS]

class HomeModule extends NeutronModule {
  @override
  String get name => 'home';

  @override
  Future<void> register(ModuleContext ctx) async {
    // Register dependencies
    ctx.container.registerLazySingleton<HomeRepository>(
      (c) => HomeRepository(),
    );

    ctx.container.registerLazySingleton<HomeService>(
      (c) => HomeService(c.get<HomeRepository>()),
    );

    // Wire routes via controller
    final service = ctx.container.get<HomeService>();
    HomeController(service).register(ctx.router);
    // [CONTROLLER_REGISTRATIONS]
  }
}
''';

  String get homeController => '''
import 'package:neutronx/neutronx.dart';
import '../services/home_service.dart';

class HomeController {
  final HomeService _service;

  HomeController(this._service);

  void register(Router router) {
    router.get('/', _welcome);
  }

  Future<Response> _welcome(Request req) async {
    final data = await _service.welcome();
    return Response.json(data);
  }
}
''';

  String get homeService => '''
import '../repositories/home_repository.dart';

class HomeService {
  final HomeRepository _repository;

  HomeService(this._repository);

  Future<Map<String, dynamic>> welcome() async {
    return _repository.welcome();
  }
}
''';

  String get homeRepository => '''
class HomeRepository {
  Future<Map<String, dynamic>> welcome() async {
    return {
      'module': 'home',
      'message': 'Hello from HomeModule',
    };
  }
}
''';

  String get healthTest => '''
import 'dart:convert';
import 'package:neutronx/neutronx.dart';
import 'package:test/test.dart';

void main() {
  test('health endpoint responds with ok', () async {
    final router = Router();
    router.get('/health', (req) async {
      return Response.json({'status': 'ok'});
    });

    final response = await router.handler(Request.test(
      method: 'GET',
      uri: Uri.parse('http://localhost/health'),
      path: '/health',
    ));

    expect(response.statusCode, equals(200));
    final body = jsonDecode(utf8.decode(response.body));
    expect(body['status'], equals('ok'));
  });
}
''';

  String serverMain({String? packageName, String? displayName}) {
    final pkg = packageName ?? projectName;
    final name = displayName ?? ReCase(projectName).pascalCase;
    return '''
import 'dart:io';
import 'package:neutronx/neutronx.dart';
import 'package:$pkg/$pkg.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();
  final host = Platform.environment['HOST'] ?? 'localhost';
  final port =
      int.tryParse(Platform.environment['PORT'] ?? '3000') ?? 3000;

  // Welcome route
  router.get('/', (req) async {
    return Response.json({
      'message': 'Welcome to ${projectName.pascalCase}!',
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
        '[metrics] \${event.method} \${event.path} '
        '-> \${event.statusCode} (\${event.duration.inMilliseconds}ms)',
      );
    }),
    errorHandlerMiddleware(),
  ]);

  // Feature modules
  app.registerModules(buildModules());

  // Start server
  final server = await app.listen(host: host, port: port);
  print('🚀 Server running on http://\${host}:\${server.port}');
}
''';
  }

  String get monorepoReadme => '''
# $projectName

A NeutronX monorepo with backend and mobile applications sharing common DTOs.

## Structure

```
$projectName/
├── apps/
│   ├── backend/      # NeutronX backend
│   └── mobile/       # Flutter mobile app
└── packages/
    └── models/       # Shared DTOs
```

## Getting Started

### Backend

```bash
cd apps/backend
dart pub get
neutron dev
# e.g. neutron dev -DAPI_URL=https://api.dev
```

### Mobile

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Shared Models

The \`packages/models\` directory contains DTOs shared between backend and mobile:

```dart
import 'package:models/models.dart';

// Use in both backend and Flutter
final user = UserDto(id: '1', name: 'John', email: 'john@example.com');
```
''';

  String get backendPubspec {
    return '''
name: backend
description: ${projectName.pascalCase} backend application
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  $_neutronxDependency
  models:
    path: ../../packages/models

dev_dependencies:
  lints: ^6.0.0
  test: ^1.28.0
''';
  }

  String get mobilePubspec => '''
name: mobile
description: ${projectName.pascalCase} mobile application
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  models:
    path: ../../packages/models

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
''';

  String get mobileMain => '''
import 'package:flutter/material.dart';
import 'package:models/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${projectName.pascalCase}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${projectName.pascalCase}'),
      ),
      body: const Center(
        child: Text('Hello from Flutter!'),
      ),
    );
  }
}
''';

  String get modelsPubspec => '''
name: models
description: Shared DTOs for ${projectName.pascalCase}
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies: {}

dev_dependencies:
  lints: ^6.0.0
  test: ^1.28.0
''';

  String get modelsLibrary => '''
/// Shared data transfer objects
library models;

export 'src/user_dto.dart';
''';

  String get userDto => '''
class UserDto {
  final String id;
  final String name;
  final String email;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
''';
}

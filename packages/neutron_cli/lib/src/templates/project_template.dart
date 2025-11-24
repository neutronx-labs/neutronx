import 'dart:io' show Platform;
import 'package:recase/recase.dart';

/// Templates for new project generation
class ProjectTemplate {
  final String projectName;

  ProjectTemplate(this.projectName);

  String get pubspecYaml {
    final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
    final neutronxDep = neutronxRoot != null && neutronxRoot.isNotEmpty
        ? '''neutronx:
    path: $neutronxRoot'''
        : '''neutronx: ^0.1.0  # Update this when published
  # For now, use:
  # neutronx:
  #   path: /path/to/neutronx''';

    return '''
name: $projectName
description: A NeutronX backend application
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  $neutronxDep

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
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
# or
dart run bin/server.dart
```

### Building for Production

```bash
neutron build
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
│       ├── modules/      # Feature modules
│       ├── middleware/   # Custom middleware
│       ├── repositories/ # Data access layer
│       └── services/     # Business logic
└── test/                 # Tests
```

## Documentation

- [NeutronX Documentation](https://github.com/neutronx/neutronx)
''';

  String get mainLibrary => '''
/// ${projectName.pascalCase} backend application
library $projectName;

export 'src/modules/home_module.dart';
''';

  String get serverMain => '''
import 'package:neutronx/neutronx.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();

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

  // Use router
  app.use(router);

  // Add middleware
  app.useMiddleware([
    loggingMiddleware(),
    corsMiddleware(),
    errorHandlerMiddleware(),
  ]);

  // Start server
  final server = await app.listen(port: 3000);
  print('🚀 Server running on http://localhost:\${server.port}');
}
''';

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
    final neutronxRoot = Platform.environment['NEUTRONX_ROOT'];
    final neutronxDep = neutronxRoot != null && neutronxRoot.isNotEmpty
        ? '''neutronx:
    path: $neutronxRoot'''
        : '''neutronx: ^0.1.0  # Update when published
  # For now, use:
  # neutronx:
  #   path: /path/to/neutronx''';

    return '''
name: backend
description: ${projectName.pascalCase} backend application
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  $neutronxDep
  models:
    path: ../../packages/models

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
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
  lints: ^3.0.0
  test: ^1.24.0
''';

  String get modelsLibrary => '''
/// Shared data transfer objects
library models;

export 'src/user_dto.dart';
''';
}

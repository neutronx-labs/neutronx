# NeutronX CLI

Command-line tool for the NeutronX framework.

## Installation

### Global Installation

```bash
dart pub global activate --source path packages/neutron_cli
```

### Local Usage

```bash
cd packages/neutron_cli
dart pub get
dart run bin/neutron.dart <command>
```

## Commands

### `neutron new`

Create a new NeutronX project.

```bash
# Create a standard project
neutron new my_backend

# Create a monorepo structure
neutron new my_project --monorepo
```

**Options:**
- `-m, --monorepo`: Create a monorepo structure with apps/ and packages/

### `neutron generate`

Generate code (modules, DTOs, services, repositories).

```bash
# Generate a module (creates module, service, and repository)
neutron generate module users

# Generate a DTO
neutron generate dto product

# Generate a service
neutron generate service auth

# Generate a repository
neutron generate repository orders
```

**Available types:**
- `module` (or `m`): Generate a complete module with service and repository
- `dto` (or `d`): Generate a Data Transfer Object
- `service` (or `s`): Generate a service class
- `repository` (or `r`): Generate a repository class

### `neutron dev`

Start development server with hot reload.

```bash
# Start on default port (3000)
neutron dev

# Start on custom port
neutron dev --port 8080

# Specify custom entry point
neutron dev --entry bin/server.dart
```

**Options:**
- `-p, --port`: Port to run the server on (default: 3000)
- `--host`: Host to bind the server to (default: localhost)
- `-e, --entry`: Entry point file (default: bin/server.dart)

### `neutron build`

Build project for production.

```bash
# Build with default settings
neutron build

# Build with custom output path
neutron build --output build/my_server

# Build with custom entry point
neutron build --entry bin/server.dart
```

**Options:**
- `-o, --output`: Output executable path (default: build/server)
- `-e, --entry`: Entry point file (default: bin/server.dart)

## Examples

### Create and Run a New Project

```bash
# Create project
neutron new my_backend
cd my_backend

# Install dependencies
dart pub get

# Start development server
neutron dev
```

### Generate a Complete Module

```bash
# Generate users module
neutron generate module users

# This creates:
# - lib/src/modules/users/users_module.dart
# - lib/src/modules/users/controllers/users_controller.dart
# - lib/src/modules/users/services/users_service.dart
# - lib/src/modules/users/repositories/users_repository.dart
# - lib/src/modules/modules.dart (updated to include UsersModule)
```

### Build for Production

```bash
# Build
neutron build

# Run the executable
./build/server
```

## Monorepo Structure

When creating a monorepo with `--monorepo`:

```
my_project/
├── apps/
│   ├── backend/          # NeutronX backend
│   │   ├── bin/
│   │   ├── lib/
│   │   └── pubspec.yaml
│   └── mobile/           # Flutter mobile app
│       ├── lib/
│       └── pubspec.yaml
└── packages/
    └── models/           # Shared DTOs
        ├── lib/
        └── pubspec.yaml
```

This structure allows sharing DTOs between backend and mobile:

```dart
// In packages/models/lib/src/user_dto.dart
class UserDto {
  final String id;
  final String name;
  // ...
}

// Use in backend (apps/backend)
import 'package:models/models.dart';

// Use in mobile (apps/mobile)
import 'package:models/models.dart';
```

## Global Options

- `-h, --help`: Print usage information
- `-v, --version`: Print CLI version

## Tips

1. **Project Naming**: Use snake_case for project names (e.g., `my_backend`, `user_service`)
2. **Module Organization**: Group related modules together in subdirectories
3. **Development**: Use `neutron dev` during development for faster iteration
4. **Production**: Always use `neutron build` for production deployments

## See Also

- [NeutronX Documentation](../../README.md)
- [Module System Guide](../../docs/MODULE_SYSTEM_IMPLEMENTATION.md)
- [Architecture Guide](../../docs/neutron_x_technical_architecture.md)

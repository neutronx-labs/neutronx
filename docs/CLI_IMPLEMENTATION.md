# NeutronX CLI Implementation

## Overview

Complete command-line tool implementation for the NeutronX framework with project scaffolding, code generation, development server, and production build capabilities.

## 📦 Package Structure

```
packages/neutron_cli/
├── bin/
│   └── neutron.dart              # CLI entry point
├── lib/
│   ├── neutron_cli.dart          # Public API
│   └── src/
│       ├── cli_exception.dart    # Error handling
│       ├── neutron_cli.dart      # Main CLI orchestrator
│       ├── commands/             # Command implementations
│       │   ├── command.dart      # Base command class
│       │   ├── new_command.dart  # Project creation
│       │   ├── generate_command.dart  # Code generation
│       │   ├── dev_command.dart  # Development server
│       │   └── build_command.dart     # Production builds
│       ├── generators/           # Code generators
│       │   ├── module_generator.dart  # Module scaffolding
│       │   ├── dto_generator.dart     # DTO generation
│       │   ├── service_generator.dart # Service generation
│       │   └── repository_generator.dart  # Repository generation
│       └── templates/
│           └── project_template.dart  # Project templates
├── pubspec.yaml
└── README.md
```

## 🎯 Implemented Commands

### 1. `neutron new <project-name>`

Creates a new NeutronX project with complete folder structure.

**Features:**
- ✅ Standard project structure
- ✅ Monorepo support (`--monorepo` flag)
- ✅ Pre-configured pubspec.yaml
- ✅ Example server code
- ✅ Analysis options
- ✅ README with quickstart guide

**Usage:**
```bash
neutron new my_backend
neutron new my_project --monorepo
```

**Generated Structure (Standard):**
```
my_backend/
├── bin/
│   └── server.dart
├── lib/
│   ├── my_backend.dart
│   └── src/
│       ├── core/
│       ├── modules/
│       ├── middleware/
│       ├── repositories/
│       └── services/
├── test/
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

**Generated Structure (Monorepo):**
```
my_project/
├── apps/
│   ├── backend/      # NeutronX backend
│   └── mobile/       # Flutter mobile app
├── packages/
│   └── models/       # Shared DTOs
└── README.md
```

### 2. `neutron generate <type> <name>`

Generates code with proper structure and boilerplate.

**Supported Types:**

#### Module (`module` or `m`)
Generates a complete module with service and repository:
- `lib/src/modules/{name}/{name}_module.dart`
- `lib/src/modules/{name}/controllers/{name}_controller.dart`
- `lib/src/modules/{name}/services/{name}_service.dart`
- `lib/src/modules/{name}/repositories/{name}_repository.dart`
- `lib/src/modules/modules.dart` (registry auto-updated)

```bash
neutron generate module users
```

**Generated Module Includes:**
- ✅ Full CRUD routes (GET, POST, PUT, DELETE)
- ✅ DI registration
- ✅ Lifecycle hooks (onInit, onReady)
- ✅ Service layer with business logic
- ✅ Repository layer with in-memory storage (template)

#### DTO (`dto` or `d`)
Generates a Data Transfer Object:
```bash
neutron generate dto product
```

**Generated DTO Includes:**
- ✅ Immutable fields
- ✅ `fromJson()` factory
- ✅ `toJson()` method
- ✅ `copyWith()` method
- ✅ `==` operator and `hashCode`
- ✅ `toString()` override

#### Service (`service` or `s`)
Generates a service class:
```bash
neutron generate service auth
```

**Generated Service Includes:**
- ✅ Repository dependency
- ✅ CRUD methods
- ✅ Validation logic template
- ✅ Business logic structure

#### Repository (`repository` or `r`)
Generates a repository class:
```bash
neutron generate repository orders
```

**Generated Repository Includes:**
- ✅ In-memory storage (template for database)
- ✅ CRUD operations
- ✅ Query methods
- ✅ TODO comments for database integration

### 3. `neutron dev`

Starts development server with hot reload support.

**Features:**
- ✅ VM service enabled for debugging
- ✅ Custom port configuration
- ✅ Custom host binding
- ✅ Custom entry point
- ✅ Output forwarding

**Usage:**
```bash
neutron dev
neutron dev --port 8080
neutron dev --entry bin/server.dart
```

**Options:**
- `-p, --port`: Port number (default: 3000)
- `--host`: Host address (default: localhost)
- `-e, --entry`: Entry file (default: bin/server.dart)

### 4. `neutron build`

Builds project for production as native executable.

**Features:**
- ✅ Compiles to native binary using `dart compile exe`
- ✅ Custom output path
- ✅ Custom entry point
- ✅ Build success/failure reporting

**Usage:**
```bash
neutron build
neutron build --output build/my_server
```

**Options:**
- `-o, --output`: Output path (default: build/server)
- `-e, --entry`: Entry file (default: bin/server.dart)

## 📋 Code Generation Templates

### Module Template

The module generator creates a complete, production-ready module:

```dart
class UsersModule extends NeutronModule {
  @override
  String get name => 'users';

  @override
  Future<void> register(ModuleContext context) async {
    // DI registration
    context.container.registerLazySingleton<UsersRepository>(
      (c) => UsersRepository(),
    );
    context.container.registerLazySingleton<UsersService>(
      (c) => UsersService(c.get<UsersRepository>()),
    );

    // Route registration
    final service = context.container.get<UsersService>();
    final router = context.router;

    router.get('/', (req) async { /* ... */ });
    router.get('/:id', (req) async { /* ... */ });
    router.post('/', (req) async { /* ... */ });
    router.put('/:id', (req) async { /* ... */ });
    router.delete('/:id', (req) async { /* ... */ });
  }
}
```

### DTO Template

DTOs include all necessary methods for serialization:

```dart
class ProductDto {
  final String id;
  final String name;
  final DateTime createdAt;

  ProductDto({required this.id, required this.name, required this.createdAt});

  factory ProductDto.fromJson(Map<String, dynamic> json) { /* ... */ }
  Map<String, dynamic> toJson() { /* ... */ }
  ProductDto copyWith({/* ... */}) { /* ... */ }
  
  @override
  bool operator ==(Object other) { /* ... */ }
  
  @override
  int get hashCode { /* ... */ }
}
```

## 🧪 Testing Results

All CLI commands have been tested and verified:

✅ **Project Creation:**
- Standard project structure generated correctly
- All required files created
- Valid pubspec.yaml configuration

✅ **Module Generation:**
- Module, service, and repository files created
- Proper imports and dependencies
- Complete CRUD implementation

✅ **DTO Generation:**
- Valid DTO class with all methods
- Proper JSON serialization
- Immutability enforced

✅ **Service Generation:**
- Service class with repository dependency
- CRUD methods implemented
- Validation template included

✅ **Repository Generation:**
- Repository class with in-memory storage
- All CRUD operations
- Query methods included

✅ **Help System:**
- Global help works (`--help`)
- Version flag works (`--version`)
- Command-specific help available

## 📚 Dependencies

```yaml
dependencies:
  args: ^2.4.0      # Command-line argument parsing
  path: ^1.8.3      # Path manipulation
  recase: ^4.1.0    # String case conversion (snake_case, PascalCase, etc.)
```

## 🎨 Code Quality Features

### Naming Conventions
- ✅ Validates project/module names (must be snake_case)
- ✅ Automatic case conversion (snake_case → PascalCase)
- ✅ Consistent file naming

### Error Handling
- ✅ Custom `CliException` with exit codes
- ✅ User-friendly error messages
- ✅ Input validation with helpful feedback

### Code Generation
- ✅ Consistent formatting
- ✅ Proper imports
- ✅ TODO comments for customization
- ✅ Best practices baked in

## 🚀 Usage Examples

### Complete Workflow

```bash
# 1. Create new project
neutron new my_api
cd my_api

# 2. Install dependencies
dart pub get

# 3. Generate a module
neutron generate module products

# 4. Generate DTOs
neutron generate dto product
neutron generate dto category

# 5. Start development server
neutron dev --port 3000

# 6. Build for production
neutron build

# 7. Run production build
./build/server
```

### Monorepo Workflow

```bash
# 1. Create monorepo
neutron new my_project --monorepo
cd my_project

# 2. Work on backend
cd apps/backend
dart pub get
neutron generate module users

# 3. Add shared models
cd ../../packages/models
# Add UserDto, ProductDto, etc.

# 4. Both apps can use shared models
# Backend: import 'package:models/models.dart';
# Mobile: import 'package:models/models.dart';
```

## 📈 Statistics

- **Total Commands:** 4 (new, generate, dev, build)
- **Generator Types:** 4 (module, dto, service, repository)
- **Template Files:** 11 project templates
- **Lines of Code:** ~1,200 lines
- **Zero Errors:** All code compiles without warnings

## ✨ Key Features

1. **Fast Scaffolding**: Create production-ready projects in seconds
2. **Smart Generation**: Generates proper boilerplate with best practices
3. **Developer Experience**: Clear error messages and helpful output
4. **Flexibility**: Monorepo and standard project support
5. **Production Ready**: Native compilation for optimal performance

## 🔄 Integration with Framework

The CLI is designed to work seamlessly with NeutronX:

- Generated modules follow NeutronX patterns
- DTOs are compatible with Request.json() and Response.json()
- Services integrate with DI container
- Repositories follow repository pattern
- All generated code is ready to use immediately

## 📝 Documentation

Complete documentation available in:
- `packages/neutron_cli/README.md` - CLI user guide
- Command help: `neutron <command> --help`
- Examples in this document

---

**Status:** ✅ Complete and fully functional
**Next Steps:** Package for `pub.dev` distribution

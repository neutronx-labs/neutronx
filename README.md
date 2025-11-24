# NeutronX

A **Flutter-first Dart backend framework** with shared DTO support and monorepo-native design.

## 🚀 Overview

NeutronX is designed to work seamlessly with Flutter applications, enabling:

- **Shared DTOs and models** between backend and Flutter
- **Shared validation rules**
- **Monorepo development** between `/apps/backend` and `/apps/mobile`
- **Compile-time sync** between backend responses and Flutter parsing

## 🎯 Core Features

- **Pure dart:io** - Maximum performance with full control
- **Shelf-style middleware** - Composable request/response pipeline
- **Nested routers** - Modular, feature-based routing
- **Type-safe DI** - Built-in dependency injection with circular dependency detection
- **Plugin system** - Extensible architecture for databases, auth, caching
- **Stateless services** - Prevent race conditions and hidden state
- **Monorepo-first** - Designed for shared code between backend and Flutter

## 📦 Packages

- `packages/neutronx` — core SDK/library
- `packages/neutron_cli` — CLI tooling and project generator (installs `neutron`)

## 🔧 Installation

### 1. Clone the repo

```bash
# Clone the repository
git clone https://github.com/neutronx-labs/neutronx.git
cd neutronx
```

### 2. Install CLI

```bash
./install_cli.sh
```

### 3. Set Environment Variable

Add to your `~/.zshrc` or `~/.bashrc` (point to the repo root):

```bash
export NEUTRONX_ROOT="/Users/yourname/neutronx"  # Repo root
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Then reload:
```bash
source ~/.zshrc
```

### 4. Verify Installation

```bash
neutron --version
echo $NEUTRONX_ROOT  # Should show your NeutronX path
```

> **Note**: When `NEUTRONX_ROOT` is set, the CLI resolves `sdk: neutronx` to `path: $NEUTRONX_ROOT/packages/neutronx` automatically. No manual path tweaks needed in `pubspec.yaml`.

## 🛠️ CLI Usage

### Create New Project

```bash
# Standard project
neutron new my_backend
cd my_backend

# Monorepo with backend + mobile app
neutron new my_project --monorepo
cd my_project
```

### Generate Code

```bash
# Generate a complete module (includes service, repository, and CRUD routes)
neutron generate module products

# Generate a DTO with JSON serialization
neutron generate dto user --fields="name:String,email:String,age:int"

# Generate a service
neutron generate service auth

# Generate a repository
neutron generate repository orders
```

### Development & Build

```bash
# Start development server with hot reload
neutron dev --port 3000

# Build for production
neutron build --output build/server

# Run production build
./build/server
```

## 🏃 Quick Start

```dart
import 'package:neutronx/neutronx.dart';

void main() async {
  final app = NeutronApp();
  final router = Router();

  router.get('/', (req) async {
    return Response.json({'message': 'Hello from NeutronX!'});
  });

  router.get('/users/:id', (req) async {
    final id = req.params['id'];
    return Response.json({'userId': id});
  });

  app.use(router);
  await app.listen(port: 3000);
  print('Server running on http://localhost:3000');
}
```

## 🏗️ Architecture

```
+---------------------------+
|  Controller Layer (*)     |  <-- Optional, future: annotations/codegen
+---------------------------+
|  Router Layer             |  <-- Router objects, nested routers
+---------------------------+
|  Middleware Pipeline      |  <-- Shelf-style Handler/Middleware
+---------------------------+
|  Core HTTP Runtime        |  <-- dart:io server, Request/Response APIs
+---------------------------+
```

## Project Structure

### Standard Project

```
my_backend/
├── bin/
│   └── server.dart       # Application entry point
├── lib/
│   ├── my_backend.dart
│   └── src/
│       ├── modules/      # Feature modules (self-contained)
│       │   ├── modules.dart        # Module registry (auto-populated)
│       │   └── home/               # Example module
│       │       ├── home_module.dart
│       │       ├── services/
│       │       └── repositories/
│       └── middleware/   # Custom middleware
└── test/                 # Tests
```

### Monorepo Project

```
my_project/
├── apps/
│   ├── backend/          # NeutronX backend
│   │   ├── bin/
│   │   │   └── server.dart
│   │   └── lib/
│   │       └── src/
│   │           └── modules/
│   │               ├── modules.dart
│   │               └── home/
│   │                   ├── home_module.dart
│   │                   ├── services/
│   │                   └── repositories/
│   └── mobile/           # Flutter mobile app
│       ├── lib/
│       └── pubspec.yaml
└── packages/
    └── models/           # Shared DTOs between backend and mobile
        └── lib/
            └── src/
                ├── user_dto.dart
                └── product_dto.dart
```

## Documentation

- [Technical Architecture](./docs/neutron_x_technical_architecture.md)
- [CLI Implementation Guide](./docs/CLI_IMPLEMENTATION.md)
- [Module System](./docs/MODULE_SYSTEM_IMPLEMENTATION.md)
- [Test Suite](./docs/TEST_SUITE.md)
- API Documentation (coming soon)
- Plugin Development Guide (coming soon)

## 🧪 Development Status

**Current Version**: 0.1.0 (Alpha)

This is an early-stage implementation. The API may change before the 1.0 release.

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

Built with ❤️ for the Flutter community
# neutronx

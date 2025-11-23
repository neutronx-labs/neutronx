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

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  neutronx: ^0.1.0
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

## 📚 Documentation

- [Technical Architecture](./neutron_x_technical_architecture.md)
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

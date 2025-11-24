# NeutronX Example Applications

This directory contains **two example applications** demonstrating different architectural approaches.

## 📁 Example Files

### 1. `main.dart` - Service-Based Architecture (Original)
The **traditional approach** where you manually register services in the DI container.

**Best for:**
- Small APIs (< 5 features)
- Learning NeutronX basics
- Quick prototyping
- Maximum simplicity

**Run:**
```bash
dart run example/main.dart
```

---

### 2. `main_modular.dart` - Module-Based Architecture (NEW! 🎉)
The **NestJS-style approach** using self-contained modules.

**Best for:**
- Large APIs (> 5 features)
- Team development
- Better organization
- Coming from NestJS/Angular

**Run:**
```bash
dart run example/main_modular.dart
```

---

## 🎯 Key Differences

### Service-Based (main.dart)
```dart
// main.dart gets cluttered with DI registrations
app.container.registerLazySingleton<UsersRepository>(...);
app.container.registerLazySingleton<UsersService>(...);
final usersModule = UsersModule(container.get<UsersService>());
router.mount('/api', usersModule.createRouter());
```

### Module-Based (main_modular.dart)
```dart
// Clean main.dart - just register modules!
app.registerModules([
  UsersModule(),    // Self-contained with DI
  ProductsModule(), // Each module manages itself
  OrdersModule(),
]);
```

---

## 🏗️ Features Demonstrated

### Architecture Patterns
- ✅ **Modular Design**: Separate modules for features
- ✅ **Dependency Injection**: DI container with circular dependency detection
- ✅ **Layered Architecture**: Repository → Service → Module
- ✅ **Shared DTOs**: Models package shared between backend and Flutter

### NeutronX Features
- ✅ **Router**: Nested routers with path parameters (`:id`)
- ✅ **Middleware**: Logging, CORS, Error Handling
- ✅ **Request/Response**: Type-safe JSON parsing
- ✅ **HTTP Methods**: GET, POST, PUT, DELETE
- ✅ **Module System**: NestJS-style modules (NEW!)

## Project Structure

```
example/
├── main.dart                         # Service-based example
├── main_modular.dart                 # Module-based example (NEW!)
├── lib/
│   ├── repositories/
│   │   └── users_repository.dart     # Data access layer
│   ├── services/
│   │   └── users_service.dart        # Business logic layer
│   └── modules/
│       ├── users_module.dart         # Service-based version
│       └── users_module_v2.dart      # Module-based version (NEW!)
└── pubspec.yaml

packages/models/                       # Shared DTOs package
├── lib/
│   ├── models.dart
│   └── src/
│       ├── user_dto.dart
│       └── product_dto.dart
└── pubspec.yaml
```

## 🚀 Quick Start

### 1. Install dependencies:
```bash
cd example
dart pub get
```

### 2. Run service-based example (original):
```bash
dart run main.dart
```

The server will start on `http://localhost:3000`

## API Endpoints

### Root
- `GET /` - Welcome message with API info
- `GET /health` - Health check endpoint

### Users CRUD
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

## Example Requests

### List all users
```bash
curl http://localhost:3000/api/users
```

### Get a specific user
```bash
curl http://localhost:3000/api/users/1
```

### Create a new user
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### Update a user
```bash
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Doe"}'
```

### Delete a user
```bash
curl -X DELETE http://localhost:3000/api/users/1
```

## Key Concepts

### 1. Dependency Injection

Services are registered at startup and injected where needed:

```dart
app.container.registerLazySingleton<UsersRepository>(
  (c) => UsersRepository(),
);
app.container.registerLazySingleton<UsersService>(
  (c) => UsersService(c.get<UsersRepository>()),
);
```

### 2. Modular Routers

Each feature gets its own module with a router:

```dart
final usersModule = UsersModule(usersService);
apiRouter.mount('', usersModule.createRouter());
router.mount('/api', apiRouter);
```

### 3. Middleware Stack

Middleware are applied in order:

```dart
app.useMiddleware([
  loggingMiddleware(),      // Logs all requests
  corsMiddleware(),         // Handles CORS
  errorHandlerMiddleware(), // Catches errors
]);
```

### 4. Shared DTOs

DTOs are defined once and used by both backend and Flutter:

```dart
// In packages/models/
class UserDto {
  final String id;
  final String name;
  final String email;
  
  Map<String, dynamic> toJson() { ... }
  factory UserDto.fromJson(Map<String, dynamic> json) { ... }
}

// In backend:
return Response.json(user.toJson());

// In Flutter (future):
final user = UserDto.fromJson(jsonDecode(response.body));
```

## Next Steps

To build a production app:

1. **Add a real database**: Replace `UsersRepository` with PostgreSQL/MongoDB
2. **Add authentication**: Use JWT middleware for protected routes
3. **Add validation**: Use a validation library for input validation
4. **Add tests**: Write unit and integration tests
5. **Add logging**: Use a structured logging library
6. **Add configuration**: Use environment variables for config

## Flutter Integration

To use this backend with Flutter:

1. Add the `models` package to your Flutter app's `pubspec.yaml`
2. Use the shared DTOs for type-safe API communication
3. Any changes to DTOs will cause compile-time errors in both backend and Flutter
4. This ensures API contracts are always in sync!

## Learn More

- [NeutronX Technical Architecture](../neutron_x_technical_architecture.md)
- [Main README](../README.md)

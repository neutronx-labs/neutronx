# Module Architecture: Current vs NestJS-Style Approach

## Current Approach (Service-Based DI)

### Implementation
```dart
// main.dart - Register each layer separately
app.container.registerLazySingleton<UsersRepository>(
  (c) => UsersRepository(),
);
app.container.registerLazySingleton<UsersService>(
  (c) => UsersService(c.get<UsersRepository>()),
);

// Then manually create module
final usersService = app.container.get<UsersService>();
final usersModule = UsersModule(usersService);
```

### Pros ✅
1. **Fine-grained control** - Register services individually
2. **Simple to understand** - Clear dependency chain visible in main.dart
3. **Easy debugging** - Can see exact registration order
4. **Flexible sharing** - Services can be used across multiple modules easily
5. **Explicit dependencies** - No magic, everything is visible
6. **Lighter modules** - Module is just a router factory
7. **Testing friendly** - Mock individual services easily
8. **No boilerplate** - No need for module classes

### Cons ❌
1. **Manual wiring** - Have to register each service in main.dart
2. **Scales poorly** - 10 features = 30+ registrations in main.dart
3. **Duplicate code** - Similar registration patterns repeated
4. **Easy to forget** - Might forget to register a dependency
5. **No encapsulation** - Module internals exposed to main.dart
6. **No module lifecycle** - Can't do module-level setup/teardown
7. **Hard to reuse** - Can't easily package a feature as a "module"

---

## NestJS-Style Approach (Module-Based DI)

### Implementation
```dart
// users_module.dart - Self-contained module
class UsersModule extends NeutronModule {
  @override
  Future<void> register(ModuleContext ctx) async {
    // Register all internal dependencies
    ctx.container.registerLazySingleton<UsersRepository>(
      (c) => UsersRepository(),
    );
    ctx.container.registerLazySingleton<UsersService>(
      (c) => UsersService(c.get<UsersRepository>()),
    );
    
    // Register routes
    ctx.router.get('/users', _handleGetUsers);
    ctx.router.post('/users', _handleCreateUser);
  }
  
  // Private route handlers with dependency access
  Future<Response> _handleGetUsers(Request req) async {
    final service = ctx.container.get<UsersService>();
    final users = service.getAllUsers();
    return Response.json(users.map((u) => u.toJson()).toList());
  }
}

// main.dart - Just register modules!
app.registerModule(UsersModule());
app.registerModule(ProductsModule());
app.registerModule(OrdersModule());
```

### Pros ✅
1. **Encapsulation** - Module owns its dependencies
2. **Scales beautifully** - 10 features = 10 clean registrations
3. **Self-documenting** - Everything related to Users is in UsersModule
4. **Reusable** - Can publish modules as packages
5. **Module lifecycle** - Setup/teardown per module
6. **No main.dart clutter** - Clean application bootstrap
7. **Better organization** - Clear feature boundaries
8. **Easier onboarding** - New devs work on one module
9. **Plugin-like** - Modules can be enabled/disabled easily
10. **NestJS familiarity** - Developers coming from Node/NestJS feel at home

### Cons ❌
1. **More abstraction** - Another layer to understand
2. **Harder debugging** - Dependencies hidden inside modules
3. **Potential conflicts** - Two modules might register same type
4. **Less flexibility** - Harder to share services across modules
5. **More boilerplate** - Need to create module classes
6. **Testing complexity** - Need to test module registration too
7. **Learning curve** - Developers need to understand module system

---

## Hybrid Approach (Recommended for NeutronX)

Combine the best of both worlds:

```dart
// users_module.dart - Module manages its own dependencies
class UsersModule extends NeutronModule {
  @override
  String get name => 'users';
  
  @override
  Future<void> register(ModuleContext ctx) async {
    // Register internal dependencies (repository, service)
    _registerDependencies(ctx.container);
    
    // Register routes
    _registerRoutes(ctx.router, ctx.container);
  }
  
  void _registerDependencies(NeutronContainer container) {
    container.registerLazySingleton<UsersRepository>(
      (c) => UsersRepository(),
    );
    container.registerLazySingleton<UsersService>(
      (c) => UsersService(c.get<UsersRepository>()),
    );
  }
  
  void _registerRoutes(Router router, NeutronContainer container) {
    // Get service once (not per request)
    final service = container.get<UsersService>();
    
    router.get('/users', (req) async {
      final users = service.getAllUsers();
      return Response.json(users.map((u) => u.toJson()).toList());
    });
    
    router.post('/users', (req) async {
      final body = await req.json() as Map<String, dynamic>;
      final user = service.createUser(body['name'], body['email']);
      return Response.json(user.toJson(), statusCode: 201);
    });
  }
  
  // Optional: Export services for cross-module usage
  @override
  List<Type> get exports => [UsersService];
}

// main.dart - Clean and simple
void main() async {
  final app = NeutronApp();
  
  // Register modules (each self-contained)
  app.registerModules([
    UsersModule(),
    ProductsModule(),
    OrdersModule(),
    AuthModule(),
  ]);
  
  // Global middleware
  app.useMiddleware([
    loggingMiddleware(),
    corsMiddleware(),
  ]);
  
  await app.listen(port: 3000);
}
```

### Hybrid Pros ✅
1. **Clean main.dart** - Just register modules
2. **Self-contained** - Each module owns its dependencies
3. **Explicit exports** - Modules can share services via exports
4. **Simple debugging** - Services resolved once, not per request
5. **Best performance** - Services are singletons, not recreated
6. **Module isolation** - Each feature is independent
7. **Easy testing** - Mock at module or service level
8. **Gradual adoption** - Can mix current and module approach

---

## Recommendation for NeutronX v1.0

**Implement the Hybrid Approach** with these features:

### Phase 1: Add NeutronModule Base Class
```dart
abstract class NeutronModule {
  String get name;
  Future<void> register(ModuleContext ctx);
  List<Type> get exports => []; // Services this module exports
  List<NeutronModule> get imports => []; // Other modules it depends on
}
```

### Phase 2: Add ModuleContext
```dart
class ModuleContext {
  final NeutronContainer container;
  final Router router;
  final Map<String, dynamic> config;
  
  ModuleContext({
    required this.container,
    required this.router,
    required this.config,
  });
}
```

### Phase 3: Extend NeutronApp
```dart
class NeutronApp {
  // ... existing code ...
  
  void registerModule(NeutronModule module) {
    _modules.add(module);
  }
  
  void registerModules(List<NeutronModule> modules) {
    _modules.addAll(modules);
  }
  
  Future<void> _registerModules() async {
    for (final module in _modules) {
      final moduleRouter = Router();
      final moduleContext = ModuleContext(
        container: _container,
        router: moduleRouter,
        config: _config,
      );
      
      await module.register(moduleContext);
      
      // Mount module router at /module-name
      _router?.mount('/${module.name}', moduleRouter);
      
      print('Module registered: ${module.name}');
    }
  }
}
```

---

## Migration Path

### Step 1: Keep Current Approach Working
Don't break existing code. Both patterns should coexist.

### Step 2: Add Module System Alongside
Provide `NeutronModule` as an optional pattern.

### Step 3: Update Example
Show both approaches in the example:
- `example/main_simple.dart` - Current service-based
- `example/main_modular.dart` - New module-based

### Step 4: Document Both
Clear docs on when to use each approach:
- **Service-based**: Simple apps, prototypes, learning
- **Module-based**: Large apps, teams, published packages

---

## Conclusion

**For NeutronX v1.0**, I recommend:

1. ✅ **Implement the hybrid module system**
2. ✅ **Keep current service-based approach** (don't break it)
3. ✅ **Make modules optional** (developer choice)
4. ✅ **Default to modules in examples** (show best practice)

This gives you:
- **NestJS-like developer experience** (familiar to Node.js devs)
- **Scales to enterprise apps** (100+ routes organized cleanly)
- **Backward compatible** (existing code still works)
- **Flutter-friendly** (modules = features)

---

## Implementation Priority

**Should we implement this now?**

**Arguments FOR:**
- Makes the framework more professional
- Better for scaling (the whole point of NeutronX)
- More marketable (NestJS developers will love it)
- Cleaner example code

**Arguments AGAINST:**
- Tests should come first (ensure current code is solid)
- CLI tool might be more valuable short-term
- Adds complexity to v0.1.0

**My recommendation**: Implement modules **after tests** but **before CLI**, as the CLI should generate module-based code by default.

---

Would you like me to implement the module system now?

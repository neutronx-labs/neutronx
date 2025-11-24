import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

class TestService {
  final String name;
  TestService(this.name);
}

class TestModule extends NeutronModule {
  @override
  String get name => 'test';

  bool initCalled = false;
  bool readyCalled = false;
  bool destroyCalled = false;
  ModuleContext? capturedContext;

  @override
  Future<void> register(ModuleContext context) async {
    capturedContext = context;
    context.container.registerLazySingleton<TestService>(
      (c) => TestService('test-service'),
    );
  }

  @override
  Future<void> onInit() async {
    initCalled = true;
  }

  @override
  Future<void> onReady() async {
    readyCalled = true;
  }

  @override
  Future<void> onDestroy() async {
    destroyCalled = true;
  }
}

class UsersModule extends NeutronModule {
  @override
  String get name => 'users';

  @override
  Future<void> register(ModuleContext context) async {
    final router = context.router;
    context.container.registerLazySingleton<TestService>(
      (c) => TestService('users-service'),
    );
    router.get('/', (req) async => Response.json({'users': []}));
  }

  @override
  List<Type> get exports => [TestService];
}

class PostsModule extends NeutronModule {
  final UsersModule usersModule;
  PostsModule(this.usersModule);

  @override
  String get name => 'posts';

  @override
  List<NeutronModule> get imports => [usersModule];

  @override
  Future<void> register(ModuleContext context) async {
    // Can use TestService from UsersModule because it's exported
    final router = context.router;
    router.get('/', (req) async => Response.json({'posts': []}));
  }
}

void main() {
  group('NeutronModule', () {
    late NeutronContainer container;
    late Router router;

    setUp(() {
      container = NeutronContainer();
      router = Router();
    });

    test('module register() is called with context', () async {
      final module = TestModule();
      final context = ModuleContext(
        container: container,
        router: router,
        config: {},
      );

      await module.register(context);

      expect(module.capturedContext, same(context));
      expect(container.isRegistered<TestService>(), isTrue);
    });

    test('ModuleContext provides access to container', () {
      final context = ModuleContext(
        container: container,
        router: router,
        config: {},
      );

      expect(context.container, same(container));
    });

    test('ModuleContext provides access to router', () {
      final context = ModuleContext(
        container: container,
        router: router,
        config: {},
      );

      expect(context.router, same(router));
    });

    test('module lifecycle hooks are called', () async {
      final module = TestModule();

      expect(module.initCalled, isFalse);
      expect(module.readyCalled, isFalse);
      expect(module.destroyCalled, isFalse);

      await module.onInit();
      expect(module.initCalled, isTrue);

      await module.onReady();
      expect(module.readyCalled, isTrue);

      await module.onDestroy();
      expect(module.destroyCalled, isTrue);
    });

    test('module name is accessible', () {
      final module = TestModule();
      expect(module.name, equals('test'));
    });

    test('module exports list is empty by default', () {
      final module = TestModule();
      expect(module.exports, isEmpty);
    });

    test('module imports list is empty by default', () {
      final module = TestModule();
      expect(module.imports, isEmpty);
    });

    test('module can specify exports', () {
      final module = UsersModule();
      expect(module.exports, contains(TestService));
    });

    test('module can specify imports', () {
      final usersModule = UsersModule();
      final postsModule = PostsModule(usersModule);

      expect(postsModule.imports, contains(usersModule));
    });

    test('module registers routes on its router', () async {
      final module = UsersModule();
      final context = ModuleContext(
        container: container,
        router: router,
        config: {},
      );

      await module.register(context);

      // Test that route was registered (module registers on '/', not '/users/')
      final request = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/'),
        path: '/',
      );

      final response = await router.handler(request);
      expect(response.statusCode, equals(200));
    });

    test('module can register dependencies', () async {
      final module = TestModule();
      final context = ModuleContext(
        container: container,
        router: router,
        config: {},
      );

      await module.register(context);

      final service = container.get<TestService>();
      expect(service.name, equals('test-service'));
    });
  });
}

import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

class TestPlugin extends NeutronPlugin {
  @override
  String get name => 'test-plugin';

  bool registered = false;
  PluginContext? capturedContext;

  @override
  Future<void> register(PluginContext context) async {
    registered = true;
    capturedContext = context;
  }
}

class DatabasePlugin extends NeutronPlugin {
  @override
  String get name => 'database';

  @override
  Future<void> register(PluginContext context) async {
    // Register database connection in container
    context.container.registerSingleton<String>('db-connection-string');
  }
}

void main() {
  group('NeutronPlugin', () {
    late NeutronContainer container;
    late Router router;

    setUp(() {
      container = NeutronContainer();
      router = Router();
    });

    test('plugin register() is called with context', () async {
      final plugin = TestPlugin();
      final context = PluginContext(
        container: container,
        router: router,
        config: {},
      );

      await plugin.register(context);

      expect(plugin.registered, isTrue);
      expect(plugin.capturedContext, same(context));
    });

    test('PluginContext provides access to container', () {
      final context = PluginContext(
        container: container,
        router: router,
        config: {},
      );

      expect(context.container, same(container));
    });

    test('PluginContext provides access to router', () {
      final context = PluginContext(
        container: container,
        router: router,
        config: {},
      );

      expect(context.router, same(router));
    });

    test('PluginContext provides access to config', () {
      final config = {'database': 'postgres', 'port': 5432};
      final context = PluginContext(
        container: container,
        router: router,
        config: config,
      );

      expect(context.config['database'], equals('postgres'));
      expect(context.config['port'], equals(5432));
    });

    test('plugin can register services in container', () async {
      final plugin = DatabasePlugin();
      final context = PluginContext(
        container: container,
        router: router,
        config: {},
      );

      await plugin.register(context);

      expect(container.isRegistered<String>(), isTrue);
      expect(container.get<String>(), equals('db-connection-string'));
    });

    test('plugin name is accessible', () {
      final plugin = TestPlugin();
      expect(plugin.name, equals('test-plugin'));
    });
  });
}

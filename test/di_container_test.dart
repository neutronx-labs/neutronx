import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

class ServiceA {}

class ServiceB {
  final ServiceA serviceA;
  ServiceB(this.serviceA);
}

class ServiceC {
  final ServiceB serviceB;
  ServiceC(this.serviceB);
}

class CircularA {
  CircularA(CircularB b);
}

class CircularB {
  CircularB(CircularA a);
}

void main() {
  group('NeutronContainer', () {
    late NeutronContainer container;

    setUp(() {
      container = NeutronContainer();
    });

    test('registerSingleton() registers a singleton instance', () {
      final instance = ServiceA();
      container.registerSingleton<ServiceA>(instance);

      final retrieved = container.get<ServiceA>();
      expect(retrieved, same(instance));
    });

    test('registerSingleton() returns same instance on multiple gets', () {
      final instance = ServiceA();
      container.registerSingleton<ServiceA>(instance);

      final first = container.get<ServiceA>();
      final second = container.get<ServiceA>();

      expect(first, same(second));
    });

    test('registerSingleton() throws if type already registered', () {
      container.registerSingleton<ServiceA>(ServiceA());

      expect(
        () => container.registerSingleton<ServiceA>(ServiceA()),
        throwsStateError,
      );
    });

    test('registerLazySingleton() defers creation until first get', () {
      var factoryCalled = false;

      container.registerLazySingleton<ServiceA>((c) {
        factoryCalled = true;
        return ServiceA();
      });

      expect(factoryCalled, isFalse);

      container.get<ServiceA>();
      expect(factoryCalled, isTrue);
    });

    test('registerLazySingleton() caches result after first call', () {
      var callCount = 0;

      container.registerLazySingleton<ServiceA>((c) {
        callCount++;
        return ServiceA();
      });

      final first = container.get<ServiceA>();
      final second = container.get<ServiceA>();

      expect(callCount, equals(1));
      expect(first, same(second));
    });

    test('registerFactory() creates new instance on every get', () {
      var callCount = 0;

      container.registerFactory<ServiceA>((c) {
        callCount++;
        return ServiceA();
      });

      final first = container.get<ServiceA>();
      final second = container.get<ServiceA>();

      expect(callCount, equals(2));
      expect(first, isNot(same(second)));
    });

    test('get() throws if type not registered', () {
      expect(
        () => container.get<ServiceA>(),
        throwsStateError,
      );
    });

    test('isRegistered() returns true for registered types', () {
      container.registerSingleton<ServiceA>(ServiceA());
      expect(container.isRegistered<ServiceA>(), isTrue);
    });

    test('isRegistered() returns false for unregistered types', () {
      expect(container.isRegistered<ServiceA>(), isFalse);
    });

    test('unregister() removes a registration', () {
      container.registerSingleton<ServiceA>(ServiceA());
      expect(container.isRegistered<ServiceA>(), isTrue);

      container.unregister<ServiceA>();
      expect(container.isRegistered<ServiceA>(), isFalse);
    });

    test('clear() removes all registrations', () {
      container.registerSingleton<ServiceA>(ServiceA());
      container.registerSingleton<ServiceB>(ServiceB(ServiceA()));

      expect(container.registrationCount, equals(2));

      container.clear();
      expect(container.registrationCount, equals(0));
    });

    test('overrideSingleton() replaces existing singleton', () {
      final original = ServiceA();
      final replacement = ServiceA();

      container.registerSingleton<ServiceA>(original);
      container.overrideSingleton<ServiceA>(replacement);

      final retrieved = container.get<ServiceA>();
      expect(retrieved, same(replacement));
      expect(retrieved, isNot(same(original)));
    });

    test('can resolve dependencies between services', () {
      container.registerLazySingleton<ServiceA>((c) => ServiceA());
      container.registerLazySingleton<ServiceB>(
        (c) => ServiceB(c.get<ServiceA>()),
      );

      final serviceB = container.get<ServiceB>();
      expect(serviceB.serviceA, isNotNull);
    });

    test('can resolve deep dependency chains', () {
      container.registerLazySingleton<ServiceA>((c) => ServiceA());
      container.registerLazySingleton<ServiceB>(
        (c) => ServiceB(c.get<ServiceA>()),
      );
      container.registerLazySingleton<ServiceC>(
        (c) => ServiceC(c.get<ServiceB>()),
      );

      final serviceC = container.get<ServiceC>();
      expect(serviceC.serviceB.serviceA, isNotNull);
    });

    test('detects circular dependencies', () {
      container.registerLazySingleton<CircularA>(
        (c) => CircularA(c.get<CircularB>()),
      );
      container.registerLazySingleton<CircularB>(
        (c) => CircularB(c.get<CircularA>()),
      );

      expect(
        () => container.get<CircularA>(),
        throwsA(isA<CircularDependencyError>()),
      );
    });

    test('CircularDependencyError includes dependency chain', () {
      container.registerLazySingleton<CircularA>(
        (c) => CircularA(c.get<CircularB>()),
      );
      container.registerLazySingleton<CircularB>(
        (c) => CircularB(c.get<CircularA>()),
      );

      try {
        container.get<CircularA>();
        fail('Should have thrown CircularDependencyError');
      } on CircularDependencyError catch (e) {
        expect(e.dependencyChain, contains(CircularA));
        expect(e.dependencyChain, contains(CircularB));
        expect(e.message, contains('Circular dependency'));
      }
    });

    test('registrationCount returns correct count', () {
      expect(container.registrationCount, equals(0));

      container.registerSingleton<ServiceA>(ServiceA());
      expect(container.registrationCount, equals(1));

      container.registerSingleton<ServiceB>(ServiceB(ServiceA()));
      expect(container.registrationCount, equals(2));

      container.unregister<ServiceA>();
      expect(container.registrationCount, equals(1));
    });

    test('createChild() resolves from parent when missing locally', () {
      container.registerSingleton<ServiceA>(ServiceA());
      final child = container.createChild();

      final resolved = child.get<ServiceA>();
      expect(resolved, same(container.get<ServiceA>()));
    });

    test('dispose() invokes registered disposers', () async {
      var disposed = false;
      container.registerSingleton<ServiceA>(
        ServiceA(),
        dispose: (_) {
          disposed = true;
        },
      );

      await container.dispose();
      expect(disposed, isTrue);
    });

    test('toString() returns readable representation', () {
      container.registerSingleton<ServiceA>(ServiceA());
      final str = container.toString();

      expect(str, contains('NeutronContainer'));
      expect(str, contains('1'));
    });
  });
}

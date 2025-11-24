import 'circular_dependency_error.dart';

/// Registration types for dependencies
enum _RegistrationType {
  singleton,
  lazySingleton,
  factory,
}

/// Internal representation of a dependency registration
class _Registration<T> {
  final _RegistrationType type;
  final T? instance;
  final T Function(NeutronContainer)? factory;

  _Registration.singleton(this.instance)
      : type = _RegistrationType.singleton,
        factory = null;

  _Registration.lazySingleton(this.factory)
      : type = _RegistrationType.lazySingleton,
        instance = null;

  _Registration.factory(this.factory)
      : type = _RegistrationType.factory,
        instance = null;
}

/// A lightweight dependency injection container for NeutronX
///
/// The container supports three registration types:
/// - **Singleton**: Pre-built instance that is reused
/// - **Lazy Singleton**: Factory that is called once on first access
/// - **Factory**: Factory that creates a new instance on every access
///
/// The container enforces acyclic dependency graphs and will throw a
/// [CircularDependencyError] if a cycle is detected during resolution.
///
/// Example:
/// ```dart
/// final container = NeutronContainer();
///
/// // Register a singleton
/// container.registerSingleton<DbClient>(DbClient.fromEnv());
///
/// // Register a lazy singleton
/// container.registerLazySingleton<UsersRepo>(
///   (c) => UsersRepo(c.get<DbClient>())
/// );
///
/// // Register a factory
/// container.registerFactory<Logger>((c) => Logger());
///
/// // Resolve dependencies
/// final repo = container.get<UsersRepo>();
/// ```
class NeutronContainer {
  final Map<Type, _Registration> _registrations = {};
  final Map<Type, dynamic> _singletonInstances = {};
  final Set<Type> _resolutionStack = {};
  final Map<Type, void Function(dynamic)> _disposers = {};
  final NeutronContainer? _parent;

  NeutronContainer({NeutronContainer? parent}) : _parent = parent;

  /// Registers a pre-built singleton instance
  ///
  /// The same instance will be returned on every [get<T>()] call.
  void registerSingleton<T extends Object>(T instance, {void Function(T)? dispose}) {
    if (_registrations.containsKey(T)) {
      throw StateError('Type $T is already registered');
    }

    _registrations[T] = _Registration<T>.singleton(instance);
    _singletonInstances[T] = instance;
    if (dispose != null) {
      _disposers[T] = (obj) => dispose(obj as T);
    }
  }

  /// Registers a lazy singleton factory
  ///
  /// The factory will be called once on the first [get<T>()] call,
  /// and the result will be cached for subsequent calls.
  void registerLazySingleton<T extends Object>(
    T Function(NeutronContainer) factory, {
    void Function(T)? dispose,
  }) {
    if (_registrations.containsKey(T)) {
      throw StateError('Type $T is already registered');
    }

    _registrations[T] = _Registration<T>.lazySingleton(factory);
    if (dispose != null) {
      _disposers[T] = (obj) => dispose(obj as T);
    }
  }

  /// Registers a factory function
  ///
  /// The factory will be called on every [get<T>()] call,
  /// creating a new instance each time.
  void registerFactory<T extends Object>(
    T Function(NeutronContainer) factory,
  ) {
    if (_registrations.containsKey(T)) {
      throw StateError('Type $T is already registered');
    }

    _registrations[T] = _Registration<T>.factory(factory);
  }

  /// Overrides an existing singleton registration
  ///
  /// This is useful for testing or when a plugin needs to replace
  /// a service with a custom implementation.
  ///
  /// Note: This only works with singletons. For factories and lazy singletons,
  /// unregister the type first and then register a new one.
  void overrideSingleton<T extends Object>(T instance) {
    _disposeIfPresent(T);
    _registrations[T] = _Registration<T>.singleton(instance);
    _singletonInstances[T] = instance;
  }

  /// Resolves and returns an instance of type T
  ///
  /// Throws [StateError] if T is not registered.
  /// Throws [CircularDependencyError] if a circular dependency is detected.
  T get<T extends Object>() {
    if (!_registrations.containsKey(T)) {
      if (_parent != null) {
        return _parent!.get<T>();
      }

      throw StateError(
        'Type $T is not registered in the container. '
        'Did you forget to call register?',
      );
    }

    // Check for circular dependencies
    if (_resolutionStack.contains(T)) {
      final chain = [..._resolutionStack, T];
      throw CircularDependencyError(
        'Circular dependency detected for type $T',
        chain,
      );
    }

    final registration = _registrations[T]!;

    switch (registration.type) {
      case _RegistrationType.singleton:
        // Already resolved and cached
        return _singletonInstances[T] as T;

      case _RegistrationType.lazySingleton:
        // Check if already resolved
        if (_singletonInstances.containsKey(T)) {
          return _singletonInstances[T] as T;
        }

        // Resolve the lazy singleton
        _resolutionStack.add(T);
        try {
          final instance = (registration.factory! as T Function(NeutronContainer))(this);
          _singletonInstances[T] = instance;
          return instance;
        } finally {
          _resolutionStack.remove(T);
        }

      case _RegistrationType.factory:
        // Always create a new instance
        _resolutionStack.add(T);
        try {
          return (registration.factory! as T Function(NeutronContainer))(this);
        } finally {
          _resolutionStack.remove(T);
        }
    }
  }

  /// Checks if a type is registered in the container
  bool isRegistered<T extends Object>() {
    return _registrations.containsKey(T);
  }

  /// Checks if a raw type is registered (useful when you only have a Type instance)
  bool isRegisteredType(Type type) {
    return _registrations.containsKey(type);
  }

  /// Unregisters a type from the container
  ///
  /// This is useful for testing or dynamic reconfiguration.
  void unregister<T extends Object>() {
    _disposeIfPresent(T);
    _registrations.remove(T);
    _singletonInstances.remove(T);
    _disposers.remove(T);
  }

  /// Clears all registrations and cached instances
  ///
  /// This is primarily useful for testing.
  void clear() {
    _disposeAll();
    _registrations.clear();
    _singletonInstances.clear();
    _resolutionStack.clear();
    _disposers.clear();
  }

  /// Returns the number of registered types
  int get registrationCount => _registrations.length;

  /// Creates a child container that will fall back to this container
  /// for resolution. Useful for request-scoped dependencies.
  NeutronContainer createChild() => NeutronContainer(parent: this);

  /// Dispose singletons that have registered disposers.
  Future<void> dispose() async {
    _disposeAll();
  }

  void _disposeAll() {
    _singletonInstances.forEach((type, instance) {
      _disposeIfPresent(type, instance: instance);
    });
  }

  void _disposeIfPresent(Type type, {dynamic instance}) {
    final disposer = _disposers[type];
    final value = instance ?? _singletonInstances[type];
    if (disposer != null && value != null) {
      try {
        disposer(value);
      } catch (_) {
        // Swallow disposer errors to avoid masking shutdown
      }
    }
  }

  @override
  String toString() {
    return 'NeutronContainer(${_registrations.length} registrations)';
  }
}

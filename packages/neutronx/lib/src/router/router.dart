import 'package:neutronx/neutronx.dart';

/// Internal representation of a mounted sub-router
class _Mount {
  final String prefix;
  final Router router;

  _Mount(this.prefix, this.router);
}

/// Trie node for route matching
class _RouteNode {
  final Map<String, _RouteNode> staticChildren = {};
  _RouteNode? paramChild;
  String? paramName;
  final Map<String, Handler> handlers = {};

  _RouteNode();

  void addRoute(String method, List<String> segments, Handler handler) {
    var node = this;

    for (final segment in segments) {
      if (segment.startsWith(':')) {
        node.paramChild ??= _RouteNode();
        node.paramChild!.paramName ??= segment.substring(1);
        node = node.paramChild!;
      } else {
        node = node.staticChildren.putIfAbsent(segment, () => _RouteNode());
      }
    }

    if (node.handlers.containsKey(method)) {
      throw StateError('Route for method $method already exists on ${segments.join('/')}');
    }

    node.handlers[method] = handler;
  }

  _RouteMatch? match(List<String> segments) {
    return _matchInternal(segments, 0, <String, String>{});
  }

  _RouteMatch? _matchInternal(
    List<String> segments,
    int index,
    Map<String, String> params,
  ) {
    if (index == segments.length) {
      if (handlers.isEmpty) {
        return null;
      }
      return _RouteMatch(params: params, handlers: handlers);
    }

    final segment = segments[index];

    // Try static match first
    final staticChild = staticChildren[segment];
    if (staticChild != null) {
      final match = staticChild._matchInternal(segments, index + 1, params);
      if (match != null) {
        return match;
      }
    }

    // Fallback to parameter match
    final paramChild = this.paramChild;
    if (paramChild != null && paramChild.paramName != null) {
      final newParams = Map<String, String>.from(params)
        ..[paramChild.paramName!] = segment;
      final match = paramChild._matchInternal(segments, index + 1, newParams);
      if (match != null) {
        return match;
      }
    }

    return null;
  }
}

class _RouteMatch {
  final Map<String, String> params;
  final Map<String, Handler> handlers;

  _RouteMatch({
    required this.params,
    required this.handlers,
  });

  List<String> get allowedMethods {
    final methods = handlers.keys.toSet();
    if (methods.contains('*')) {
      methods
        ..remove('*')
        ..addAll(['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD']);
    }
    if (methods.contains('GET')) {
      methods.add('HEAD');
    }
    methods.add('OPTIONS');
    methods.remove('*');
    return methods.toList()..sort();
  }
}

class WebSocketRouteMatch {
  final Map<String, String> params;
  final WebSocketHandler handler;
  final String path;

  WebSocketRouteMatch({
    required this.params,
    required this.handler,
    required this.path,
  });
}

class _WebSocketRouteNode {
  final Map<String, _WebSocketRouteNode> staticChildren = {};
  _WebSocketRouteNode? paramChild;
  String? paramName;
  WebSocketHandler? handler;

  void addRoute(List<String> segments, WebSocketHandler handler) {
    var node = this;

    for (final segment in segments) {
      if (segment.startsWith(':')) {
        node.paramChild ??= _WebSocketRouteNode();
        node.paramChild!.paramName ??= segment.substring(1);
        node = node.paramChild!;
      } else {
        node = node.staticChildren.putIfAbsent(segment, () => _WebSocketRouteNode());
      }
    }

    if (node.handler != null) {
      throw StateError('WebSocket route already exists on ${segments.join('/')}');
    }
    node.handler = handler;
  }

  WebSocketRouteMatch? match(List<String> segments) {
    return _matchInternal(segments, 0, <String, String>{});
  }

  WebSocketRouteMatch? _matchInternal(
    List<String> segments,
    int index,
    Map<String, String> params,
  ) {
    if (index == segments.length) {
      if (handler == null) {
        return null;
      }
      final routePath = '/${segments.join('/')}';
      return WebSocketRouteMatch(
        params: params,
        handler: handler!,
        path: routePath.isEmpty ? '/' : routePath,
      );
    }

    final segment = segments[index];

    final staticChild = staticChildren[segment];
    if (staticChild != null) {
      final match = staticChild._matchInternal(segments, index + 1, params);
      if (match != null) {
        return match;
      }
    }

    final paramChild = this.paramChild;
    if (paramChild != null && paramChild.paramName != null) {
      final newParams = Map<String, String>.from(params)
        ..[paramChild.paramName!] = segment;
      final match = paramChild._matchInternal(segments, index + 1, newParams);
      if (match != null) {
        return match;
      }
    }

    return null;
  }
}

/// Router class for defining and matching HTTP routes
///
/// The router supports:
/// - HTTP method routing (.get(), .post(), .put(), .delete(), .patch())
/// - Static paths ('/users')
/// - Dynamic parameters ('/users/:id')
/// - Nested routers via .mount()
///
/// Example:
/// ```dart
/// final router = Router();
///
/// router.get('/users', (req) async {
///   return Response.json([...]);
/// });
///
/// router.get('/users/:id', (req) async {
///   final id = req.params['id'];
///   return Response.json({'id': id});
/// });
///
/// // Mount a sub-router
/// final apiRouter = Router();
/// router.mount('/api', apiRouter);
/// ```
class Router {
  final _RouteNode _root = _RouteNode();
  final _WebSocketRouteNode _wsRoot = _WebSocketRouteNode();
  final List<_Mount> _mounts = [];

  /// Registers a GET route
  void get(String path, Handler handler) {
    _addRoute('GET', path, handler);
  }

  /// Registers a POST route
  void post(String path, Handler handler) {
    _addRoute('POST', path, handler);
  }

  /// Registers a PUT route
  void put(String path, Handler handler) {
    _addRoute('PUT', path, handler);
  }

  /// Registers a DELETE route
  void delete(String path, Handler handler) {
    _addRoute('DELETE', path, handler);
  }

  /// Registers a PATCH route
  void patch(String path, Handler handler) {
    _addRoute('PATCH', path, handler);
  }

  /// Registers a route that matches any HTTP method
  void any(String path, Handler handler) {
    _addRoute('*', path, handler);
  }

  /// Mounts a sub-router at a prefix path
  ///
  /// The sub-router will handle all requests that start with the prefix.
  ///
  /// Example:
  /// ```dart
  /// final apiRouter = Router();
  /// apiRouter.get('/users', usersHandler);
  ///
  /// final mainRouter = Router();
  /// mainRouter.mount('/api', apiRouter); // handles /api/users
  /// ```
  void mount(String prefix, Router router) {
    // Normalize prefix (remove trailing slash)
    var normalizedPrefix = prefix;
    if (normalizedPrefix.endsWith('/')) {
      normalizedPrefix = normalizedPrefix.substring(0, normalizedPrefix.length - 1);
    }
    if (!normalizedPrefix.startsWith('/')) {
      normalizedPrefix = '/$normalizedPrefix';
    }

    _mounts.add(_Mount(normalizedPrefix, router));
  }

  /// Registers a websocket route
  void ws(String path, WebSocketHandler handler) {
    var normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    // Remove trailing slash (except root)
    if (normalizedPath.length > 1 && normalizedPath.endsWith('/')) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }

    final segments = normalizedPath.split('/').where((s) => s.isNotEmpty).toList();
    _wsRoot.addRoute(segments, handler);
  }

  /// Internal method to register a route
  void _addRoute(String method, String path, Handler handler) {
    // Normalize path
    var normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    // Remove trailing slash (except root)
    if (normalizedPath.length > 1 && normalizedPath.endsWith('/')) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }

    final segments = normalizedPath.split('/').where((s) => s.isNotEmpty).toList();
    _root.addRoute(method, segments, handler);
  }

  /// Returns a Handler that can be used in the middleware pipeline
  ///
  /// This handler will attempt to match incoming requests against registered
  /// routes and mounts.
  Handler get handler {
    return (Request req) async {
      // First, try mounted routers (they have precedence)
      for (final mount in _mounts) {
        if (req.path.startsWith(mount.prefix)) {
          // Strip the prefix and delegate to the mounted router
          final subPath = req.path.substring(mount.prefix.length);

          // Create a modified request with the sub-path
          final modifiedReq = req.copyWith(
            path: subPath.isEmpty ? '/' : subPath,
            context: {...req.context, '_originalPath': req.path},
          );

          return await mount.router.handler(modifiedReq);
        }
      }

      // Then try local routes
      final match = _match(req.path);
      if (match != null) {
        final effectiveMethod = req.method.toUpperCase();
        final handler = _selectHandler(match.handlers, effectiveMethod);

        if (effectiveMethod == 'OPTIONS') {
          if (handler != null) {
            final mergedParams = {...req.params, ...match.params};
            final reqWithParams = req.copyWith(params: mergedParams);
            return await handler(reqWithParams);
          }
          return _optionsResponse(match.allowedMethods);
        }

        if (handler != null) {
          final mergedParams = {...req.params, ...match.params};
          final reqWithParams = req.copyWith(params: mergedParams);
          final response = await handler(reqWithParams);
          if (effectiveMethod == 'HEAD' && match.handlers['HEAD'] == null) {
            return response.copyWith(body: [], bodyStream: null);
          }
          return response;
        }

        // Path matched but method not allowed
        return Response.json(
          {'error': 'Method ${req.method} not allowed'},
          statusCode: 405,
          headers: {'allow': match.allowedMethods.join(', ')},
        );
      }

      // No route matched - return 404
      return Response.notFound('Route not found: ${req.method} ${req.path}');
    };
  }

  /// Returns all registered routes (for debugging/inspection)
  List<String> get routes {
    final result = <String>[];
    _collectRoutes(_root, [], result);

    final wsRoutes = <String>[];
    _collectWebSocketRoutes(_wsRoot, [], wsRoutes);
    for (final route in wsRoutes) {
      result.add('WS $route');
    }

    for (final mount in _mounts) {
      result.add('MOUNT ${mount.prefix} -> [nested router]');
    }

    return result;
  }

  _RouteMatch? _match(String path) {
    var normalized = path;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
    return _root.match(segments);
  }

  WebSocketRouteMatch? matchWebSocket(String path) {
    var normalized = path;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    for (final mount in _mounts) {
      if (normalized.startsWith(mount.prefix)) {
        final subPath = normalized.substring(mount.prefix.length);
        final effectiveSubPath = subPath.isEmpty ? '/' : subPath;
        final match = mount.router.matchWebSocket(effectiveSubPath);
        if (match != null) {
          return match;
        }
      }
    }

    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
    return _wsRoot.match(segments);
  }

  Handler? _selectHandler(Map<String, Handler> handlers, String method) {
    // Exact match
    final handler = handlers[method];
    if (handler != null) return handler;

    // Wildcard
    if (handlers.containsKey('*')) {
      return handlers['*'];
    }

    // HEAD falls back to GET if not explicitly defined
    if (method == 'HEAD' && handlers.containsKey('GET')) {
      return handlers['GET'];
    }

    // OPTIONS is handled separately
    return null;
  }

  Response _optionsResponse(List<String> allowedMethods) {
    return Response.empty(
      statusCode: 204,
      headers: {'allow': allowedMethods.join(', ')},
    );
  }

  void _collectRoutes(_RouteNode node, List<String> prefix, List<String> output) {
    node.handlers.forEach((method, _) {
      if (method == 'HEAD') {
        // HEAD is implicit for GET; skip listing duplicates
        if (node.handlers.containsKey('GET')) return;
      }
      final routePath = '/${prefix.join('/')}';
      output.add('$method ${routePath.isEmpty ? '/' : routePath}');
    });

    node.staticChildren.forEach((segment, child) {
      _collectRoutes(child, [...prefix, segment], output);
    });

    if (node.paramChild != null) {
      final paramName = node.paramChild!.paramName ?? 'param';
      _collectRoutes(node.paramChild!, [...prefix, ':$paramName'], output);
    }
  }

  void _collectWebSocketRoutes(
    _WebSocketRouteNode node,
    List<String> prefix,
    List<String> output,
  ) {
    if (node.handler != null) {
      final routePath = '/${prefix.join('/')}';
      output.add(routePath.isEmpty ? '/' : routePath);
    }

    node.staticChildren.forEach((segment, child) {
      _collectWebSocketRoutes(child, [...prefix, segment], output);
    });

    if (node.paramChild != null) {
      final paramName = node.paramChild!.paramName ?? 'param';
      _collectWebSocketRoutes(node.paramChild!, [...prefix, ':$paramName'], output);
    }
  }

  @override
  String toString() {
    return 'Router(${routes.length} routes, ${_mounts.length} mounts)';
  }
}

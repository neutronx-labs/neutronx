import 'package:neutronx/neutronx.dart';

/// Internal representation of a route with its pattern and handler
class _Route {
  final String method;
  final _PathPattern pattern;
  final Handler handler;

  _Route(this.method, this.pattern, this.handler);
}

/// Internal representation of a mounted sub-router
class _Mount {
  final String prefix;
  final Router router;

  _Mount(this.prefix, this.router);
}

/// Pattern matching for URL paths with support for static and dynamic segments
class _PathPattern {
  final String pattern;
  final List<String> segments;
  final List<int> paramIndexes;
  final List<String> paramNames;

  _PathPattern(this.pattern)
      : segments = pattern.split('/').where((s) => s.isNotEmpty).toList(),
        paramIndexes = [],
        paramNames = [] {
    // Identify parameter segments (e.g., :id, :userId)
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].startsWith(':')) {
        paramIndexes.add(i);
        paramNames.add(segments[i].substring(1)); // Remove the ':' prefix
      }
    }
  }

  /// Checks if a path matches this pattern and extracts parameters
  ({bool matches, Map<String, String> params}) match(String path) {
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

    // Must have same number of segments
    if (pathSegments.length != segments.length) {
      return (matches: false, params: {});
    }

    final params = <String, String>{};

    // Check each segment
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].startsWith(':')) {
        // This is a parameter - extract it
        final paramName = segments[i].substring(1);
        params[paramName] = pathSegments[i];
      } else {
        // This is a static segment - must match exactly
        if (segments[i] != pathSegments[i]) {
          return (matches: false, params: {});
        }
      }
    }

    return (matches: true, params: params);
  }

  @override
  String toString() => pattern;
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
  final List<_Route> _routes = [];
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

  /// Internal method to register a route
  void _addRoute(String method, String path, Handler handler) {
    // Normalize path
    var normalizedPath = path;
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    final pattern = _PathPattern(normalizedPath);
    _routes.add(_Route(method, pattern, handler));
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
      for (final route in _routes) {
        // Check if method matches (or route accepts any method)
        if (route.method != '*' && route.method != req.method) {
          continue;
        }

        // Check if path matches
        final matchResult = route.pattern.match(req.path);
        if (matchResult.matches) {
          // Merge extracted params with existing params
          final mergedParams = {...req.params, ...matchResult.params};
          final reqWithParams = req.copyWith(params: mergedParams);
          return await route.handler(reqWithParams);
        }
      }

      // No route matched - return 404
      return Response.notFound('Route not found: ${req.method} ${req.path}');
    };
  }

  /// Returns all registered routes (for debugging/inspection)
  List<String> get routes {
    final result = <String>[];

    for (final route in _routes) {
      result.add('${route.method} ${route.pattern}');
    }

    for (final mount in _mounts) {
      result.add('MOUNT ${mount.prefix} -> [nested router]');
    }

    return result;
  }

  @override
  String toString() {
    return 'Router(${_routes.length} routes, ${_mounts.length} mounts)';
  }
}

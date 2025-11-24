import 'package:neutronx/neutronx.dart';
import 'dart:math';

/// A simple logging middleware that logs request method and path
Middleware loggingMiddleware({
  void Function(String)? logger,
}) {
  final log = logger ?? print;

  return (Handler next) {
    return (Request req) async {
      final stopwatch = Stopwatch()..start();
      log('[${DateTime.now().toIso8601String()}] ${req.method} ${req.path}');

      try {
        final response = await next(req);
        stopwatch.stop();
        log(
          '[${DateTime.now().toIso8601String()}] ${req.method} ${req.path} '
          '→ ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        );
        return response;
      } catch (e, stackTrace) {
        stopwatch.stop();
        log(
          '[${DateTime.now().toIso8601String()}] ${req.method} ${req.path} '
          '→ ERROR (${stopwatch.elapsedMilliseconds}ms): $e',
        );
        log('Stack trace: $stackTrace');
        rethrow;
      }
    };
  };
}

/// CORS middleware that adds Cross-Origin Resource Sharing headers
Middleware corsMiddleware({
  String origin = '*',
  String methods = 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
  String headers = 'Content-Type, Authorization',
  bool credentials = false,
}) {
  return (Handler next) {
    return (Request req) async {
      // Handle preflight OPTIONS request
      if (req.method == 'OPTIONS') {
        return Response.empty(statusCode: 204, headers: {
          'access-control-allow-origin': origin,
          'access-control-allow-methods': methods,
          'access-control-allow-headers': headers,
          if (credentials) 'access-control-allow-credentials': 'true',
        });
      }

      // Process normal request and add CORS headers to response
      final response = await next(req);
      return response.withHeaders({
        'access-control-allow-origin': origin,
        'access-control-allow-methods': methods,
        'access-control-allow-headers': headers,
        if (credentials) 'access-control-allow-credentials': 'true',
      });
    };
  };
}

/// Error handling middleware that catches exceptions and returns proper error responses
Middleware errorHandlerMiddleware({
  bool showStackTrace = false,
}) {
  return (Handler next) {
    return (Request req) async {
      try {
        return await next(req);
      } on FormatException catch (e) {
        return Response.badRequest(e.message);
      } catch (e, stackTrace) {
        final message =
            showStackTrace ? 'Internal Server Error: $e\n\n$stackTrace' : 'Internal Server Error';

        return Response.internalServerError(message);
      }
    };
  };
}

/// Authentication middleware that checks for a valid token in the Authorization header
///
/// This is a simple example. In production, you would validate the token
/// against a database or JWT verification.
Middleware authMiddleware({
  required Future<dynamic> Function(String token) validateToken,
  String headerName = 'authorization',
}) {
  return (Handler next) {
    return (Request req) async {
      final authHeader = req.headers[headerName];

      if (authHeader == null) {
        return Response.unauthorized('Missing authorization header');
      }

      // Extract token (assuming "Bearer <token>" format)
      final parts = authHeader.split(' ');
      if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') {
        return Response.unauthorized('Invalid authorization header format');
      }

      final token = parts[1];

      try {
        final user = await validateToken(token);

        // Store authenticated user in request context for downstream handlers
        final newReq = req.copyWith(
          context: {...req.context, 'user': user},
        );

        return await next(newReq);
      } catch (e) {
        return Response.unauthorized('Invalid or expired token');
      }
    };
  };
}

/// Rate limiting middleware (simple in-memory implementation)
///
/// Note: This is a basic example. For production, you would use Redis or
/// a similar distributed cache.
Middleware rateLimitMiddleware({
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
}) {
  final requestCounts = <String, List<DateTime>>{};

  return (Handler next) {
    return (Request req) async {
      final clientId = req.headers['x-forwarded-for'] ?? req.headers['x-real-ip'] ?? 'unknown';

      final now = DateTime.now();
      final windowStart = now.subtract(window);

      // Clean up old entries
      requestCounts[clientId]?.removeWhere((time) => time.isBefore(windowStart));

      // Get current count
      final count = requestCounts[clientId]?.length ?? 0;

      if (count >= maxRequests) {
        return Response.json(
          {'error': 'Rate limit exceeded. Try again later.'},
          statusCode: 429,
          headers: {
            'retry-after': window.inSeconds.toString(),
          },
        );
      }

      // Record this request
      requestCounts.putIfAbsent(clientId, () => []).add(now);

      return await next(req);
    };
  };
}

/// Adds an id to every request and propagates it via headers and context.
Middleware requestIdMiddleware({
  String headerName = 'x-request-id',
  String contextKey = 'requestId',
  String Function()? generator,
}) {
  final rand = Random();
  String _defaultGen() =>
      '${DateTime.now().microsecondsSinceEpoch}-${rand.nextInt(1 << 32)}';
  final gen = generator ?? _defaultGen;

  return (Handler next) {
    return (Request req) async {
      final existing = req.headers[headerName.toLowerCase()];
      final requestId = existing ?? gen();

      final newReq = req.withContext(contextKey, requestId);
      final response = await next(newReq);

      return response.withHeaders({headerName: requestId});
    };
  };
}

/// Adds common security headers (baseline hardening).
Middleware securityHeadersMiddleware({
  String frameOptions = 'DENY',
  String xssProtection = '1; mode=block',
  String contentTypeOptions = 'nosniff',
  String referrerPolicy = 'no-referrer',
  String permissionsPolicy = 'geolocation=(), microphone=(), camera=()',
}) {
  return (Handler next) {
    return (Request req) async {
      final res = await next(req);
      return res.withHeaders({
        'x-frame-options': frameOptions,
        'x-xss-protection': xssProtection,
        'x-content-type-options': contentTypeOptions,
        'referrer-policy': referrerPolicy,
        'permissions-policy': permissionsPolicy,
      });
    };
  };
}

/// Captures metrics for each request.
class MetricsEvent {
  final String method;
  final String path;
  final int statusCode;
  final Duration duration;
  final int? responseBytes;

  MetricsEvent({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.duration,
    this.responseBytes,
  });
}

Middleware metricsMiddleware({
  required void Function(MetricsEvent event) onEvent,
}) {
  return (Handler next) {
    return (Request req) async {
      final sw = Stopwatch()..start();
      final res = await next(req);
      sw.stop();

      final event = MetricsEvent(
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        duration: sw.elapsed,
        responseBytes: res.bodyStream == null ? res.body.length : null,
      );
      onEvent(event);
      return res;
    };
  };
}

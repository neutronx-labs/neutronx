import 'package:neutronx/neutronx.dart';

/// A middleware is a function that wraps a Handler and returns a new Handler.
///
/// This follows the "Shelf-style" middleware pattern, enabling an onion-model
/// execution flow where middleware can:
/// - Execute code before the handler
/// - Call the next handler in the chain
/// - Execute code after the handler
/// - Modify the request or response
///
/// Example:
/// ```dart
/// Middleware loggingMiddleware = (Handler next) {
///   return (Request req) async {
///     print('${req.method} ${req.path}');
///     final response = await next(req);
///     print('Response: ${response.statusCode}');
///     return response;
///   };
/// };
/// ```
typedef Middleware = Handler Function(Handler next);

/// Utility class for creating and composing middleware
class MiddlewareUtils {
  /// Composes multiple middleware into a single middleware
  ///
  /// The middleware are applied in order, so the first middleware in the list
  /// will be the outermost layer.
  ///
  /// Example:
  /// ```dart
  /// final composed = MiddlewareUtils.compose([
  ///   loggingMiddleware,
  ///   corsMiddleware,
  ///   authMiddleware,
  /// ]);
  /// ```
  static Middleware compose(List<Middleware> middleware) {
    return (Handler next) {
      Handler handler = next;
      // Apply middleware in reverse order so the first middleware
      // in the list is the outermost layer
      for (var i = middleware.length - 1; i >= 0; i--) {
        handler = middleware[i](handler);
      }
      return handler;
    };
  }

  /// Creates a pipeline by wrapping a handler with multiple middleware
  ///
  /// This is a convenience method that composes middleware and applies them
  /// to a handler in one step.
  static Handler pipeline(Handler handler, List<Middleware> middleware) {
    final composed = compose(middleware);
    return composed(handler);
  }
}

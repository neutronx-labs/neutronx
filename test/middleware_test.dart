import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

void main() {
  group('Middleware', () {
    test('MiddlewareUtils.compose() composes multiple middleware', () async {
      final executionOrder = <String>[];

      Middleware middleware1 = (Handler next) {
        return (Request req) async {
          executionOrder.add('middleware1-before');
          final response = await next(req);
          executionOrder.add('middleware1-after');
          return response;
        };
      };

      Middleware middleware2 = (Handler next) {
        return (Request req) async {
          executionOrder.add('middleware2-before');
          final response = await next(req);
          executionOrder.add('middleware2-after');
          return response;
        };
      };

      Handler finalHandler = (Request req) async {
        executionOrder.add('handler');
        return Response.text('OK');
      };

      final composed = MiddlewareUtils.compose([middleware1, middleware2]);
      final wrappedHandler = composed(finalHandler);

      final mockReq = _MockRequest();
      await wrappedHandler(mockReq);

      // Onion model: middleware1 → middleware2 → handler → middleware2 → middleware1
      expect(
          executionOrder,
          equals([
            'middleware1-before',
            'middleware2-before',
            'handler',
            'middleware2-after',
            'middleware1-after',
          ]));
    });

    test('MiddlewareUtils.pipeline() creates handler with middleware', () async {
      var middlewareExecuted = false;

      Middleware testMiddleware = (Handler next) {
        return (Request req) async {
          middlewareExecuted = true;
          return await next(req);
        };
      };

      Handler handler = (Request req) async {
        return Response.text('OK');
      };

      final pipelined = MiddlewareUtils.pipeline(handler, [testMiddleware]);
      final mockReq = _MockRequest();
      await pipelined(mockReq);

      expect(middlewareExecuted, isTrue);
    });

    test('middleware can modify request context', () async {
      Middleware addUserMiddleware = (Handler next) {
        return (Request req) async {
          final newReq = req.copyWith(
            context: {...req.context, 'user': 'testuser'},
          );
          return await next(newReq);
        };
      };

      String? capturedUser;
      Handler handler = (Request req) async {
        capturedUser = req.context['user'] as String?;
        return Response.text('OK');
      };

      final wrappedHandler = addUserMiddleware(handler);
      final mockReq = _MockRequest();
      await wrappedHandler(mockReq);

      expect(capturedUser, equals('testuser'));
    });

    test('middleware can modify response', () async {
      Middleware addHeaderMiddleware = (Handler next) {
        return (Request req) async {
          final response = await next(req);
          return response.withHeaders({'x-custom': 'added-by-middleware'});
        };
      };

      Handler handler = (Request req) async {
        return Response.text('OK');
      };

      final wrappedHandler = addHeaderMiddleware(handler);
      final mockReq = _MockRequest();
      final response = await wrappedHandler(mockReq);

      expect(response.headers['x-custom'], equals('added-by-middleware'));
    });

    test('middleware can short-circuit the pipeline', () async {
      var handlerCalled = false;

      Middleware shortCircuitMiddleware = (Handler next) {
        return (Request req) async {
          // Don't call next, return immediately
          return Response.unauthorized('No access');
        };
      };

      Handler handler = (Request req) async {
        handlerCalled = true;
        return Response.text('OK');
      };

      final wrappedHandler = shortCircuitMiddleware(handler);
      final mockReq = _MockRequest();
      final response = await wrappedHandler(mockReq);

      expect(handlerCalled, isFalse);
      expect(response.statusCode, equals(401));
    });
  });

  group('Example Middleware', () {
    test('corsMiddleware() adds CORS headers', () async {
      final middleware = corsMiddleware();
      Handler handler = (Request req) async => Response.text('OK');

      final wrappedHandler = middleware(handler);
      final mockReq = _MockRequest();
      final response = await wrappedHandler(mockReq);

      expect(response.headers['access-control-allow-origin'], equals('*'));
      expect(response.headers['access-control-allow-methods'], isNotNull);
    });

    test('corsMiddleware() handles OPTIONS preflight', () async {
      final middleware = corsMiddleware();
      Handler handler = (Request req) async => Response.text('OK');

      final wrappedHandler = middleware(handler);
      final mockReq = _MockRequest(method: 'OPTIONS');
      final response = await wrappedHandler(mockReq);

      expect(response.statusCode, equals(204));
      expect(response.headers['access-control-allow-origin'], equals('*'));
    });

    test('errorHandlerMiddleware() catches exceptions', () async {
      final middleware = errorHandlerMiddleware();
      Handler handler = (Request req) async {
        throw Exception('Test error');
      };

      final wrappedHandler = middleware(handler);
      final mockReq = _MockRequest();
      final response = await wrappedHandler(mockReq);

      expect(response.statusCode, equals(500));
    });

    test('errorHandlerMiddleware() handles FormatException as 400', () async {
      final middleware = errorHandlerMiddleware();
      Handler handler = (Request req) async {
        throw FormatException('Invalid format');
      };

      final wrappedHandler = middleware(handler);
      final mockReq = _MockRequest();
      final response = await wrappedHandler(mockReq);

      expect(response.statusCode, equals(400));
    });
  });
}

// Factory function to create mock Request for testing
Request _MockRequest({String method = 'GET', Map<String, dynamic>? context}) {
  return Request.test(
    method: method,
    uri: Uri.parse('http://localhost/test'),
    path: '/test',
    context: context,
  );
}

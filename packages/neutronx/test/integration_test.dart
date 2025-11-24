import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

void main() {
  group('Integration Tests', () {
    late HttpServer? testServer;

    tearDown(() async {
      await testServer?.close();
      testServer = null;
    });

    test('full request/response lifecycle with middleware', () async {
      // Create app with middleware stack
      final app = NeutronApp();
      final router = Router();

      // Add test route
      router.get('/hello', (req) async {
        return Response.json({'message': 'Hello, World!'});
      });

      app.use(router);

      // Add logging middleware to track execution
      final executionLog = <String>[];
      app.useMiddleware([
        (Handler next) {
          return (Request req) async {
            executionLog.add('middleware-1-before');
            final response = await next(req);
            executionLog.add('middleware-1-after');
            return response;
          };
        },
        (Handler next) {
          return (Request req) async {
            executionLog.add('middleware-2-before');
            final response = await next(req);
            executionLog.add('middleware-2-after');
            return response;
          };
        },
      ]);

      // Start server on random port
      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      // Make real HTTP request
      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/hello');
      final response = await request.close();

      // Verify response
      expect(response.statusCode, equals(200));
      expect(response.headers.contentType?.mimeType, equals('application/json'));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['message'], equals('Hello, World!'));

      // Verify middleware execution order (onion model)
      expect(executionLog, equals([
        'middleware-1-before',
        'middleware-2-before',
        'middleware-2-after',
        'middleware-1-after',
      ]));

      client.close();
    });

    test('404 response for non-existent routes', () async {
      final app = NeutronApp();
      final router = Router();

      router.get('/exists', (req) async => Response.text('OK'));
      app.use(router);

      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/nonexistent');
      final response = await request.close();

      expect(response.statusCode, equals(404));
      client.close();
    });

    test('POST request with JSON body', () async {
      final app = NeutronApp();
      final router = Router();

      Map<String, dynamic>? receivedData;
      router.post('/data', (req) async {
        receivedData = await req.json();
        return Response.json({'received': receivedData});
      });

      app.use(router);
      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.post('127.0.0.1', port, '/data');
      request.headers.contentType = ContentType.json;
      
      final testData = {'name': 'John', 'age': 30};
      request.write(jsonEncode(testData));
      
      final response = await request.close();
      expect(response.statusCode, equals(200));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['received']['name'], equals('John'));
      expect(json['received']['age'], equals(30));
      expect(receivedData, equals(testData));

      client.close();
    });

    test('path parameters are extracted correctly', () async {
      final app = NeutronApp();
      final router = Router();

      String? capturedId;
      router.get('/users/:id', (req) async {
        capturedId = req.params['id'];
        return Response.json({'userId': capturedId});
      });

      app.use(router);
      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/users/123');
      final response = await request.close();

      expect(response.statusCode, equals(200));
      expect(capturedId, equals('123'));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['userId'], equals('123'));

      client.close();
    });

    test('query parameters are parsed', () async {
      final app = NeutronApp();
      final router = Router();

      Map<String, String>? capturedQuery;
      router.get('/search', (req) async {
        capturedQuery = req.query;
        return Response.json(capturedQuery);
      });

      app.use(router);
      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/search?q=test&page=2');
      final response = await request.close();

      expect(response.statusCode, equals(200));
      expect(capturedQuery?['q'], equals('test'));
      expect(capturedQuery?['page'], equals('2'));

      client.close();
    });

    test('middleware can modify request context', () async {
      final app = NeutronApp();
      final router = Router();

      String? capturedUser;
      router.get('/protected', (req) async {
        capturedUser = req.context['user'] as String?;
        return Response.json({'user': capturedUser});
      });

      app.use(router);

      // Middleware adds user to context
      app.useMiddleware([
        (Handler next) {
          return (Request req) async {
            final newReq = req.copyWith(
              context: {...req.context, 'user': 'testuser'},
            );
            return await next(newReq);
          };
        },
      ]);

      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/protected');
      final response = await request.close();

      expect(response.statusCode, equals(200));
      expect(capturedUser, equals('testuser'));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['user'], equals('testuser'));

      client.close();
    });

    test('error handler middleware catches exceptions', () async {
      final app = NeutronApp();
      final router = Router();

      router.get('/error', (req) async {
        throw Exception('Test error');
      });

      app.use(router);
      app.useMiddleware([errorHandlerMiddleware()]);

      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/error');
      final response = await request.close();

      expect(response.statusCode, equals(500));
      client.close();
    });

    test('CORS middleware adds headers', () async {
      final app = NeutronApp();
      final router = Router();

      router.get('/test', (req) async => Response.text('OK'));
      app.use(router);
      app.useMiddleware([corsMiddleware()]);

      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/test');
      final response = await request.close();

      expect(response.statusCode, equals(200));
      expect(
        response.headers.value('access-control-allow-origin'),
        equals('*'),
      );

      client.close();
    });

    test('nested routers with mount()', () async {
      final app = NeutronApp();
      final mainRouter = Router();
      final apiRouter = Router();

      apiRouter.get('/users', (req) async {
        return Response.json({'users': []});
      });

      mainRouter.mount('/api', apiRouter);
      app.use(mainRouter);

      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/api/users');
      final response = await request.close();

      expect(response.statusCode, equals(200));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['users'], isA<List>());

      client.close();
    });

    test('DI container integration', () async {
      final app = NeutronApp();
      final router = Router();

      // Register service in container
      app.container.registerSingleton<String>('test-service-value');

      router.get('/service', (req) async {
        final value = app.container.get<String>();
        return Response.json({'value': value});
      });

      app.use(router);
      testServer = await app.listen(host: '127.0.0.1', port: 0);
      final port = testServer!.port;

      final client = HttpClient();
      final request = await client.get('127.0.0.1', port, '/service');
      final response = await request.close();

      expect(response.statusCode, equals(200));

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      expect(json['value'], equals('test-service-value'));

      client.close();
    });
  });
}

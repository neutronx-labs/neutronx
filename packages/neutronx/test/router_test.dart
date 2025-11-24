import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

void main() {
  group('Router', () {
    late Router router;

    setUp(() {
      router = Router();
    });

    test('get() registers GET route', () async {
      router.get('/test', (req) async => Response.text('GET response'));

      final mockReq = _MockRequest(method: 'GET', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('post() registers POST route', () async {
      router.post('/test', (req) async => Response.text('POST response'));

      final mockReq = _MockRequest(method: 'POST', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('put() registers PUT route', () async {
      router.put('/test', (req) async => Response.text('PUT response'));

      final mockReq = _MockRequest(method: 'PUT', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('delete() registers DELETE route', () async {
      router.delete('/test', (req) async => Response.text('DELETE response'));

      final mockReq = _MockRequest(method: 'DELETE', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('patch() registers PATCH route', () async {
      router.patch('/test', (req) async => Response.text('PATCH response'));

      final mockReq = _MockRequest(method: 'PATCH', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('any() registers route for all methods', () async {
      router.any('/test', (req) async => Response.text('ANY response'));

      for (final method in ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']) {
        final mockReq = _MockRequest(method: method, path: '/test');
        final response = await router.handler(mockReq);
        expect(response.statusCode, equals(200), reason: 'Failed for $method');
      }
    });

    test('routes return 404 for non-matching paths', () async {
      router.get('/test', (req) async => Response.text('OK'));

      final mockReq = _MockRequest(method: 'GET', path: '/notfound');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(404));
    });

    test('routes return 405 for non-matching methods', () async {
      router.get('/test', (req) async => Response.text('OK'));

      final mockReq = _MockRequest(method: 'POST', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(405));
    });

    test('extracts path parameters from :param syntax', () async {
      String? capturedId;

      router.get('/users/:id', (req) async {
        capturedId = req.params['id'];
        return Response.text('OK');
      });

      final mockReq = _MockRequest(method: 'GET', path: '/users/123');
      await router.handler(mockReq);

      expect(capturedId, equals('123'));
    });

    test('extracts multiple path parameters', () async {
      Map<String, String>? capturedParams;

      router.get('/users/:userId/posts/:postId', (req) async {
        capturedParams = req.params;
        return Response.text('OK');
      });

      final mockReq = _MockRequest(method: 'GET', path: '/users/123/posts/456');
      await router.handler(mockReq);

      expect(capturedParams?['userId'], equals('123'));
      expect(capturedParams?['postId'], equals('456'));
    });

    test('static segments must match exactly', () async {
      router.get('/users/active', (req) async => Response.text('OK'));

      final mockReq1 = _MockRequest(method: 'GET', path: '/users/active');
      final response1 = await router.handler(mockReq1);
      expect(response1.statusCode, equals(200));

      final mockReq2 = _MockRequest(method: 'GET', path: '/users/inactive');
      final response2 = await router.handler(mockReq2);
      expect(response2.statusCode, equals(404));
    });

    test('mount() nests routers', () async {
      final subRouter = Router();
      subRouter.get('/test', (req) async => Response.text('Sub response'));

      router.mount('/api', subRouter);

      final mockReq = _MockRequest(method: 'GET', path: '/api/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('mounted routers have precedence over local routes', () async {
      final subRouter = Router();
      subRouter.get('/test', (req) async => Response.text('Sub response'));

      router.mount('/api', subRouter);
      router.get('/api/test', (req) async => Response.text('Local response'));

      final mockReq = _MockRequest(method: 'GET', path: '/api/test');
      final response = await router.handler(mockReq);

      // Sub router should handle it
      expect(response.statusCode, equals(200));
    });

    test('mount() strips prefix from path', () async {
      String? capturedPath;

      final subRouter = Router();
      subRouter.get('/users', (req) async {
        capturedPath = req.path;
        return Response.text('OK');
      });

      router.mount('/api', subRouter);

      final mockReq = _MockRequest(method: 'GET', path: '/api/users');
      await router.handler(mockReq);

      expect(capturedPath, equals('/users'));
    });

    test('routes property returns registered routes', () {
      router.get('/users', (req) async => Response.text('OK'));
      router.post('/users', (req) async => Response.text('OK'));

      final routes = router.routes;

      expect(routes.length, equals(2));
      expect(routes, contains('GET /users'));
      expect(routes, contains('POST /users'));
    });

    test('handles trailing slashes in mount prefix', () async {
      final subRouter = Router();
      subRouter.get('/test', (req) async => Response.text('OK'));

      router.mount('/api/', subRouter); // Trailing slash

      final mockReq = _MockRequest(method: 'GET', path: '/api/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('handles missing leading slash in paths', () async {
      router.get('test', (req) async => Response.text('OK')); // No leading slash

      final mockReq = _MockRequest(method: 'GET', path: '/test');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
    });

    test('responds to OPTIONS with Allow header', () async {
      router.get('/opts', (req) async => Response.text('OK'));

      final mockReq = _MockRequest(method: 'OPTIONS', path: '/opts');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(204));
      expect(response.headers['allow'], contains('GET'));
      expect(response.headers['allow'], contains('HEAD'));
    });

    test('HEAD falls back to GET handler without body', () async {
      router.get('/head', (req) async => Response.text('BODY'));

      final mockReq = _MockRequest(method: 'HEAD', path: '/head');
      final response = await router.handler(mockReq);

      expect(response.statusCode, equals(200));
      expect(response.body.isEmpty, isTrue);
    });
  });
}

// Factory function to create mock Request for testing
Request _MockRequest({String method = 'GET', String path = '/'}) {
  return Request.test(
    method: method,
    uri: Uri.parse('http://localhost$path'),
    path: path,
  );
}

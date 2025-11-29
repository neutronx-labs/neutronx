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

  group('WebSocket routing', () {
    late Router router;

    setUp(() {
      router = Router();
    });

    test('ws() registers a WebSocket route', () {
      router.ws('/ws', (session) async {});

      final routes = router.routes;
      expect(routes, contains('WS /ws'));
    });

    test('ws() normalizes path by adding leading slash', () {
      router.ws('ws', (session) async {});

      final routes = router.routes;
      expect(routes, contains('WS /ws'));
    });

    test('ws() normalizes path by removing trailing slash', () {
      router.ws('/ws/', (session) async {});

      final routes = router.routes;
      expect(routes, contains('WS /ws'));
    });

    test('ws() supports path parameters with colon syntax', () {
      router.ws('/ws/:id', (session) async {});

      final routes = router.routes;
      expect(routes, contains('WS /ws/:id'));
    });

    test('ws() throws StateError for duplicate routes', () {
      router.ws('/ws', (session) async {});

      expect(
        () => router.ws('/ws', (session) async {}),
        throwsStateError,
      );
    });

    test('matchWebSocket() returns null for non-matching paths', () {
      router.ws('/ws', (session) async {});

      final match = router.matchWebSocket('/notfound');
      expect(match, isNull);
    });

    test('matchWebSocket() matches static route', () {
      router.ws('/ws', (session) async {});

      final match = router.matchWebSocket('/ws');
      expect(match, isNotNull);
      expect(match!.path, equals('/ws'));
      expect(match.params, isEmpty);
    });

    test('matchWebSocket() matches dynamic route and extracts params', () {
      router.ws('/ws/:id', (session) async {});

      final match = router.matchWebSocket('/ws/123');
      expect(match, isNotNull);
      expect(match!.params['id'], equals('123'));
    });

    test('matchWebSocket() extracts multiple path parameters', () {
      router.ws('/chat/:room/:user', (session) async {});

      final match = router.matchWebSocket('/chat/lobby/john');
      expect(match, isNotNull);
      expect(match!.params['room'], equals('lobby'));
      expect(match.params['user'], equals('john'));
    });

    test('matchWebSocket() normalizes path by adding leading slash', () {
      router.ws('/ws', (session) async {});

      final match = router.matchWebSocket('ws');
      expect(match, isNotNull);
      expect(match!.path, equals('/ws'));
    });

    test('matchWebSocket() normalizes path by removing trailing slash', () {
      router.ws('/ws', (session) async {});

      final match = router.matchWebSocket('/ws/');
      expect(match, isNotNull);
      expect(match!.path, equals('/ws'));
    });

    test('matchWebSocket() works with mounted routers', () {
      final apiRouter = Router();
      apiRouter.ws('/events', (session) async {});

      router.mount('/api', apiRouter);

      final match = router.matchWebSocket('/api/events');
      expect(match, isNotNull);
      expect(match!.path, equals('/events'));
    });

    test('matchWebSocket() with mounted routers extracts params', () {
      final apiRouter = Router();
      apiRouter.ws('/stream/:channel', (session) async {});

      router.mount('/api', apiRouter);

      final match = router.matchWebSocket('/api/stream/updates');
      expect(match, isNotNull);
      expect(match!.params['channel'], equals('updates'));
    });

    test('matchWebSocket() prioritizes static over dynamic segments', () {
      router.ws('/ws/status', (session) async {});
      router.ws('/ws/:id', (session) async {});

      final staticMatch = router.matchWebSocket('/ws/status');
      expect(staticMatch, isNotNull);
      expect(staticMatch!.path, equals('/ws/status'));
      expect(staticMatch.params, isEmpty);

      final dynamicMatch = router.matchWebSocket('/ws/123');
      expect(dynamicMatch, isNotNull);
      expect(dynamicMatch!.params['id'], equals('123'));
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

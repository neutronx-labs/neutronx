import 'dart:convert';
import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

void main() {
  group('Response', () {
    test('text() creates text response with correct headers', () {
      final response = Response.text('Hello World');

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('text/plain; charset=utf-8'));
      expect(utf8.decode(response.body), equals('Hello World'));
    });

    test('text() accepts custom status code', () {
      final response = Response.text('Created', statusCode: 201);
      expect(response.statusCode, equals(201));
    });

    test('json() creates JSON response with correct headers', () {
      final response = Response.json({'message': 'Hello'});

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/json; charset=utf-8'));

      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['message'], equals('Hello'));
    });

    test('json() encodes list correctly', () {
      final response = Response.json([1, 2, 3]);
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded, equals([1, 2, 3]));
    });

    test('bytes() creates binary response', () {
      final bytes = [1, 2, 3, 4, 5];
      final response = Response.bytes(bytes);

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/octet-stream'));
      expect(response.body, equals(bytes));
    });

    test('redirect() creates redirect response', () {
      final response = Response.redirect('/new-location');

      expect(response.statusCode, equals(302));
      expect(response.headers['location'], equals('/new-location'));
      expect(response.body, isEmpty);
    });

    test('redirect() accepts custom status code', () {
      final response = Response.redirect('/moved', statusCode: 301);
      expect(response.statusCode, equals(301));
    });

    test('empty() creates empty response', () {
      final response = Response.empty();

      expect(response.statusCode, equals(204));
      expect(response.body, isEmpty);
    });

    test('html() creates HTML response', () {
      final response = Response.html('<h1>Hello</h1>');

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('text/html; charset=utf-8'));
      expect(utf8.decode(response.body), equals('<h1>Hello</h1>'));
    });

    test('notFound() creates 404 response', () {
      final response = Response.notFound();

      expect(response.statusCode, equals(404));
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('Not Found'));
    });

    test('notFound() accepts custom message', () {
      final response = Response.notFound('User not found');
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('User not found'));
    });

    test('badRequest() creates 400 response', () {
      final response = Response.badRequest('Invalid input');

      expect(response.statusCode, equals(400));
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('Invalid input'));
    });

    test('unauthorized() creates 401 response', () {
      final response = Response.unauthorized();

      expect(response.statusCode, equals(401));
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('Unauthorized'));
    });

    test('forbidden() creates 403 response', () {
      final response = Response.forbidden();

      expect(response.statusCode, equals(403));
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('Forbidden'));
    });

    test('internalServerError() creates 500 response', () {
      final response = Response.internalServerError();

      expect(response.statusCode, equals(500));
      final decoded = jsonDecode(utf8.decode(response.body));
      expect(decoded['error'], equals('Internal Server Error'));
    });

    test('copyWith() creates new response with updated status', () {
      final original = Response.text('Hello');
      final updated = original.copyWith(statusCode: 201);

      expect(updated.statusCode, equals(201));
      expect(original.statusCode, equals(200)); // Original unchanged
      expect(utf8.decode(updated.body), equals('Hello'));
    });

    test('copyWith() creates new response with updated headers', () {
      final original = Response.text('Hello');
      final updated = original.copyWith(
        headers: {'x-custom': 'value'},
      );

      expect(updated.headers['x-custom'], equals('value'));
      expect(updated.headers['content-type'], isNull); // Old headers replaced
    });

    test('withHeaders() merges additional headers', () {
      final original = Response.text('Hello');
      final updated = original.withHeaders({'x-custom': 'value'});

      expect(updated.headers['x-custom'], equals('value'));
      expect(updated.headers['content-type'],
          equals('text/plain; charset=utf-8')); // Original preserved
    });

    test('withHeaders() overwrites existing headers', () {
      final original = Response.text('Hello');
      final updated = original.withHeaders({'content-type': 'text/custom'});

      expect(updated.headers['content-type'], equals('text/custom'));
    });

    test('stream() creates streaming response without buffering', () {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('chunk1'),
        utf8.encode('chunk2'),
      ]);

      final response = Response.stream(stream, contentType: 'text/plain');

      expect(response.bodyStream, isNotNull);
      expect(response.body, isEmpty);
      expect(response.headers['content-type'], equals('text/plain'));
    });
  });
}

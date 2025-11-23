import 'dart:convert';
import 'package:test/test.dart';
import 'package:neutronx/neutronx.dart';

void main() {
  group('Request', () {
    test('test constructor creates Request with all properties', () {
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost:3000/users/123?filter=active'),
        path: '/users/123',
        params: {'id': '123'},
        query: {'filter': 'active'},
        headers: {'content-type': 'application/json'},
        context: {'user': 'testuser'},
      );

      expect(request.method, equals('POST'));
      expect(request.uri.toString(), equals('http://localhost:3000/users/123?filter=active'));
      expect(request.path, equals('/users/123'));
      expect(request.params['id'], equals('123'));
      expect(request.query['filter'], equals('active'));
      expect(request.headers['content-type'], equals('application/json'));
      expect(request.context['user'], equals('testuser'));
    });

    test('test constructor has default values', () {
      final request = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/'),
        path: '/',
      );

      expect(request.params, isEmpty);
      expect(request.query, isEmpty);
      expect(request.headers, isEmpty);
      expect(request.cookies, isEmpty);
      expect(request.context, isEmpty);
    });

    test('bodyBytes() returns cached body bytes', () async {
      final bodyData = utf8.encode('test body');
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        bodyBytes: bodyData,
      );

      final bytes = await request.bodyBytes();
      expect(bytes, equals(bodyData));

      // Second call should return cached value
      final bytes2 = await request.bodyBytes();
      expect(bytes2, equals(bodyData));
      expect(bytes2, same(bytes));
    });

    test('body() decodes bodyBytes as UTF-8 string', () async {
      final bodyData = utf8.encode('Hello World');
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        bodyBytes: bodyData,
      );

      final body = await request.body();
      expect(body, equals('Hello World'));
    });

    test('json() parses JSON body', () async {
      final jsonData = {'name': 'John', 'age': 30};
      final bodyData = utf8.encode(jsonEncode(jsonData));
      
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        bodyBytes: bodyData,
      );

      final parsed = await request.json();
      expect(parsed['name'], equals('John'));
      expect(parsed['age'], equals(30));
    });

    test('json() caches parsed result', () async {
      final jsonData = {'name': 'John'};
      final bodyData = utf8.encode(jsonEncode(jsonData));
      
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        bodyBytes: bodyData,
      );

      final parsed1 = await request.json();
      final parsed2 = await request.json();
      
      expect(parsed1, same(parsed2));
    });

    test('copyWith() creates new Request with updated path', () {
      final original = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/old'),
        path: '/old',
      );

      final updated = original.copyWith(path: '/new');

      expect(updated.path, equals('/new'));
      expect(original.path, equals('/old'));
      expect(updated.method, equals(original.method));
    });

    test('copyWith() creates new Request with updated params', () {
      final original = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/users'),
        path: '/users',
        params: {'old': 'value'},
      );

      final updated = original.copyWith(params: {'id': '123'});

      expect(updated.params['id'], equals('123'));
      expect(updated.params.containsKey('old'), isFalse);
    });

    test('copyWith() creates new Request with updated context', () {
      final original = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        context: {'key1': 'value1'},
      );

      final updated = original.copyWith(
        context: {...original.context, 'key2': 'value2'},
      );

      expect(updated.context['key1'], equals('value1'));
      expect(updated.context['key2'], equals('value2'));
      expect(original.context.containsKey('key2'), isFalse);
    });

    test('contentType getter returns content-type header', () {
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        headers: {'content-type': 'application/json'},
      );

      expect(request.contentType, equals('application/json'));
    });

    test('authorization getter returns authorization header', () {
      final request = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        headers: {'authorization': 'Bearer token123'},
      );

      expect(request.authorization, equals('Bearer token123'));
    });

    test('isJson returns true for JSON content-type', () {
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      expect(request.isJson, isTrue);
    });

    test('isForm returns true for form content-type', () {
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      expect(request.isForm, isTrue);
    });

    test('isMultipart returns true for multipart content-type', () {
      final request = Request.test(
        method: 'POST',
        uri: Uri.parse('http://localhost/test'),
        path: '/test',
        headers: {'content-type': 'multipart/form-data; boundary=----'},
      );

      expect(request.isMultipart, isTrue);
    });

    test('toString() returns readable representation', () {
      final request = Request.test(
        method: 'GET',
        uri: Uri.parse('http://localhost/users'),
        path: '/users',
      );

      expect(request.toString(), equals('Request(GET /users)'));
    });
  });
}

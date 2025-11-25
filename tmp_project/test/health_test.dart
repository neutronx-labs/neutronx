import 'dart:convert';
import 'package:neutronx/neutronx.dart';
import 'package:test/test.dart';

void main() {
  test('health endpoint responds with ok', () async {
    final router = Router();
    router.get('/health', (req) async {
      return Response.json({'status': 'ok'});
    });

    final response = await router.handler(Request.test(
      method: 'GET',
      uri: Uri.parse('http://localhost/health'),
      path: '/health',
    ));

    expect(response.statusCode, equals(200));
    final body = jsonDecode(utf8.decode(response.body));
    expect(body['status'], equals('ok'));
  });
}

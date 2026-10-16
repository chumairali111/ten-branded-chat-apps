import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whatsapp_clone_client/core/api_client.dart';

void main() {
  test('media credentials stay in headers, not URL query', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient((request) async {
        sent = request;
        return http.Response.bytes([1, 2, 3], 200);
      }),
    )..token = 'private-session';
    expect(await api.downloadBytes('files/media-id'), [1, 2, 3]);
    expect(sent.headers['Authorization'], 'Bearer private-session');
    expect(sent.url.query, isEmpty);
    api.close();
  });
  test('delete-for-everyone retains its scope query', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: 'https://example.test/api',
      client: MockClient((request) async {
        sent = request;
        return http.Response('{"ok":true}', 200);
      }),
    );
    await api.delete('messages/8?scope=everyone');
    expect(sent.url.queryParameters['scope'], 'everyone');
    api.close();
  });
}

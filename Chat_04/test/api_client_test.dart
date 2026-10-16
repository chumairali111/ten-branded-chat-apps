import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whatsapp_clone_client/core/api_client.dart';

void main() {
  group('ApiClient', () {
    test(
      'uses configured API base and sends CSRF and bearer credentials',
      () async {
        late http.Request sent;
        final client =
            ApiClient(
                baseUrl: 'https://chat.example.test/api',
                client: MockClient((request) async {
                  sent = request;
                  return http.Response(jsonEncode({'ok': true}), 200);
                }),
              )
              ..csrf = 'csrf-value'
              ..token = 'session-value';

        final response = await client.post('chats/12/read');

        expect(response['ok'], isTrue);
        expect(
          sent.url.toString(),
          'https://chat.example.test/api/chats/12/read',
        );
        expect(sent.headers['X-CSRF-Token'], 'csrf-value');
        expect(sent.headers['Authorization'], 'Bearer session-value');
      },
    );

    test('surfaces structured server errors', () async {
      final client = ApiClient(
        baseUrl: 'https://chat.example.test',
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': 'Chat is locked'}), 423),
        ),
      );

      await expectLater(
        client.get('chats/3/messages'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 423)
              .having((error) => error.message, 'message', 'Chat is locked'),
        ),
      );
    });
  });
}

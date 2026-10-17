import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:whatsapp_clone_client/core/api_client.dart';
import 'package:whatsapp_clone_client/core/app_controller.dart';
import 'package:whatsapp_clone_client/core/session_store.dart';

class _MemorySessionStore implements SessionStore {
  String? token;
  String? csrf;

  @override
  Future<(String, String)?> read() async =>
      token == null || csrf == null ? null : (token!, csrf!);

  @override
  Future<void> write(String token, String csrf) async {
    this.token = token;
    this.csrf = csrf;
  }

  @override
  Future<void> clear() async {
    token = null;
    csrf = null;
  }
}

void main() {
  test(
    'authentication persists native credentials and loads chat state',
    () async {
      final store = _MemorySessionStore();
      final api = ApiClient(
        baseUrl: 'https://chat.example.test/api',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) {
            return http.Response(
              jsonEncode({
                'user': {'id': 7, 'username': 'umair', 'name': 'Umair'},
                'csrf': 'csrf',
                'token': 'native-token',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/chats')) {
            return http.Response(jsonEncode({'chats': []}), 200);
          }
          return http.Response(
            jsonEncode({'error': 'Unexpected request'}),
            404,
          );
        }),
      );
      final controller = AppController(api: api, store: store);

      await controller.authenticate('umair', 'Password123!');

      expect(controller.user?['name'], 'Umair');
      expect(store.token, 'native-token');
      expect(store.csrf, 'csrf');
      expect(controller.chats, isEmpty);
      controller.dispose();
    },
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  const SessionStore();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'messaging.session.token';
  static const _csrfKey = 'messaging.session.csrf';

  Future<(String, String)?> read() async {
    if (kIsWeb) return null;
    final token = await _storage.read(key: _tokenKey);
    final csrf = await _storage.read(key: _csrfKey);
    if (token == null || csrf == null) return null;
    return (token, csrf);
  }

  Future<void> write(String token, String csrf) async {
    if (kIsWeb) return;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _csrfKey, value: csrf);
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _csrfKey);
  }
}

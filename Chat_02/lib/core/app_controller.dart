import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'session_store.dart';

class AppController extends ChangeNotifier {
  AppController({ApiClient? api, SessionStore? store})
    : api = api ?? ApiClient(),
      store = store ?? const SessionStore();

  final ApiClient api;
  final SessionStore store;
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> messages = [];
  Map<String, dynamic>? activeChat;
  String activeSection = 'chats';
  String chatFilter = 'all';
  bool loading = true;
  String? error;
  Timer? _poller;

  bool get signedIn => user != null;

  Future<void> initialize() async {
    try {
      final saved = await store.read();
      if (saved != null) {
        api.token = saved.$1;
        api.csrf = saved.$2;
      }
      final result = await api.get('me');
      user = Map<String, dynamic>.from(result['user'] as Map);
      api.csrf = result['csrf'] as String?;
      await refreshChats();
      _startPolling();
    } on ApiException catch (exception) {
      if (exception.statusCode != 401) error = exception.message;
      user = null;
    } catch (exception) {
      error = 'Could not connect to the messaging server: $exception';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> authenticate(
    String username,
    String password, {
    String? name,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'password': password,
      'device_name': defaultTargetPlatform.name,
      'platform': _platform,
      if (name != null) 'name': name,
    };
    final result = name == null
        ? await api.post('login', body)
        : await api.post('register', body);
    await _setSession(result);
    await refreshChats();
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!signedIn) return;
      unawaited(refreshChats(silent: true));
      final id = activeChat?['id'];
      if (id is int) unawaited(openChat(id, silent: true));
    });
  }

  Future<void> _setSession(Map<String, dynamic> result) async {
    user = Map<String, dynamic>.from(result['user'] as Map);
    api.csrf = result['csrf'] as String?;
    api.token = result['token'] as String?;
    if (api.token != null && api.csrf != null) {
      await store.write(api.token!, api.csrf!);
    }
    error = null;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'android';
    }
  }

  Future<void> refreshChats({bool silent = false}) async {
    if (!silent) {
      error = null;
      notifyListeners();
    }
    try {
      final result = await api.get('chats');
      chats = (result['chats'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (activeChat != null &&
          !chats.any((chat) => chat['id'] == activeChat!['id'])) {
        activeChat = null;
        messages = [];
      }
      if (!silent) error = null;
    } catch (exception) {
      error = exception.toString();
    }
    notifyListeners();
  }

  Future<void> openChat(int id, {bool silent = false}) async {
    if (silent && activeChat?['id'] != id) return;
    try {
      final detail = await api.get('chats/$id');
      if (silent && activeChat?['id'] != id) return;
      activeChat = detail;
      final result = await api.get('chats/$id/messages');
      if (activeChat?['id'] != id) return;
      messages = (result['messages'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      await api.post('chats/$id/read');
      error = null;
    } on ApiException catch (exception) {
      error = exception.toString();
      if (exception.statusCode == 423) {
        activeChat = null;
        messages = [];
      }
    } catch (exception) {
      error = exception.toString();
    }
    notifyListeners();
  }

  void closeChat() {
    activeChat = null;
    messages = [];
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final result = await api.get('me');
    user = Map<String, dynamic>.from(result['user'] as Map);
    notifyListeners();
  }

  Future<void> sendMessage(String text, {int? replyId}) async {
    final chat = activeChat;
    if (chat == null || text.trim().isEmpty) return;
    await api.post('chats/${chat['id']}/messages', {
      'body': text.trim(),
      if (replyId != null) 'reply_id': replyId,
    });
    await openChat(chat['id'] as int);
    await refreshChats(silent: true);
  }

  Future<void> sendAttachment(String filename, List<int> bytes) async {
    final chat = activeChat;
    if (chat == null) return;
    final file = await api.upload('chats/${chat['id']}/files', filename, bytes);
    final ext = filename.split('.').last.toLowerCase();
    final kind = const {'png', 'jpg', 'jpeg', 'gif', 'webp'}.contains(ext)
        ? 'image'
        : const {'mp4', 'mov', 'webm'}.contains(ext)
        ? 'video'
        : const {'mp3', 'wav', 'ogg', 'm4a', 'aac'}.contains(ext)
        ? 'audio'
        : 'document';
    await api.post('chats/${chat['id']}/messages', {
      'file_id': file['id'],
      'kind': kind,
      'body': '',
    });
    await openChat(chat['id'] as int);
    await refreshChats(silent: true);
  }

  Future<Map<String, dynamic>> createChat({
    required List<int> members,
    String kind = 'direct',
    String? title,
  }) async {
    final result = await api.post('chats', {
      'kind': kind,
      'members': members,
      if (title != null) 'title': title,
    });
    await refreshChats();
    return result;
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await api.get('users', query: {'q': query});
    return (response['users'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> updatePreference(int id, String key, bool value) async {
    await api.patch('chats/$id/preferences', {key: value});
    await refreshChats(silent: true);
    if (activeChat?['id'] == id) await openChat(id);
  }

  Future<void> updateChatSettings(int id, Map<String, dynamic> values) async {
    final path = activeChat?['kind'] == 'group'
        ? 'groups/$id'
        : 'chats/$id/settings';
    await api.patch(path, values);
    await openChat(id);
  }

  Future<void> logout() async {
    try {
      await api.post('logout');
    } finally {
      await store.clear();
      api.token = null;
      api.csrf = null;
      _poller?.cancel();
      _poller = null;
      user = null;
      activeChat = null;
      chats = [];
      messages = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createPairing(String deviceName) async =>
      api.post('device-pairings', {
        'device_name': deviceName,
        'platform': _platform,
      });

  Future<Map<String, dynamic>> pollPairing(String id, String secret) =>
      api.post('device-pairings/$id/poll', {'secret': secret});

  Future<void> approvePairing(String id, String secret) async {
    await api.post('device-pairings/$id/approve', {'secret': secret});
  }

  Future<Map<String, dynamic>> pairingDetails(String id, String secret) =>
      api.post('device-pairings/$id/details', {'secret': secret});

  Future<void> acceptPairedSession(Map<String, dynamic> result) async {
    await _setSession(result);
    await refreshChats();
    _startPolling();
    notifyListeners();
  }

  Future<void> cancelPairing(String id, String secret) async {
    await api.post('device-pairings/$id/cancel', {'secret': secret});
  }

  @override
  void dispose() {
    _poller?.cancel();
    api.close();
    super.dispose();
  }
}

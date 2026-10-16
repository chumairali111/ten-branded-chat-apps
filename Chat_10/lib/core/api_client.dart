import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'http_client_factory_stub.dart'
    if (dart.library.html) 'http_client_factory_web.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : _client = client ?? createHttpClient(),
      baseUrl = _resolveBaseUrl(baseUrl);

  final http.Client _client;
  final Uri baseUrl;
  String? token;
  String? csrf;

  static Uri _resolveBaseUrl(String? configured) {
    final value = configured ?? const String.fromEnvironment('API_BASE_URL');
    if (value.isNotEmpty) {
      final parsed = Uri.parse(value.trim());
      if (!parsed.hasAuthority || parsed.host.isEmpty || !['http', 'https'].contains(parsed.scheme) || parsed.userInfo.isNotEmpty || parsed.hasQuery || parsed.hasFragment) {
        throw const FormatException('Enter a valid server URL, without passwords or query parameters');
      }
      if (kReleaseMode && parsed.scheme != 'https') {
        throw const FormatException('Public release builds require an HTTPS server');
      }
      final path = parsed.path.replaceFirst(RegExp(r'/+$'), '');
      return parsed.replace(
        path: path.endsWith('/api') ? '$path/' : '$path/api/',
      );
    }
    if (kIsWeb) return Uri.base.resolve('/api/');
    if (kReleaseMode) throw const FormatException('Configure your public HTTPS server first');
    return Uri.parse('http://10.0.2.2:5000/api/');
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final uri = baseUrl.resolve(normalized);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _request('POST', path, body: body ?? const {});

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> upload(
    String path,
    String filename,
    List<int> bytes,
  ) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (csrf != null) request.headers['X-CSRF-Token'] = csrf!;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (!kIsWeb) request.headers['X-Client'] = 'flutter-native';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 60)),
    );
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      data = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Upload failed (${response.statusCode})',
        response.statusCode,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (csrf != null) 'X-CSRF-Token': csrf!,
      if (token != null) 'Authorization': 'Bearer $token',
      if (!kIsWeb) 'X-Client': 'flutter-native',
    };
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      data = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Request failed (${response.statusCode})',
        response.statusCode,
      );
    }
    return data;
  }

  Uri mediaUri(String path) => _uri(path);

  Map<String, String> get mediaHeaders => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<int>> downloadBytes(String path) async {
    final response = await _client.get(_uri(path), headers: mediaHeaders).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw ApiException(
        'Media unavailable (${response.statusCode})',
        response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}

// Web media uses authenticated fetch + a local blob URL, never session tokens in URLs.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import '../../core/api_client.dart';

class MediaSource {
  MediaSource(this.url);
  final String url;
  Map<String, String> get headers => const {};
  void dispose() => html.Url.revokeObjectUrl(url);
}

Future<MediaSource> loadMediaSource(
  ApiClient api,
  String path,
  String mime,
) async {
  final bytes = await api.downloadBytes(path);
  return MediaSource(
    html.Url.createObjectUrlFromBlob(
      html.Blob([Uint8List.fromList(bytes)], mime),
    ),
  );
}

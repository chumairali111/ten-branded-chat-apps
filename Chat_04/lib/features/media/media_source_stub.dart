import '../../core/api_client.dart';

class MediaSource {
  MediaSource(this.url, this.headers);
  final String url;
  final Map<String, String> headers;
  void dispose() {}
}

Future<MediaSource> loadMediaSource(
  ApiClient api,
  String path,
  String mime,
) async => MediaSource(api.mediaUri(path).toString(), api.mediaHeaders);

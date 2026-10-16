import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import 'media_source_stub.dart' if (dart.library.html) 'media_source_web.dart';

class MediaPreview extends StatefulWidget {
  const MediaPreview({
    required this.api,
    required this.path,
    required this.kind,
    this.name = '',
    this.mime = 'application/octet-stream',
    super.key,
  });
  final ApiClient api;
  final String path, kind, name, mime;
  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  Uint8List? _image;
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  MediaSource? _source;
  String? _error;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.kind == 'image') {
        final bytes = await widget.api.downloadBytes(widget.path);
        if (!mounted) return;
        _image = Uint8List.fromList(bytes);
      } else if (widget.kind == 'video' || widget.kind == 'audio') {
        final source = await loadMediaSource(
          widget.api,
          widget.path,
          widget.mime,
        );
        if (!mounted) {
          source.dispose();
          return;
        }
        _source = source;
        if (widget.kind == 'video') {
          final video = VideoPlayerController.networkUrl(
            Uri.parse(source.url),
            httpHeaders: source.headers,
          );
          _video = video;
          await video.initialize();
          if (!mounted) return;
          video.addListener(_changed);
        } else {
          final audio = AudioPlayer(useProxyForRequestHeaders: false);
          _audio = audio;
          await audio.setUrl(source.url, headers: source.headers);
          if (!mounted) return;
        }
      }
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to load media: $e');
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.removeListener(_changed);
    _video?.dispose();
    _audio?.dispose();
    _source?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return Text(_error!, style: const TextStyle(color: Colors.redAccent));
    if (!_ready)
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    if (_image != null)
      return GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) =>
              Dialog(child: InteractiveViewer(child: Image.memory(_image!))),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _image!,
            width: 280,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Text('Image format not supported'),
          ),
        ),
      );
    if (_video != null)
      return SizedBox(
        width: 300,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _video!.value.aspectRatio == 0
                  ? 16 / 9
                  : _video!.value.aspectRatio,
              child: VideoPlayer(_video!),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (_video!.value.isPlaying) {
                      await _video!.pause();
                    } else {
                      if (_video!.value.position >= _video!.value.duration)
                        await _video!.seekTo(Duration.zero);
                      await _video!.play();
                    }
                  },
                  icon: Icon(
                    _video!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(_video!, allowScrubbing: true),
                ),
              ],
            ),
          ],
        ),
      );
    if (_audio != null)
      return SizedBox(
        width: 270,
        child: StreamBuilder<PlayerState>(
          stream: _audio!.playerStateStream,
          builder: (_, snapshot) => Row(
            children: [
              IconButton(
                onPressed: () async {
                  try {
                    if (_audio!.playing) {
                      await _audio!.pause();
                    } else {
                      if (_audio!.processingState == ProcessingState.completed)
                        await _audio!.seek(Duration.zero);
                      await _audio!.play();
                    }
                  } catch (e) {
                    if (mounted) setState(() => _error = '$e');
                  }
                },
                icon: Icon(
                  snapshot.data?.playing == true &&
                          snapshot.data?.processingState !=
                              ProcessingState.completed
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
              const Icon(Icons.graphic_eq),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name.isEmpty ? 'Voice note' : widget.name,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    return Text(widget.name);
  }
}

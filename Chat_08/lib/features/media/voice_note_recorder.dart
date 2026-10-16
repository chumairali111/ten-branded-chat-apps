import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Records bounded PCM and wraps it in a WAV container, including Flutter Web.
class VoiceNoteRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _subscription;
  String? error;
  Future<void> start() async {
    if (!await _recorder.hasPermission())
      throw StateError('Microphone permission is required');
    _pcm.clear();
    error = null;
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _subscription = stream.listen((bytes) {
      if (_pcm.length + bytes.length <= 16000 * 2 * 120) _pcm.add(bytes);
    }, onError: (Object e) => error = e.toString());
  }

  Future<Uint8List> stop() async {
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    if (error != null) throw StateError(error!);
    final pcm = _pcm.takeBytes();
    if (pcm.isEmpty) throw StateError('No audio recorded');
    final wav = Uint8List(44 + pcm.length);
    final data = ByteData.sublistView(wav);
    void ascii(int offset, String value) =>
        wav.setRange(offset, offset + value.length, value.codeUnits);
    ascii(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 16000, Endian.little);
    data.setUint32(28, 32000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);
    wav.setRange(44, wav.length, pcm);
    return wav;
  }

  Future<void> cancel() async {
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    _pcm.clear();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _recorder.dispose();
  }
}

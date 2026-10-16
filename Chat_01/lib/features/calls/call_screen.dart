import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/app_controller.dart';

bool _callOpen = false;
Future<void> openOutgoingCall(
  BuildContext context,
  AppController app,
  bool video,
) async {
  if (_callOpen) throw StateError('A call is already open');
  final chat = app.activeChat;
  if (chat == null || chat['kind'] != 'direct') return;
  _callOpen = true;
  try {
    final response = await app.api.post('chats/${chat['id']}/calls', {
      'video': video,
    });
    if (!context.mounted) {
      await app.api.patch('calls/${response['id']}', {'state': 'ended'});
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          app: app,
          id: response['id'] as int,
          video: video,
          incoming: false,
          name: chat['title'] as String? ?? 'Contact',
        ),
      ),
    );
  } finally {
    _callOpen = false;
  }
}

/// Incoming calls are detected while the signed-in application is open.
class CallCoordinator extends StatefulWidget {
  const CallCoordinator({required this.app, required this.child, super.key});
  final AppController app;
  final Widget child;
  @override
  State<CallCoordinator> createState() => _CallCoordinatorState();
}

class _CallCoordinatorState extends State<CallCoordinator> {
  Timer? _timer;
  bool _polling = false;
  final Set<int> _shown = {};
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || _callOpen || !widget.app.signedIn) return;
    _polling = true;
    try {
      final response = await widget.app.api.get('calls');
      for (final entry in response['calls'] as List) {
        final call = Map<String, dynamic>.from(entry as Map);
        final id = call['id'] as int;
        if (call['callee'] == widget.app.user?['id'] &&
            call['state'] == 'ringing' &&
            !_shown.contains(id) &&
            mounted) {
          _shown.add(id);
          _callOpen = true;
          try {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  app: widget.app,
                  id: id,
                  video: call['video'] == 1,
                  incoming: true,
                  name: call['caller_name'] as String? ?? 'Contact',
                ),
              ),
            );
          } finally {
            _callOpen = false;
          }
          break;
        }
      }
    } catch (_) {
      /* Main controller reports network errors; next tick retries. */
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class CallScreen extends StatefulWidget {
  const CallScreen({
    required this.app,
    required this.id,
    required this.video,
    required this.incoming,
    required this.name,
    super.key,
  });
  final AppController app;
  final int id;
  final bool video, incoming;
  final String name;
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _local = RTCVideoRenderer(), _remote = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _stream;
  Timer? _timer;
  int _after = 0;
  bool _accepted = false, _preparing = false, _polling = false, _ending = false;
  bool _muted = false,
      _cameraOff = false,
      _speaker = false,
      _renderersReady = false;
  bool _remoteDescription = false, _canPop = false;
  final List<RTCIceCandidate> _pending = [];
  String _status = 'Ringing', _error = '';
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
    if (!widget.incoming) unawaited(_prepare());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _prepare() async {
    if (_preparing || _ending) return;
    _preparing = true;
    _error = '';
    _refresh();
    try {
      await _local.initialize();
      await _remote.initialize();
      if (!mounted || _ending) return;
      _renderersReady = true;
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.video ? {'facingMode': 'user'} : false,
      });
      if (!mounted || _ending) {
        for (final track in stream.getTracks()) {
          await track.stop();
        }
        await stream.dispose();
        return;
      }
      _stream = stream;
      _local.srcObject = stream;
      final config = await widget.app.api.get('calls/config');
      if (!mounted || _ending) return;
      final pc = await createPeerConnection({
        'iceServers': config['iceServers'],
        'sdpSemantics': 'unified-plan',
      });
      if (!mounted || _ending) {
        await pc.close();
        await pc.dispose();
        return;
      }
      _pc = pc;
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate != null && !_ending) {
          unawaited(
            widget.app.api
                .post('calls/${widget.id}/signals', {
                  'type': 'candidate',
                  'candidate': candidate.toMap(),
                })
                .catchError((Object e) {
                  _error = 'Signalling failed: $e';
                  _refresh();
                  return <String, dynamic>{};
                }),
          );
        }
      };
      pc.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remote.srcObject = event.streams.first;
          _refresh();
        }
      };
      pc.onConnectionState = (state) {
        if (_ending) return;
        _status =
            state == RTCPeerConnectionState.RTCPeerConnectionStateConnected
            ? 'Connected'
            : 'Connecting';
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed)
          _error =
              'Connection failed. Configure a TURN relay for this network.';
        _refresh();
      };
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
      if (!mounted || _ending) return;
      if (widget.incoming) {
        await widget.app.api.patch('calls/${widget.id}', {'state': 'active'});
      } else {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        await widget.app.api.post('calls/${widget.id}/signals', {
          'type': 'offer',
          'sdp': offer.sdp,
        });
      }
      _accepted = true;
    } catch (e) {
      _error = 'Camera/microphone or call setup failed: $e';
      try {
        await widget.app.api.patch('calls/${widget.id}', {
          'state': widget.incoming ? 'declined' : 'ended',
        });
      } catch (_) {}
    } finally {
      _preparing = false;
      _refresh();
    }
  }

  Future<void> _poll() async {
    if (_polling || _ending || !mounted) return;
    _polling = true;
    try {
      // Do not consume SDP until the media connection has been prepared.
      final result = await widget.app.api.get(
        'calls/${widget.id}/signals',
        query: {'after': '$_after'},
      );
      if (!mounted || _ending) return;
      if (['ended', 'declined', 'missed'].contains(result['state'])) {
        await _end(remote: true);
        return;
      }
      if (!_accepted || _pc == null) return;
      for (final entry in result['signals'] as List) {
        final row = Map<String, dynamic>.from(entry as Map);
        final signal =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        if (signal['type'] == 'offer' || signal['type'] == 'answer') {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(
              signal['sdp'] as String?,
              signal['type'] as String?,
            ),
          );
          _remoteDescription = true;
          if (signal['type'] == 'offer' && widget.incoming) {
            final answer = await _pc!.createAnswer();
            await _pc!.setLocalDescription(answer);
            await widget.app.api.post('calls/${widget.id}/signals', {
              'type': 'answer',
              'sdp': answer.sdp,
            });
          }
        } else if (signal['type'] == 'candidate') {
          final candidate = Map<String, dynamic>.from(
            signal['candidate'] as Map,
          );
          final ice = RTCIceCandidate(
            candidate['candidate'] as String?,
            candidate['sdpMid'] as String?,
            (candidate['sdpMLineIndex'] as num?)?.toInt(),
          );
          if (_remoteDescription) {
            await _pc!.addCandidate(ice);
          } else {
            _pending.add(ice);
          }
        }
        _after = row['id'] as int;
      }
      if (_remoteDescription) {
        for (final ice in _pending) {
          await _pc!.addCandidate(ice);
        }
        _pending.clear();
      }
    } catch (e) {
      _error = 'Call connection interrupted: $e';
      _refresh();
    } finally {
      _polling = false;
    }
  }

  Future<void> _end({bool remote = false}) async {
    if (_ending) return;
    _ending = true;
    _timer?.cancel();
    if (!remote) {
      try {
        await widget.app.api.patch('calls/${widget.id}', {
          'state': widget.incoming && !_accepted ? 'declined' : 'ended',
        });
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _cleanup() async {
    for (final track in _stream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _stream?.dispose();
    await _pc?.close();
    await _pc?.dispose();
    _local.srcObject = null;
    _remote.srcObject = null;
    await _local.dispose();
    await _remote.dispose();
  }

  @override
  void dispose() {
    _ending = true;
    _timer?.cancel();
    unawaited(_cleanup());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_end());
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.video ? 'Video call' : 'Voice call'),
        leading: IconButton(
          onPressed: _end,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(widget.name, style: const TextStyle(fontSize: 24)),
            Text(widget.incoming && !_accepted ? 'Incoming call' : _status),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: _renderersReady && _accepted
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: widget.video
                              ? RTCVideoView(_remote)
                              : const Center(child: Icon(Icons.call, size: 90)),
                        ),
                        // Remote renderer remains mounted for audio calls too.
                        if (!widget.video)
                          SizedBox(
                            width: 1,
                            height: 1,
                            child: RTCVideoView(_remote),
                          ),
                        if (widget.video)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: SizedBox(
                              width: 120,
                              height: 160,
                              child: RTCVideoView(_local, mirror: true),
                            ),
                          ),
                      ],
                    )
                  : const Center(child: Icon(Icons.account_circle, size: 100)),
            ),
            if (_preparing) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.incoming &&
                      !_accepted &&
                      !_preparing &&
                      _error.isEmpty)
                    FilledButton.icon(
                      onPressed: _prepare,
                      icon: const Icon(Icons.call),
                      label: const Text('Answer'),
                    ),
                  if (_accepted)
                    IconButton.filledTonal(
                      tooltip: 'Mute microphone',
                      onPressed: () {
                        _muted = !_muted;
                        for (final track in _stream!.getAudioTracks()) {
                          track.enabled = !_muted;
                        }
                        _refresh();
                      },
                      icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    ),
                  if (_accepted && widget.video)
                    IconButton.filledTonal(
                      tooltip: 'Toggle camera',
                      onPressed: () {
                        _cameraOff = !_cameraOff;
                        for (final track in _stream!.getVideoTracks()) {
                          track.enabled = !_cameraOff;
                        }
                        _refresh();
                      },
                      icon: Icon(
                        _cameraOff ? Icons.videocam_off : Icons.videocam,
                      ),
                    ),
                  if (_accepted && widget.video)
                    IconButton.filledTonal(
                      tooltip: 'Switch camera',
                      onPressed: () async {
                        try {
                          for (final track in _stream!.getVideoTracks()) {
                            await Helper.switchCamera(track);
                          }
                        } catch (e) {
                          _error = '$e';
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.cameraswitch),
                    ),
                  if (_accepted)
                    IconButton.filledTonal(
                      tooltip: 'Speaker',
                      onPressed: () async {
                        try {
                          await Helper.setSpeakerphoneOn(!_speaker);
                          _speaker = !_speaker;
                          _refresh();
                        } catch (e) {
                          _error = '$e';
                          _refresh();
                        }
                      },
                      icon: Icon(_speaker ? Icons.volume_up : Icons.hearing),
                    ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _end,
                    icon: const Icon(Icons.call_end),
                    label: Text(
                      widget.incoming && !_accepted ? 'Decline' : 'End call',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_controller.dart';
import '../core/api_client.dart';

enum PairingMode { request, scan }

class PairingScreen extends StatefulWidget {
  const PairingScreen({
    required this.controller,
    required this.mode,
    super.key,
  });

  final AppController controller;
  final PairingMode mode;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _scanner = MobileScannerController();
  Timer? _poller;
  Map<String, dynamic>? _challenge;
  String? _error;
  bool _busy = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PairingMode.request) unawaited(_createChallenge());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  Future<bool> _cancelRequest({bool pop = true}) async {
    final challenge = _challenge;
    if (challenge == null) {
      _completed = true;
      if (pop && mounted) Navigator.pop(context);
      return true;
    }
    try {
      await widget.controller.cancelPairing(
        challenge['id'] as String,
        challenge['secret'] as String,
      );
      _completed = true;
      if (pop && mounted) Navigator.pop(context);
      return true;
    } catch (exception) {
      if (mounted)
        setState(
          () => _error = 'Could not cancel the pairing challenge: $exception',
        );
      return false;
    }
  }

  Future<void> _createChallenge() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.controller.createPairing('Flutter device');
      if (!mounted) return;
      setState(() => _challenge = result);
      _poller = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_poll()),
      );
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    if (_busy || _completed || _challenge == null) return;
    _busy = true;
    try {
      final response = await widget.controller.pollPairing(
        _challenge!['id'] as String,
        _challenge!['secret'] as String,
      );
      if ((response['status'] == 'approved' && response['token'] != null) ||
          (response['status'] == 'approved' &&
              response['delivered'] == false &&
              response['csrf'] != null)) {
        _completed = true;
        _poller?.cancel();
        await widget.controller.acceptPairedSession(response);
        if (mounted) Navigator.of(context).pop();
      } else if (response['status'] == 'cancelled' ||
          response['status'] == 'expired' ||
          response['status'] == 'revoked') {
        _poller?.cancel();
        if (mounted)
          setState(
            () => _error = 'Pairing ${response['status']}. Start again.',
          );
      }
    } catch (exception) {
      if (exception is ApiException &&
          (exception.statusCode == 410 || exception.statusCode == 404)) {
        _poller?.cancel();
      }
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleCode(String? raw) async {
    if (_busy || raw == null) return;
    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } on FormatException {
      return;
    }
    if (uri.scheme != 'whatsappclone' || uri.host != 'pair') return;
    final id = uri.queryParameters['id'];
    final secret = uri.queryParameters['secret'];
    if (id == null || secret == null) return;
    setState(() => _busy = true);
    try {
      await _scanner.stop();
      final details = await widget.controller.pairingDetails(id, secret);
      if (!mounted) return;
      final approve = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve linked device?'),
          content: Text(
            '${details['device_name']} · ${details['platform']}\n\n'
            'This will create a separate account session on that device. Continue only if you initiated this sign-in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (approve == true) {
        await widget.controller.approvePairing(id, secret);
        _completed = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device linked. You can revoke it from Settings.'),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        await _scanner.start();
      }
    } catch (exception) {
      if (mounted) {
        setState(() => _error = exception.toString());
        await _scanner.start();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestMode = widget.mode == PairingMode.request;
    return WillPopScope(
      onWillPop: () async {
        if (!requestMode || _completed) return true;
        if (_busy) return false;
        return _cancelRequest(pop: false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            requestMode ? 'Link with a QR code' : 'Scan a device QR code',
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (requestMode) ...[
                    if (_challenge == null)
                      const CircularProgressIndicator()
                    else ...[
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: _challenge!['pairing_uri'] as String,
                            size: 250,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'On another device already signed in to this app, open Settings and scan this code. Confirm the device details before approving.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Expires in ${_challenge!['expires_in']} seconds',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ] else ...[
                    SizedBox(
                      height: 340,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: MobileScanner(
                          controller: _scanner,
                          onDetect: (capture) {
                            final values = capture.barcodes
                                .map((barcode) => barcode.rawValue)
                                .whereType<String>()
                                .toList();
                            final value = values.isEmpty ? null : values.first;
                            unawaited(_handleCode(value));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Scan the temporary code shown on your other sign-in device.',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (requestMode)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _cancelRequest(),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

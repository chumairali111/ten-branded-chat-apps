import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'app_controller.dart';

final serverHostKey = GlobalKey<ServerHostState>();
void configureServer(BuildContext context) {
  final host = serverHostKey.currentState;
  if (host == null) return;
  Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ServerSetupScreen(
    initial: host.controller?.api.baseUrl.toString() ?? '', save: host.accept,
  )));
}

class ServerHost extends StatefulWidget {
  const ServerHost({required this.builder, super.key});
  final Widget Function(AppController) builder;
  @override
  State<ServerHost> createState() => ServerHostState();
}
class ServerHostState extends State<ServerHost> {
  static const _storage = FlutterSecureStorage();
  AppController? controller;
  bool _loading = true;
  String _initial = '';
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      const compiled = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://chumairali.pythonanywhere.com/api');
      final saved = kIsWeb ? null : await _storage.read(key: 'messaging_server_url');
      _initial = saved ?? compiled;
      if (_initial.isNotEmpty) {
        controller = AppController(api: ApiClient(baseUrl: _initial));
      } else if (kIsWeb) {
        controller = AppController(); // public page origin + /api
      }
    } catch (_) { controller = null; }
    if (mounted) setState(() => _loading = false);
  }
  Future<void> accept(String value) async {
    final candidate = ApiClient(baseUrl: value);
    if (kIsWeb && (candidate.baseUrl.host != Uri.base.host || candidate.baseUrl.scheme != Uri.base.scheme)) {
      candidate.close();
      throw const FormatException('Open the web app on the hosted server URL; browser login must use the same site');
    }
    try {
      final result = await candidate.get('health');
      if (result['status'] != 'ok') throw StateError('This URL is not a messaging backend');
      if (controller != null) await controller!.store.clear();
      if (!kIsWeb) await _storage.write(key: 'messaging_server_url', value: candidate.baseUrl.toString());
      // Changing server discards old session credentials before any request to a new host.
      if (mounted) setState(() => controller = AppController(api: ApiClient(baseUrl: candidate.baseUrl.toString())));
    } finally { candidate.close(); }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    if (controller != null) return widget.builder(controller!);
    return MaterialApp(debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: ServerSetupScreen(initial: _initial, save: accept),
    );
  }
}
class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({required this.initial, required this.save, super.key});
  final String initial;
  final Future<void> Function(String) save;
  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}
class _ServerSetupScreenState extends State<ServerSetupScreen> {
  late final TextEditingController _url;
  bool _busy = false;
  String? _error;
  @override
  void initState() { super.initState(); _url = TextEditingController(text: widget.initial); }
  @override
  void dispose() { _url.dispose(); super.dispose(); }
  Future<void> _save() async {
    setState(() { _busy = true; _error = null; });
    try { await widget.save(_url.text.trim()); }
    catch (e) { if (mounted) setState(() => _error = 'Could not connect: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connect to your server')),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.public, size: 60), const SizedBox(height: 20),
        const Text('Use your hosted HTTPS server to chat from any network.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(controller: _url, enabled: !_busy, keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Server URL', hintText: 'https://your-messenger.example'),
          onSubmitted: (_) { if (!_busy) _save(); }),
        const SizedBox(height: 12),
        const Text('Changing server signs this app out. Use the same server URL on every device.', textAlign: TextAlign.center),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Checking server…' : 'Connect')),
      ]),
    ))),
  );
}

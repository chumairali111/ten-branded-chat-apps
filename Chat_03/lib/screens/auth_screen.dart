import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/server_host.dart';
import 'pairing_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.authenticate(
        _username.text.trim(),
        _password.text,
        name: _register ? _name.text.trim() : null,
      );
    } catch (exception) {
      if (mounted) setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 600 ? 440 : 480),
          child: Card(
            color: const Color(0xff12251B),
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                TextButton.icon(onPressed: () => configureServer(context), icon: const Icon(Icons.dns_outlined), label: const Text('Server settings')),
                    const Icon(Icons.forest, size: 48, color: Color(0xff4ADE80)),
                    const SizedBox(height: 14),
                    Text(
                      'ForestTalk',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stay close. Grow together.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Enter your display name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Username must have at least 3 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) => (value?.length ?? 0) < 10
                          ? 'Password must have at least 10 characters'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    if (widget.controller.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Server connection issue: ${widget.controller.error}',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_register ? 'Create account' : 'Sign in'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _error = null;
                            }),
                      child: Text(
                        _register
                            ? 'Already have an account? Sign in'
                            : 'Create account',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => PairingScreen(
                                  controller: widget.controller,
                                  mode: PairingMode.request,
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Link an existing account with QR'),
                    ),
                    const Text(
                      'Not affiliated with WhatsApp or Meta. Existing WhatsApp accounts cannot be used here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

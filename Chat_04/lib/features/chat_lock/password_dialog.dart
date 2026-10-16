import 'package:flutter/material.dart';

/// Owns its text controller until the dialog finishes its closing animation.
/// Failed passwords remain in the dialog and never hide the server error.
class ChatPasswordDialog extends StatefulWidget {
  const ChatPasswordDialog({
    required this.title,
    required this.actionLabel,
    required this.submit,
    super.key,
  });
  final String title, actionLabel;
  final Future<void> Function(String password) submit;
  @override
  State<ChatPasswordDialog> createState() => _ChatPasswordDialogState();
}

class _ChatPasswordDialogState extends State<ChatPasswordDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.submit(_password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Account login password',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Please wait…' : widget.actionLabel),
        ),
      ],
    ),
  );
}

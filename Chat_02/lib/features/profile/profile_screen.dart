import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/app_controller.dart';
import 'profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.app, super.key});
  final AppController app;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name, _about;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.app.user?['name'] as String? ?? '',
    );
    _about = TextEditingController(
      text: widget.app.user?['about'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await widget.app.refreshProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || !mounted) return;
    final file = result.files.single;
    if (file.bytes == null || file.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Choose an image smaller than 5 MB');
      return;
    }
    await _run(() async {
      final media = await widget.app.api.upload(
        'media/avatar',
        file.name,
        file.bytes!,
      );
      await widget.app.api.post('profile/avatar', {'media_id': media['id']});
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My profile')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ProfileAvatar(
            api: widget.app.api,
            id: widget.app.user?['avatar'] as String? ?? '',
            name: _name.text,
            radius: 65,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _photo,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Change photo'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await widget.app.api.delete('profile/avatar');
                    }),
              child: const Text('Remove photo'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _about,
          maxLength: 140,
          decoration: const InputDecoration(labelText: 'About'),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                  await widget.app.api.patch('profile', {
                    'name': _name.text.trim(),
                    'about': _about.text,
                  });
                }),
          child: Text(_busy ? 'Saving…' : 'Save profile'),
        ),
      ],
    ),
  );
}
